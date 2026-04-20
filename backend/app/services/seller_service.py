import hashlib
import json
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import case, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.seller import Seller
from app.models.invoice import Invoice
from app.models.seller_transaction import SellerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.seller import BalanceAdjustmentRequest, OpeningBalanceRequest, PaymentRequest, SellerCreateRequest, SellerLedgerResponse, SellerResponse, SellerTransactionResponse, SellerUpdateRequest


def create_seller(session: Session, payload: SellerCreateRequest) -> Seller:
    seller = Seller(**payload.model_dump())
    session.add(seller)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_SELLER", "message": "Seller already exists"}}) from exc
    session.refresh(seller)
    return seller


def list_sellers(session: Session) -> list[Seller]:
    return list(session.scalars(select(Seller).order_by(Seller.name)).all())


def get_seller(session: Session, seller_id) -> Seller:
    seller = session.get(Seller, seller_id)
    if seller is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Seller not found"}})
    return seller


def update_seller(session: Session, seller_id, payload: SellerUpdateRequest) -> Seller:
    seller = get_seller(session, seller_id)
    for key, value in payload.model_dump().items():
        setattr(seller, key, value)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_SELLER", "message": "Seller already exists"}}) from exc
    session.refresh(seller)
    return seller


def archive_seller(session: Session, seller_id) -> Seller:
    seller = get_seller(session, seller_id)
    seller.is_active = False
    session.commit()
    session.refresh(seller)
    return seller


def _entry_hash(payload: dict) -> str:
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()


def _ensure_active_seller(seller: Seller) -> None:
    if not seller.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "SELLER_ARCHIVED", "message": "Archived seller cannot be updated"}})


def create_opening_balance(session: Session, seller_id, payload: OpeningBalanceRequest, current_user: CurrentUserResponse):
    seller = get_seller(session, seller_id)
    _ensure_active_seller(seller)
    entry_type = "OPENING_BALANCE"
    entry_hash = _entry_hash({"seller_id": str(seller.id), "entry_type": entry_type, **payload.model_dump(mode="json")})
    existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = SellerTransaction(
        seller_id=seller.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
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
        existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "OPENING_BALANCE_EXISTS", "message": "Opening balance already exists"}}) from exc
    session.refresh(transaction)
    return transaction


def create_payment(session: Session, payload: PaymentRequest, current_user: CurrentUserResponse):
    seller = get_seller(session, payload.seller_id)
    _ensure_active_seller(seller)
    entry_hash = _entry_hash({"seller_id": str(seller.id), "entry_type": "PAYMENT", **payload.model_dump(mode="json")})
    existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = SellerTransaction(
        seller_id=seller.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        entry_type="PAYMENT",
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
        existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}}) from exc
    session.refresh(transaction)
    return transaction


def create_balance_adjustment(session: Session, seller_id, payload: BalanceAdjustmentRequest, current_user: CurrentUserResponse):
    seller = get_seller(session, seller_id)
    _ensure_active_seller(seller)
    entry_type = "BALANCE_INCREASE_ADJUSTMENT" if payload.direction == "INCREASE" else "BALANCE_DECREASE_ADJUSTMENT"
    entry_hash = _entry_hash({"seller_id": str(seller.id), "entry_type": entry_type, **payload.model_dump(mode="json")})
    existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = SellerTransaction(
        seller_id=seller.id,
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
        existing = session.scalar(select(SellerTransaction).where(SellerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}}) from exc
    session.refresh(transaction)
    return transaction


def _pending_balance_value(session: Session, seller_id) -> Decimal:
    value = session.scalar(
        select(
            func.coalesce(
                func.sum(
                    case(
                        (SellerTransaction.entry_type.in_(["OPENING_BALANCE", "CREDIT_SALE", "BALANCE_INCREASE_ADJUSTMENT"]), SellerTransaction.amount),
                        else_=-SellerTransaction.amount,
                    )
                ),
                0,
            )
        ).where(SellerTransaction.seller_id == seller_id)
    )
    return Decimal(value or 0)


def build_seller_response(session: Session, seller: Seller) -> SellerResponse:
    data = SellerResponse.model_validate(seller)
    data.pending_balance = f"{_pending_balance_value(session, seller.id):.2f}"
    return data


def get_seller_ledger(session: Session, seller_id) -> SellerLedgerResponse:
    seller = get_seller(session, seller_id)
    transactions = list(session.scalars(select(SellerTransaction).where(SellerTransaction.seller_id == seller.id).order_by(SellerTransaction.occurred_on, SellerTransaction.created_at)).all())
    invoices = list(session.scalars(select(Invoice).where(Invoice.seller_id == seller.id).order_by(Invoice.invoice_date, Invoice.invoice_number)).all())
    return SellerLedgerResponse(
        seller=build_seller_response(session, seller),
        transactions=[SellerTransactionResponse.model_validate(transaction) for transaction in transactions],
        invoices=[
            SellerLedgerResponse.InvoiceHistoryEntry(
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
