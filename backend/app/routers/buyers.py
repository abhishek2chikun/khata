import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.buyer import BuyerAdjustmentRequest, BuyerCreateRequest, BuyerLedgerEntryRequest, BuyerLedgerResponse, BuyerResponse, BuyerTransactionResponse
from app.services import buyer_service

router = APIRouter(prefix="/buyers", tags=["buyers"])


@router.post("", response_model=BuyerResponse, status_code=201)
def create_buyer(payload: BuyerCreateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerResponse:
    return buyer_service.build_buyer_response(session, buyer_service.create_buyer(session, payload))


@router.get("", response_model=list[BuyerResponse])
def list_buyers(search: str | None = None, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> list[BuyerResponse]:
    return [buyer_service.build_buyer_response(session, buyer) for buyer in buyer_service.list_buyers(session, search)]


@router.get("/{buyer_id}", response_model=BuyerResponse)
def get_buyer(buyer_id: uuid.UUID, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerResponse:
    return buyer_service.build_buyer_response(session, buyer_service.get_buyer(session, buyer_id))


@router.post("/{buyer_id}/opening-payable", response_model=BuyerTransactionResponse, status_code=201)
def create_opening_payable(buyer_id: uuid.UUID, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerTransactionResponse:
    return BuyerTransactionResponse.model_validate(buyer_service.create_opening_payable(session, buyer_id, payload, current_user))


@router.post("/{buyer_id}/purchase-amounts", response_model=BuyerTransactionResponse, status_code=201)
def create_purchase_amount(buyer_id: uuid.UUID, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerTransactionResponse:
    return BuyerTransactionResponse.model_validate(buyer_service.create_purchase_amount(session, buyer_id, payload, current_user))


@router.post("/{buyer_id}/payments-made", response_model=BuyerTransactionResponse, status_code=201)
def create_payment_made(buyer_id: uuid.UUID, payload: BuyerLedgerEntryRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerTransactionResponse:
    return BuyerTransactionResponse.model_validate(buyer_service.create_payment_made(session, buyer_id, payload, current_user))


@router.post("/{buyer_id}/payable-adjustments", response_model=BuyerTransactionResponse, status_code=201)
def create_payable_adjustment(buyer_id: uuid.UUID, payload: BuyerAdjustmentRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerTransactionResponse:
    return BuyerTransactionResponse.model_validate(buyer_service.create_payable_adjustment(session, buyer_id, payload, current_user))


@router.get("/{buyer_id}/ledger", response_model=BuyerLedgerResponse)
def get_buyer_ledger(buyer_id: uuid.UUID, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> BuyerLedgerResponse:
    return buyer_service.get_buyer_ledger(session, buyer_id)
