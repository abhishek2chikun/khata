from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.seller import Seller
from app.schemas.seller import SellerCreateRequest, SellerUpdateRequest


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
