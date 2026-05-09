import hashlib
import json
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import case, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.customer import Customer
from app.models.invoice import Invoice
from app.models.customer_transaction import CustomerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.customer import BalanceAdjustmentRequest, OpeningBalanceRequest, CollectionRequest, CustomerCreateRequest, CustomerLedgerResponse, CustomerResponse, CustomerTransactionResponse, CustomerUpdateRequest


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


def _ensure_active_customer(customer: Customer) -> None:
    if not customer.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "CUSTOMER_ARCHIVED", "message": "Archived customer cannot be updated"}})


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

    transaction = CustomerTransaction(
        customer_id=customer.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        entry_type="COLLECTION",
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
                        (CustomerTransaction.entry_type.in_(["OPENING_BALANCE", "CREDIT_SALE", "BALANCE_INCREASE_ADJUSTMENT"]), CustomerTransaction.amount),
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
    data.pending_balance = f"{_pending_balance_value(session, customer.id):.2f}"
    return data


def get_customer_ledger(session: Session, customer_id) -> CustomerLedgerResponse:
    customer = get_customer(session, customer_id)
    transactions = list(session.scalars(select(CustomerTransaction).where(CustomerTransaction.customer_id == customer.id).order_by(CustomerTransaction.occurred_on, CustomerTransaction.created_at)).all())
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
                payment_mode=invoice.payment_mode,
                status=invoice.status,
            )
            for invoice in invoices
        ],
    )
