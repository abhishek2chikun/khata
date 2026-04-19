from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.product import ProductCreateRequest, ProductResponse, ProductUpdateRequest
from app.services import product_service

router = APIRouter(prefix="/products", tags=["products"])


@router.post("", response_model=ProductResponse, status_code=201)
def create_product(current_user: CurrentUserResponse = Depends(get_current_user), payload: ProductCreateRequest = ..., session: Session = Depends(get_db)) -> ProductResponse:
    return ProductResponse.model_validate(product_service.create_product(session, payload, current_user))


@router.get("", response_model=list[ProductResponse])
def list_products(company: str | None = None, category: str | None = None, search: str | None = None, active: bool | None = None, low_stock_only: bool | None = None, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> list[ProductResponse]:
    return [ProductResponse.model_validate(product) for product in product_service.list_products(session, company, category, search, active, low_stock_only)]


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> ProductResponse:
    return ProductResponse.model_validate(product_service.get_product(session, product_id))


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(product_id: str, payload: ProductUpdateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> ProductResponse:
    return ProductResponse.model_validate(product_service.update_product(session, product_id, payload))


@router.delete("/{product_id}", response_model=ProductResponse)
def archive_product(product_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> ProductResponse:
    return ProductResponse.model_validate(product_service.archive_product(session, product_id))
