from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.customer import BalanceAdjustmentRequest, OpeningBalanceRequest, CustomerCreateRequest, CustomerLedgerResponse, CustomerResponse, CustomerTransactionResponse, CustomerUpdateRequest
from app.services import customer_service

router = APIRouter(prefix="/customers", tags=["customers"])


@router.post("", response_model=CustomerResponse, status_code=201)
def create_customer(payload: CustomerCreateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerResponse:
    return customer_service.build_customer_response(session, customer_service.create_customer(session, payload))


@router.get("", response_model=list[CustomerResponse])
def list_customers(_: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> list[CustomerResponse]:
    return [customer_service.build_customer_response(session, customer) for customer in customer_service.list_customers(session)]


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(customer_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerResponse:
    return customer_service.build_customer_response(session, customer_service.get_customer(session, customer_id))


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(customer_id: str, payload: CustomerUpdateRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerResponse:
    return customer_service.build_customer_response(session, customer_service.update_customer(session, customer_id, payload))


@router.delete("/{customer_id}", response_model=CustomerResponse)
def archive_customer(customer_id: str, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerResponse:
    return customer_service.build_customer_response(session, customer_service.archive_customer(session, customer_id))


@router.post("/{customer_id}/opening-balance", response_model=CustomerTransactionResponse, status_code=201)
def create_opening_balance(customer_id: str, payload: OpeningBalanceRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerTransactionResponse:
    transaction = customer_service.create_opening_balance(session, customer_id, payload, current_user)
    return CustomerTransactionResponse.model_validate(transaction)


@router.post("/{customer_id}/balance-adjustment", response_model=CustomerTransactionResponse, status_code=201)
def create_balance_adjustment(customer_id: str, payload: BalanceAdjustmentRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerTransactionResponse:
    transaction = customer_service.create_balance_adjustment(session, customer_id, payload, current_user)
    return CustomerTransactionResponse.model_validate(transaction)


@router.get("/{customer_id}/ledger", response_model=CustomerLedgerResponse)
def get_customer_ledger(customer_id: str, on_date: date | None = None, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CustomerLedgerResponse:
    return customer_service.get_customer_ledger(session, customer_id, on_date=on_date)
