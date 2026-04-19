from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.seller import SellerCreateRequest, SellerResponse, SellerUpdateRequest
from app.services import seller_service

router = APIRouter(prefix="/sellers", tags=["sellers"])


@router.post("", response_model=SellerResponse, status_code=201)
def create_seller(payload: SellerCreateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return SellerResponse.model_validate(seller_service.create_seller(session, payload))


@router.get("", response_model=list[SellerResponse])
def list_sellers(_: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> list[SellerResponse]:
    return [SellerResponse.model_validate(seller) for seller in seller_service.list_sellers(session)]


@router.get("/{seller_id}", response_model=SellerResponse)
def get_seller(seller_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return SellerResponse.model_validate(seller_service.get_seller(session, seller_id))


@router.put("/{seller_id}", response_model=SellerResponse)
def update_seller(seller_id: str, payload: SellerUpdateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return SellerResponse.model_validate(seller_service.update_seller(session, seller_id, payload))


@router.delete("/{seller_id}", response_model=SellerResponse)
def archive_seller(seller_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerResponse:
    return SellerResponse.model_validate(seller_service.archive_seller(session, seller_id))
