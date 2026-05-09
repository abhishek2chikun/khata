import hashlib
import json
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import case, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.buyer import Buyer
from app.models.buyer_transaction import BuyerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.buyer import BuyerAdjustmentRequest, BuyerCreateRequest, BuyerLedgerEntryRequest, BuyerLedgerResponse, BuyerResponse, BuyerTransactionResponse


def create_buyer(session: Session, payload: BuyerCreateRequest) -> Buyer:
    buyer = Buyer(**payload.model_dump())
    session.add(buyer)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_BUYER", "message": "Buyer already exists"}}) from exc
    session.refresh(buyer)
    return buyer


def list_buyers(session: Session, search: str | None = None) -> list[Buyer]:
    query = select(Buyer)
    if search:
        query = query.where(or_(Buyer.name.ilike(f"%{search}%"), Buyer.phone.ilike(f"%{search}%"), Buyer.gstin.ilike(f"%{search}%")))
    return list(session.scalars(query.order_by(Buyer.name)).all())


def get_buyer(session: Session, buyer_id) -> Buyer:
    buyer = session.get(Buyer, buyer_id)
    if buyer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Buyer not found"}})
    return buyer


def _entry_hash(payload: dict) -> str:
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()


def _ensure_active_buyer(buyer: Buyer) -> None:
    if not buyer.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "BUYER_ARCHIVED", "message": "Archived buyer cannot be updated"}})


def _create_entry(session: Session, buyer_id, entry_type: str, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse) -> BuyerTransaction:
    buyer = get_buyer(session, buyer_id)
    _ensure_active_buyer(buyer)
    entry_hash = _entry_hash({"buyer_id": str(buyer.id), "entry_type": entry_type, **payload.model_dump(mode="json")})
    existing = session.scalar(select(BuyerTransaction).where(BuyerTransaction.request_id == payload.request_id))
    if existing is not None:
        if existing.request_hash != entry_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        return existing

    transaction = BuyerTransaction(
        buyer_id=buyer.id,
        request_id=payload.request_id,
        request_hash=entry_hash,
        entry_type=entry_type,
        amount=payload.amount,
        occurred_at=payload.occurred_at,
        notes=payload.notes,
        created_by_user_id=current_user.id,
    )
    session.add(transaction)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        existing = session.scalar(select(BuyerTransaction).where(BuyerTransaction.request_id == payload.request_id))
        if existing is not None and existing.request_hash == entry_hash:
            return existing
        code = "OPENING_PAYABLE_EXISTS" if entry_type == "OPENING_PAYABLE" else "IDEMPOTENCY_CONFLICT"
        message = "Opening payable already exists" if entry_type == "OPENING_PAYABLE" else "request_id already used with different payload"
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": code, "message": message}}) from exc
    session.refresh(transaction)
    return transaction


def create_opening_payable(session: Session, buyer_id, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse) -> BuyerTransaction:
    return _create_entry(session, buyer_id, "OPENING_PAYABLE", payload, current_user)


def create_purchase_amount(session: Session, buyer_id, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse) -> BuyerTransaction:
    return _create_entry(session, buyer_id, "PURCHASE_AMOUNT", payload, current_user)


def create_payment_made(session: Session, buyer_id, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse) -> BuyerTransaction:
    return _create_entry(session, buyer_id, "PAYMENT_MADE", payload, current_user)


def create_payable_adjustment(session: Session, buyer_id, payload: BuyerAdjustmentRequest, current_user: CurrentUserResponse) -> BuyerTransaction:
    entry_type = "PAYABLE_INCREASE_ADJUSTMENT" if payload.direction == "INCREASE" else "PAYABLE_DECREASE_ADJUSTMENT"
    return _create_entry(session, buyer_id, entry_type, payload, current_user)


def pending_payable_value(session: Session, buyer_id) -> Decimal:
    value = session.scalar(
        select(
            func.coalesce(
                func.sum(
                    case(
                        (BuyerTransaction.entry_type.in_(["OPENING_PAYABLE", "PURCHASE_AMOUNT", "PAYABLE_INCREASE_ADJUSTMENT"]), BuyerTransaction.amount),
                        else_=-BuyerTransaction.amount,
                    )
                ),
                0,
            )
        ).where(BuyerTransaction.buyer_id == buyer_id)
    )
    return Decimal(value or 0)


def build_buyer_response(session: Session, buyer: Buyer) -> BuyerResponse:
    data = BuyerResponse.model_validate(buyer)
    data.pending_payable = f"{pending_payable_value(session, buyer.id):.2f}"
    return data


def get_buyer_ledger(session: Session, buyer_id) -> BuyerLedgerResponse:
    buyer = get_buyer(session, buyer_id)
    transactions = list(session.scalars(select(BuyerTransaction).where(BuyerTransaction.buyer_id == buyer.id).order_by(BuyerTransaction.occurred_at, BuyerTransaction.created_at)).all())
    return BuyerLedgerResponse(
        buyer=build_buyer_response(session, buyer),
        transactions=[BuyerTransactionResponse.model_validate(transaction) for transaction in transactions],
    )
