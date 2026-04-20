from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.seller import BalanceAdjustmentRequest, OpeningBalanceRequest, SellerCreateRequest, SellerLedgerResponse, SellerResponse, SellerTransactionResponse, SellerUpdateRequest
from app.services import seller_service

router = APIRouter(prefix="/sellers", tags=["sellers"])


@router.post("", response_model=SellerResponse, status_code=201)
def create_seller(payload: SellerCreateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return seller_service.build_seller_response(session, seller_service.create_seller(session, payload))


@router.get("", response_model=list[SellerResponse])
def list_sellers(_: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> list[SellerResponse]:
    return [seller_service.build_seller_response(session, seller) for seller in seller_service.list_sellers(session)]


@router.get("/{seller_id}", response_model=SellerResponse)
def get_seller(seller_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return seller_service.build_seller_response(session, seller_service.get_seller(session, seller_id))


@router.put("/{seller_id}", response_model=SellerResponse)
def update_seller(seller_id: str, payload: SellerUpdateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return seller_service.build_seller_response(session, seller_service.update_seller(session, seller_id, payload))


@router.delete("/{seller_id}", response_model=SellerResponse)
def archive_seller(seller_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return seller_service.build_seller_response(session, seller_service.archive_seller(session, seller_id))


@router.post("/{seller_id}/opening-balance", response_model=SellerTransactionResponse, status_code=201)
def create_opening_balance(seller_id: str, payload: OpeningBalanceRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerTransactionResponse:
    transaction = seller_service.create_opening_balance(session, seller_id, payload, current_user)
    return SellerTransactionResponse.model_validate(transaction)


@router.post("/{seller_id}/balance-adjustment", response_model=SellerTransactionResponse, status_code=201)
def create_balance_adjustment(seller_id: str, payload: BalanceAdjustmentRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerTransactionResponse:
    transaction = seller_service.create_balance_adjustment(session, seller_id, payload, current_user)
    return SellerTransactionResponse.model_validate(transaction)


@router.get("/{seller_id}/ledger", response_model=SellerLedgerResponse)
def get_seller_ledger(seller_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerLedgerResponse:
    return seller_service.get_seller_ledger(session, seller_id)
