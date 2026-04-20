import hashlib
import json
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.product import Product
from app.models.stock_movement import StockMovement
from app.schemas.auth import CurrentUserResponse
from app.schemas.product import ProductCreateRequest, ProductUpdateRequest


def _hash_opening_stock_payload(product_id: str, quantity: str) -> str:
    payload = {"product_id": product_id, "quantity": quantity, "movement_type": "OPENING"}
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()


def create_product(session: Session, payload: ProductCreateRequest, current_user: CurrentUserResponse) -> Product:
    product = Product(**payload.model_dump())
    session.add(product)
    try:
        session.flush()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_PRODUCT", "message": "Product already exists"}}) from exc

    if payload.quantity_on_hand != 0:
        session.add(
            StockMovement(
                product_id=product.id,
                movement_type="OPENING",
                quantity_delta=payload.quantity_on_hand,
                request_hash=_hash_opening_stock_payload(str(product.id), str(payload.quantity_on_hand)),
                reason="Initial stock",
                created_by_user_id=current_user.id,
            )
        )

    session.commit()
    session.refresh(product)
    return product


def list_products(session: Session, company: str | None, category: str | None, search: str | None, active: bool | None, low_stock_only: bool | None) -> list[Product]:
    query = select(Product)
    if company:
        query = query.where(Product.company == company)
    if category:
        query = query.where(Product.category == category)
    if search:
        query = query.where(or_(Product.item_name.ilike(f"%{search}%"), Product.item_code.ilike(f"%{search}%")))
    if active is not None:
        query = query.where(Product.is_active.is_(active))
    if low_stock_only:
        query = query.where(Product.quantity_on_hand <= Product.low_stock_threshold)
    return list(session.scalars(query.order_by(Product.item_name)).all())


def get_product(session: Session, product_id):
    product = session.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Product not found"}})
    return product


def update_product(session: Session, product_id, payload: ProductUpdateRequest) -> Product:
    product = get_product(session, product_id)
    if payload.quantity_on_hand is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": "quantity_on_hand cannot be updated directly"}})

    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(product, key, value)

    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "DUPLICATE_PRODUCT", "message": "Product already exists"}}) from exc
    session.refresh(product)
    return product


def archive_product(session: Session, product_id) -> Product:
    product = get_product(session, product_id)
    product.is_active = False
    session.commit()
    session.refresh(product)
    return product


def adjust_stock(session: Session, product_id, request_id: UUID, quantity_delta, reason: str | None, current_user: CurrentUserResponse):
    product = session.scalar(select(Product).where(Product.id == product_id).with_for_update())
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Product not found"}})
    if not product.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "PRODUCT_ARCHIVED", "message": "Archived product cannot be adjusted"}})

    quantity_delta = Decimal(quantity_delta)
    movement_hash = hashlib.sha256(
        json.dumps(
            {"product_id": str(product.id), "request_id": str(request_id), "quantity_delta": str(quantity_delta), "reason": reason},
            sort_keys=True,
        ).encode("utf-8")
    ).hexdigest()

    existing = session.scalar(select(StockMovement).where(StockMovement.request_id == request_id))
    if existing is not None:
        if existing.request_hash != movement_hash:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "request_id already used with different payload"}})
        session.refresh(product)
        return product

    product.quantity_on_hand += quantity_delta
    session.add(
        StockMovement(
            product_id=product.id,
            request_id=request_id,
            request_hash=movement_hash,
            movement_type="MANUAL_ADJUSTMENT",
            quantity_delta=quantity_delta,
            reason=reason,
            created_by_user_id=current_user.id,
        )
    )
    session.commit()
    session.refresh(product)
    return product
