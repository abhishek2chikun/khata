from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.invoice import InvoiceCancelRequest, InvoiceCreateRequest, InvoiceCreateResponse, InvoiceDetailResponse, InvoiceListResponse, InvoiceQuoteRequest, InvoiceQuoteResponse
from app.services import invoice_service

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.post("/quote", response_model=InvoiceQuoteResponse)
def quote_invoice(payload: InvoiceQuoteRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> InvoiceQuoteResponse:
    return invoice_service.build_quote(session, payload)


@router.post("", response_model=InvoiceCreateResponse, status_code=201)
def create_invoice(payload: InvoiceCreateRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> InvoiceCreateResponse:
    return invoice_service.create_invoice(session, payload, current_user)


@router.get("", response_model=InvoiceListResponse)
def list_invoices(
    from_date: date | None = None,
    to_date: date | None = None,
    seller_id: UUID | None = None,
    status: str | None = None,
    payment_mode: str | None = None,
    invoice_number: int | None = None,
    _: CurrentUserResponse = Depends(get_current_user),
    session: Session = Depends(get_db),
) -> InvoiceListResponse:
    return invoice_service.list_invoices(
        session,
        from_date=from_date,
        to_date=to_date,
        seller_id=seller_id,
        status_filter=status,
        payment_mode=payment_mode,
        invoice_number=invoice_number,
    )


@router.get("/{invoice_id}", response_model=InvoiceDetailResponse)
def get_invoice_detail(invoice_id: UUID, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> InvoiceDetailResponse:
    return invoice_service.get_invoice_detail(session, invoice_id)


@router.post("/{invoice_id}/cancel", response_model=InvoiceCreateResponse)
def cancel_invoice(invoice_id: UUID, payload: InvoiceCancelRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> InvoiceCreateResponse:
    return invoice_service.cancel_invoice(session, invoice_id, payload, current_user)
