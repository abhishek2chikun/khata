import hashlib
import json
import uuid
from datetime import date, timedelta
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import case, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.customer import Customer
from app.models.invoice import Invoice
from app.models.customer_transaction import CustomerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.customer import (
    BalanceAdjustmentRequest,
    BatchCollectionEntry,
    BatchCollectionRequest,
    BatchCollectionResponse,
    CollectionGridCustomerRow,
    CollectionGridResponse,
    CollectionRequest,
    CustomerCreateRequest,
    CustomerLedgerResponse,
    CustomerResponse,
    CustomerTransactionResponse,
    CustomerUpdateRequest,
    OpeningBalanceRequest,
    MONEY_QUANT,
)

BATCH_NOTES_PREFIX = "__batch__|"
MAX_COLLECTION_WINDOW_DAYS = 7


def create_customer(session: Session, payload: CustomerCreateRequest) -> Customer:
    customer = Customer(**payload.model_dump())
    session.add(customer)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_CUSTOMER", "message": "Customer already exists"}}) from exc
    session.refresh(customer)
    return customer


def list_customers(session: Session) -> list[Customer]:
    return list(session.scalars(select(Customer).order_by(Customer.name)).all())


def get_customer(session: Session, customer_id) -> Customer:
    customer = session.get(Customer, customer_id)
    if customer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Customer not found"}})
    return customer


def update_customer(session: Session, customer_id, payload: CustomerUpdateRequest) -> Customer:
    customer = get_customer(session, customer_id)
    for key, value in payload.model_dump().items():
        setattr(customer, key, value)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_CUSTOMER", "message": "Customer already exists"}}) from exc
    session.refresh(customer)
    return customer


def archive_customer(session: Session, customer_id) -> Customer:
    customer = get_customer(session, customer_id)
    customer.is_active = False
    session.commit()
    session.refresh(customer)
    return customer


def _entry_hash(payload: dict) -> str:
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()


def _money_string(value: Decimal) -> str:
    return f"{value.quantize(MONEY_QUANT):.2f}"


def _batch_notes(batch_request_id: uuid.UUID, batch_hash: str) -> str:
    return f"{BATCH_NOTES_PREFIX}{batch_request_id}|{batch_hash}"


def _canonical_batch_hash(entries: list[BatchCollectionEntry]) -> str:
    canonical = [
        {
            "customer_id": str(entry.customer_id),
            "occurred_on": entry.occurred_on.isoformat(),
            "amount": _money_string(entry.amount),
        }
        for entry in sorted(entries, key=lambda item: (str(item.customer_id), item.occurred_on.isoformat()))
    ]
    return hashlib.sha256(json.dumps(canonical, sort_keys=True).encode("utf-8")).hexdigest()


def _batch_entry_request_id(batch_request_id: uuid.UUID, customer_id: uuid.UUID, occurred_on: date) -> uuid.UUID:
    return uuid.uuid5(batch_request_id, f"{customer_id}:{occurred_on.isoformat()}")


def _collection_entry_hash(*, customer_id: uuid.UUID, occurred_on: date, amount: Decimal, batch_request_id: uuid.UUID | None = None) -> str:
    payload = {
        "customer_id": str(customer_id),
        "entry_type": "COLLECTION",
        "occurred_on": occurred_on.isoformat(),
        "amount": _money_string(amount),
    }
    if batch_request_id is not None:
        payload["batch_request_id"] = str(batch_request_id)
    return _entry_hash(payload)


def _build_collection_transaction(
    *,
    customer_id: uuid.UUID,
    request_id: uuid.UUID,
    request_hash: str,
    amount: Decimal,
    occurred_on: date,
    notes: str | None,
    created_by_user_id: uuid.UUID,
) -> CustomerTransaction:
    return CustomerTransaction(
        customer_id=customer_id,
        request_id=request_id,
        request_hash=request_hash,
        entry_type="COLLECTION",
        amount=amount,
        occurred_on=occurred_on,
        notes=notes,
        created_by_user_id=created_by_user_id,
    )


def _ensure_active_customer(customer: Customer) -> None:
    if not customer.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "CUSTOMER_ARCHIVED", "message": "Archived customer cannot be updated"}})


def _validate_collection_window(*, from_date: date, to_date: date, today: date) -> list[date]:
    if from_date > to_date:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "from_date must be on or before to_date"}})
    if to_date > today:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Collection dates cannot be in the future"}})
    if from_date < today - timedelta(days=6):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Collection dates cannot be older than six days"}})
    day_count = (to_date - from_date).days + 1
    if day_count > MAX_COLLECTION_WINDOW_DAYS:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Collection date range cannot exceed seven days"}})
    return [from_date + timedelta(days=offset) for offset in range(day_count)]


def _validate_batch_entries(entries: list[BatchCollectionEntry], *, today: date) -> None:
    if not entries:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "At least one collection entry is required"}})

    seen: set[tuple[uuid.UUID, date]] = set()
    for entry in entries:
        if entry.occurred_on > today:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Collection dates cannot be in the future"}})
        if entry.occurred_on < today - timedelta(days=6):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Collection dates cannot be older than six days"}})
        key = (entry.customer_id, entry.occurred_on)
        if key in seen:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "Duplicate customer and date entries are not allowed"}})
        seen.add(key)


def create_opening_balance(session: Session, customer_id, payload: OpeningBalanceRequest, current_user: CurrentUserResponse):
    customer = get_customer(session, customer_id)
    _ensure_active_customer(customer)
    entry_type = "OPENING_BALANCE"
    entry_hash = _entry_hash({"customer_id": str(customer.id), "entry_type": entry_type, **payload.model_dump(mode="json")})
    existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = CustomerTransaction(
        customer_id=customer.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        opening_balance_customer_id=customer.id,
        entry_type=entry_type,
        amount=payload.amount,
        occurred_on=payload.occurred_on,
        created_by_user_id=current_user.id,
    )
    session.add(transaction)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "OPENING_BALANCE_EXISTS", "message": "Opening balance already exists"}}) from exc
    session.refresh(transaction)
    return transaction


def create_collection(session: Session, payload: CollectionRequest, current_user: CurrentUserResponse):
    customer = get_customer(session, payload.customer_id)
    _ensure_active_customer(customer)
    entry_hash = _entry_hash({"customer_id": str(customer.id), "entry_type": "COLLECTION", **payload.model_dump(mode="json")})
    existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = _build_collection_transaction(
        customer_id=customer.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        amount=payload.amount,
        occurred_on=payload.occurred_on,
        notes=payload.notes,
        created_by_user_id=current_user.id,
    )
    session.add(transaction)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}}) from exc
    session.refresh(transaction)
    return transaction


def create_balance_adjustment(session: Session, customer_id, payload: BalanceAdjustmentRequest, current_user: CurrentUserResponse):
    customer = get_customer(session, customer_id)
    _ensure_active_customer(customer)
    entry_type = "BALANCE_INCREASE_ADJUSTMENT" if payload.direction == "INCREASE" else "BALANCE_DECREASE_ADJUSTMENT"
    entry_hash = _entry_hash({"customer_id": str(customer.id), "entry_type": entry_type, **payload.model_dump(mode="json")})
    existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = CustomerTransaction(
        customer_id=customer.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        entry_type=entry_type,
        amount=payload.amount,
        occurred_on=payload.occurred_on,
        notes=payload.notes,
        created_by_user_id=current_user.id,
    )
    session.add(transaction)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        existing = session.scalar(select(CustomerTransaction).where(CustomerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}}) from exc
    session.refresh(transaction)
    return transaction


def _pending_balance_value(session: Session, customer_id) -> Decimal:
    value = session.scalar(
        select(
            func.coalesce(
                func.sum(
                    case(
                        (CustomerTransaction.entry_type.in_(["OPENING_BALANCE", "CREDIT_SALE", "BALANCE_INCREASE_ADJUSTMENT", "COLLECTION_REVERSAL"]), CustomerTransaction.amount),
                        else_=-CustomerTransaction.amount,
                    )
                ),
                0,
            )
        ).where(CustomerTransaction.customer_id == customer_id)
    )
    return Decimal(value or 0)


def build_customer_response(session: Session, customer: Customer) -> CustomerResponse:
    data = CustomerResponse.model_validate(customer)
    data.pending_balance = _money_string(_pending_balance_value(session, customer.id))
    return data


def get_collection_grid(session: Session, *, from_date: date, to_date: date, today: date | None = None) -> CollectionGridResponse:
    business_today = today or date.today()
    dates = _validate_collection_window(from_date=from_date, to_date=to_date, today=business_today)

    customers = list(session.scalars(select(Customer).where(Customer.is_active.is_(True)).order_by(Customer.name)).all())
    positive_customers: list[CollectionGridCustomerRow] = []
    for customer in customers:
        pending_balance = _pending_balance_value(session, customer.id)
        if pending_balance <= 0:
            continue
        totals = session.execute(
            select(CustomerTransaction.occurred_on, func.sum(CustomerTransaction.amount))
            .where(
                CustomerTransaction.customer_id == customer.id,
                CustomerTransaction.entry_type == "COLLECTION",
                CustomerTransaction.occurred_on >= from_date,
                CustomerTransaction.occurred_on <= to_date,
            )
            .group_by(CustomerTransaction.occurred_on)
        ).all()
        existing_totals = {occurred_on.isoformat(): _money_string(Decimal(total or 0)) for occurred_on, total in totals}
        positive_customers.append(
            CollectionGridCustomerRow(
                id=customer.id,
                name=customer.name,
                pending_balance=_money_string(pending_balance),
                existing_totals=existing_totals,
            )
        )

    return CollectionGridResponse(from_date=from_date, to_date=to_date, dates=dates, customers=positive_customers)


def _build_batch_response(session: Session, *, batch_request_id: uuid.UUID, transactions: list[CustomerTransaction]) -> BatchCollectionResponse:
    total_amount = sum((transaction.amount for transaction in transactions), Decimal("0"))
    affected_customer_ids = sorted({transaction.customer_id for transaction in transactions})
    customers = [build_customer_response(session, get_customer(session, customer_id)) for customer_id in affected_customer_ids]
    return BatchCollectionResponse(
        request_id=batch_request_id,
        entry_count=len(transactions),
        total_amount=_money_string(total_amount),
        affected_customers=len(affected_customer_ids),
        customers=customers,
    )


def create_collection_batch(session: Session, payload: BatchCollectionRequest, current_user: CurrentUserResponse, *, today: date | None = None) -> BatchCollectionResponse:
    business_today = today or date.today()
    batch_hash = _canonical_batch_hash(payload.entries)
    batch_notes = _batch_notes(payload.request_id, batch_hash)

    conflicting = session.scalar(
        select(CustomerTransaction)
        .where(
            CustomerTransaction.notes.like(f"{BATCH_NOTES_PREFIX}{payload.request_id}|%"),
            CustomerTransaction.notes != batch_notes,
            CustomerTransaction.entry_type == "COLLECTION",
        )
        .limit(1)
    )
    if conflicting is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})

    existing = list(
        session.scalars(
            select(CustomerTransaction).where(
                CustomerTransaction.notes == batch_notes,
                CustomerTransaction.entry_type == "COLLECTION",
            )
        ).all()
    )
    if existing:
        return _build_batch_response(session, batch_request_id=payload.request_id, transactions=existing)

    _validate_batch_entries(payload.entries, today=business_today)
    customer_ids = sorted({entry.customer_id for entry in payload.entries})
    customers = list(
        session.scalars(
            select(Customer)
            .where(Customer.id.in_(customer_ids))
            .order_by(Customer.id)
            .with_for_update()
        ).all()
    )
    customers_by_id = {customer.id: customer for customer in customers}
    if len(customers_by_id) != len(customer_ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Customer not found"}})

    totals_by_customer: dict[uuid.UUID, Decimal] = {}
    for entry in payload.entries:
        customer = customers_by_id[entry.customer_id]
        _ensure_active_customer(customer)
        totals_by_customer[entry.customer_id] = totals_by_customer.get(entry.customer_id, Decimal("0")) + entry.amount

    for customer_id, total_amount in totals_by_customer.items():
        pending_balance = _pending_balance_value(session, customer_id)
        if total_amount > pending_balance:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"error": {"code": "STALE_BALANCE", "message": "Collection total exceeds current pending balance"}},
            )

    transactions: list[CustomerTransaction] = []
    for entry in sorted(payload.entries, key=lambda item: (str(item.customer_id), item.occurred_on.isoformat())):
        transaction = _build_collection_transaction(
            customer_id=entry.customer_id,
            request_id=_batch_entry_request_id(payload.request_id, entry.customer_id, entry.occurred_on),
            request_hash=_collection_entry_hash(
                customer_id=entry.customer_id,
                occurred_on=entry.occurred_on,
                amount=entry.amount,
                batch_request_id=payload.request_id,
            ),
            amount=entry.amount,
            occurred_on=entry.occurred_on,
            notes=batch_notes,
            created_by_user_id=current_user.id,
        )
        session.add(transaction)
        transactions.append(transaction)

    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        existing = list(
            session.scalars(
                select(CustomerTransaction).where(
                    CustomerTransaction.notes == batch_notes,
                    CustomerTransaction.entry_type == "COLLECTION",
                )
            ).all()
        )
        if existing:
            return _build_batch_response(session, batch_request_id=payload.request_id, transactions=existing)
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}}) from exc

    for transaction in transactions:
        session.refresh(transaction)
    return _build_batch_response(session, batch_request_id=payload.request_id, transactions=transactions)


def get_customer_ledger(session: Session, customer_id, *, on_date: date | None = None) -> CustomerLedgerResponse:
    customer = get_customer(session, customer_id)
    transactions_query = select(CustomerTransaction).where(CustomerTransaction.customer_id == customer.id)
    if on_date is not None:
        transactions_query = transactions_query.where(CustomerTransaction.occurred_on == on_date)
    transactions = list(session.scalars(transactions_query.order_by(CustomerTransaction.occurred_on, CustomerTransaction.created_at, CustomerTransaction.id)).all())
    invoices = list(session.scalars(select(Invoice).where(Invoice.customer_id == customer.id).order_by(Invoice.invoice_date, Invoice.invoice_number)).all())
    return CustomerLedgerResponse(
        customer=build_customer_response(session, customer),
        transactions=[CustomerTransactionResponse.model_validate(transaction) for transaction in transactions],
        invoices=[
            CustomerLedgerResponse.InvoiceHistoryEntry(
                invoice_id=invoice.id,
                invoice_number=str(invoice.invoice_number),
                invoice_date=invoice.invoice_date,
                grand_total=invoice.grand_total,
                payment_mode=invoice.payment_state,
                status=invoice.status,
            )
            for invoice in invoices
        ],
    )
