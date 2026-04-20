from collections import defaultdict
from dataclasses import dataclass
from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.idempotency import canonical_request_hash
from app.core.pricing import NormalizedLine, normalize_line
from app.core.state_codes import get_state_name, normalize_state_code
from app.core.tax import derive_tax_regime
from app.models.company_profile import CompanyProfile
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.product import Product
from app.models.seller import Seller
from app.models.seller_transaction import SellerTransaction
from app.models.stock_movement import StockMovement
from app.schemas.auth import CurrentUserResponse
from app.schemas.invoice import InvoiceCancelRequest, InvoiceCompanySnapshotResponse, InvoiceCreateRequest, InvoiceCreateResponse, InvoiceDetailResponse, InvoiceItemResponse, InvoiceLineQuoteResponse, InvoiceListItemResponse, InvoiceListResponse, InvoiceQuoteRequest, InvoiceQuoteResponse, InvoiceSellerSnapshotResponse, InvoiceTotalsResponse, InvoiceWarning


@dataclass(frozen=True)
class PreparedInvoiceLine:
    product: Product
    request_item: object
    normalized_line: NormalizedLine
    line_number: int


@dataclass(frozen=True)
class PreparedInvoice:
    seller: Seller
    company: CompanyProfile
    place_of_supply_state_code: str
    place_of_supply_state: str
    tax_regime: str
    lines: list[PreparedInvoiceLine]
    warnings: list[InvoiceWarning]
    totals: InvoiceTotalsResponse


def _validation_error(message: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": message}})


def _create_failed(message: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail={"error": {"code": "INVOICE_CREATE_FAILED", "message": message}})


def _get_active_company_for_invoicing(session: Session) -> CompanyProfile:
    company = session.scalar(select(CompanyProfile).where(CompanyProfile.is_active.is_(True)))
    if company is None or not company.state or not company.state_code:
        raise _validation_error("Complete company profile state metadata before invoicing")

    normalized_company_code = normalize_state_code(company.state_code)
    canonical_company_state = get_state_name(normalized_company_code)
    if company.state.strip().lower() != canonical_company_state.lower():
        raise _validation_error("Company profile state and state_code do not match")
    return company


def _resolve_place_of_supply_state_code(seller: Seller, provided_state_code: str | None) -> str:
    if provided_state_code:
        return normalize_state_code(provided_state_code)

    if seller.state_code and seller.state:
        normalized_code = normalize_state_code(seller.state_code)
        canonical_state = get_state_name(normalized_code)
        if canonical_state.lower() != seller.state.strip().lower():
            raise _validation_error("Seller state and state_code do not match")
        return normalized_code

    if seller.state_code:
        normalized_code = normalize_state_code(seller.state_code)
        get_state_name(normalized_code)
        return normalized_code

    raise _validation_error("place_of_supply_state_code is required when seller state metadata is incomplete")


def _lock_or_load_products(session: Session, product_ids: list[UUID], lock: bool) -> dict[UUID, Product]:
    unique_ids = sorted(set(product_ids))
    query = select(Product).where(Product.id.in_(unique_ids)).order_by(Product.id)
    if lock:
        query = query.with_for_update()
    products = list(session.scalars(query).all())
    return {product.id: product for product in products}


def _build_invoice_request_hash(payload: InvoiceCreateRequest, resolved_state_code: str) -> str:
    def money(value: Decimal) -> str:
        return f"{Decimal(value):.2f}"

    def quantity(value: Decimal) -> str:
        return f"{Decimal(value):.3f}"

    normalized_payload = {
        "seller_id": str(payload.seller_id),
        "invoice_date": payload.invoice_date.isoformat(),
        "payment_mode": payload.payment_mode,
        "place_of_supply_state_code": resolved_state_code,
        "notes": payload.notes,
        "items": [
            {
                "product_id": str(item.product_id),
                "quantity": quantity(item.quantity),
                "pricing_mode": item.pricing_mode,
                "unit_price": money(item.unit_price),
                "gst_rate": money(item.gst_rate),
                "discount_percent": money(item.discount_percent),
            }
            for item in payload.items
        ],
    }
    return canonical_request_hash(normalized_payload)


def _prepare_invoice(session: Session, payload: InvoiceQuoteRequest, *, lock_products: bool) -> PreparedInvoice:
    seller = session.get(Seller, payload.seller_id)
    if seller is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Seller not found"}})
    if not seller.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "SELLER_ARCHIVED", "message": "Archived seller cannot be invoiced"}})

    company = _get_active_company_for_invoicing(session)
    resolved_state_code = _resolve_place_of_supply_state_code(seller, payload.place_of_supply_state_code)
    resolved_state = get_state_name(resolved_state_code)
    tax_regime = derive_tax_regime(company.state_code, resolved_state_code)

    product_ids = [item.product_id for item in payload.items]
    products_by_id = _lock_or_load_products(session, product_ids, lock_products)
    if len(products_by_id) != len(set(product_ids)):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "One or more products were not found"}})

    warnings: list[InvoiceWarning] = []
    consumed_quantities: dict[UUID, Decimal] = defaultdict(lambda: Decimal("0.000"))
    prepared_lines: list[PreparedInvoiceLine] = []
    subtotal = Decimal("0.00")
    discount_total = Decimal("0.00")
    taxable_total = Decimal("0.00")
    gst_total = Decimal("0.00")
    grand_total = Decimal("0.00")

    for line_number, item in enumerate(payload.items, start=1):
        product = products_by_id[item.product_id]
        if not product.is_active:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "PRODUCT_ARCHIVED", "message": "Archived product cannot be invoiced"}})

        normalized_line = normalize_line(
            quantity=item.quantity,
            unit_price=item.unit_price,
            pricing_mode=item.pricing_mode,
            gst_rate=item.gst_rate,
            discount_percent=item.discount_percent,
            tax_regime=tax_regime,
        )
        prepared_lines.append(PreparedInvoiceLine(product=product, request_item=item, normalized_line=normalized_line, line_number=line_number))

        line_subtotal = normalized_line.taxable_amount + normalized_line.discount_amount
        subtotal += line_subtotal
        discount_total += normalized_line.discount_amount
        taxable_total += normalized_line.taxable_amount
        gst_total += normalized_line.gst_amount
        grand_total += normalized_line.line_total

        consumed_quantities[product.id] += item.quantity
        projected_quantity = product.quantity_on_hand - consumed_quantities[product.id]
        if projected_quantity < 0:
            warnings.append(
                InvoiceWarning(
                    code="NEGATIVE_STOCK",
                    message=f"{product.item_name} will go negative to {projected_quantity}",
                )
            )

    return PreparedInvoice(
        seller=seller,
        company=company,
        place_of_supply_state_code=resolved_state_code,
        place_of_supply_state=resolved_state,
        tax_regime=tax_regime,
        lines=prepared_lines,
        warnings=warnings,
        totals=InvoiceTotalsResponse(
            subtotal=subtotal,
            discount_total=discount_total,
            taxable_total=taxable_total,
            gst_total=gst_total,
            grand_total=grand_total,
        ),
    )


def build_quote(session: Session, payload: InvoiceQuoteRequest) -> InvoiceQuoteResponse:
    prepared = _prepare_invoice(session, payload, lock_products=False)
    return InvoiceQuoteResponse(
        place_of_supply_state=prepared.place_of_supply_state,
        place_of_supply_state_code=prepared.place_of_supply_state_code,
        tax_regime=prepared.tax_regime,
        items=[
            InvoiceLineQuoteResponse(
                product_id=line.product.id,
                quantity=line.normalized_line.quantity,
                pricing_mode=line.normalized_line.pricing_mode,
                entered_unit_price=line.normalized_line.entered_unit_price,
                unit_price_excl_tax=line.normalized_line.unit_price_excl_tax,
                unit_price_incl_tax=line.normalized_line.unit_price_incl_tax,
                gst_rate=line.normalized_line.gst_rate,
                cgst_rate=line.normalized_line.cgst_rate,
                sgst_rate=line.normalized_line.sgst_rate,
                igst_rate=line.normalized_line.igst_rate,
                discount_percent=line.normalized_line.discount_percent,
                discount_amount=line.normalized_line.discount_amount,
                taxable_amount=line.normalized_line.taxable_amount,
                gst_amount=line.normalized_line.gst_amount,
                cgst_amount=line.normalized_line.cgst_amount,
                sgst_amount=line.normalized_line.sgst_amount,
                igst_amount=line.normalized_line.igst_amount,
                line_total=line.normalized_line.line_total,
            )
            for line in prepared.lines
        ],
        totals=prepared.totals,
        warnings=prepared.warnings,
    )


def _insert_invoice_items(session: Session, invoice: Invoice, prepared: PreparedInvoice) -> list[InvoiceItem]:
    items: list[InvoiceItem] = []
    for line in prepared.lines:
        item = InvoiceItem(
            invoice_id=invoice.id,
            product_id=line.product.id,
            line_number=line.line_number,
            product_name=line.product.item_name,
            product_code=line.product.item_code,
            company=line.product.company,
            category=line.product.category,
            quantity=line.request_item.quantity,
            pricing_mode=line.request_item.pricing_mode,
            entered_unit_price=line.request_item.unit_price,
            unit_price_excl_tax=line.normalized_line.unit_price_excl_tax,
            unit_price_incl_tax=line.normalized_line.unit_price_incl_tax,
            gst_rate=line.normalized_line.gst_rate,
            cgst_rate=line.normalized_line.cgst_rate,
            sgst_rate=line.normalized_line.sgst_rate,
            igst_rate=line.normalized_line.igst_rate,
            discount_percent=line.request_item.discount_percent,
            discount_amount=line.normalized_line.discount_amount,
            taxable_amount=line.normalized_line.taxable_amount,
            gst_amount=line.normalized_line.gst_amount,
            cgst_amount=line.normalized_line.cgst_amount,
            sgst_amount=line.normalized_line.sgst_amount,
            igst_amount=line.normalized_line.igst_amount,
            line_total=line.normalized_line.line_total,
        )
        session.add(item)
        items.append(item)
    session.flush()
    return items


def _apply_stock_and_ledger(session: Session, invoice: Invoice, prepared: PreparedInvoice, current_user: CurrentUserResponse) -> None:
    for line in prepared.lines:
        session.add(
            StockMovement(
                product_id=line.product.id,
                invoice_id=invoice.id,
                movement_type="INVOICE_SALE",
                quantity_delta=-line.request_item.quantity,
                reason=f"Invoice {invoice.invoice_number}",
                created_by_user_id=current_user.id,
            )
        )
        line.product.quantity_on_hand -= line.request_item.quantity

    if invoice.payment_mode == "CREDIT":
        session.add(
            SellerTransaction(
                seller_id=invoice.seller_id,
                invoice_id=invoice.id,
                entry_type="CREDIT_SALE",
                amount=invoice.grand_total,
                occurred_on=invoice.invoice_date,
                notes=f"Invoice {invoice.invoice_number}",
                created_by_user_id=current_user.id,
            )
        )


def _build_invoice_detail(session: Session, invoice: Invoice) -> InvoiceDetailResponse:
    items = list(session.scalars(select(InvoiceItem).where(InvoiceItem.invoice_id == invoice.id).order_by(InvoiceItem.line_number)).all())
    return InvoiceDetailResponse(
        id=invoice.id,
        request_id=invoice.request_id,
        invoice_number=invoice.invoice_number,
        seller_id=invoice.seller_id,
        invoice_date=invoice.invoice_date,
        tax_regime=invoice.tax_regime,
        status=invoice.status,
        payment_mode=invoice.payment_mode,
        place_of_supply_state=invoice.place_of_supply_state,
        place_of_supply_state_code=invoice.place_of_supply_state_code,
        subtotal=invoice.subtotal,
        discount_total=invoice.discount_total,
        taxable_total=invoice.taxable_total,
        gst_total=invoice.gst_total,
        grand_total=invoice.grand_total,
        notes=invoice.notes,
        created_at=invoice.created_at,
        cancel_request_id=invoice.cancel_request_id,
        cancel_reason=invoice.cancel_reason,
        canceled_at=invoice.canceled_at,
        seller_snapshot=InvoiceSellerSnapshotResponse(
            id=invoice.seller_id,
            name=invoice.seller_name,
            address=invoice.seller_address,
            state=invoice.seller_state,
            state_code=invoice.seller_state_code,
            phone=invoice.seller_phone,
            gstin=invoice.seller_gstin,
        ),
        company_snapshot=InvoiceCompanySnapshotResponse(
            name=invoice.company_name,
            address=invoice.company_address,
            city=invoice.company_city,
            state=invoice.company_state,
            state_code=invoice.company_state_code,
            gstin=invoice.company_gstin,
            phone=invoice.company_phone,
            email=invoice.company_email,
            bank_name=invoice.company_bank_name,
            bank_account=invoice.company_bank_account,
            bank_ifsc=invoice.company_bank_ifsc,
            bank_branch=invoice.company_bank_branch,
            jurisdiction=invoice.company_jurisdiction,
        ),
        items=[InvoiceItemResponse.model_validate(item) for item in items],
    )


def _build_cancel_request_hash(payload: InvoiceCancelRequest) -> str:
    return canonical_request_hash({"request_id": str(payload.request_id), "cancel_reason": payload.cancel_reason})


def create_invoice(session: Session, payload: InvoiceCreateRequest, current_user: CurrentUserResponse) -> InvoiceCreateResponse:
    try:
        existing = session.scalar(select(Invoice).where(Invoice.request_id == payload.request_id))
        if existing is not None:
            request_hash = _build_invoice_request_hash(payload, existing.place_of_supply_state_code)
            if existing.request_hash != request_hash:
                raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "An invoice already exists for this request_id with different content"}})
            return InvoiceCreateResponse(invoice=_build_invoice_detail(session, existing), warnings=[])

        prepared = _prepare_invoice(session, payload, lock_products=True)
        request_hash = _build_invoice_request_hash(payload, prepared.place_of_supply_state_code)

        invoice = Invoice(
            request_id=payload.request_id,
            request_hash=request_hash,
            seller_id=prepared.seller.id,
            seller_name=prepared.seller.name,
            seller_address=prepared.seller.address,
            seller_state=prepared.seller.state,
            seller_state_code=prepared.seller.state_code,
            seller_phone=prepared.seller.phone,
            seller_gstin=prepared.seller.gstin,
            place_of_supply_state_code=prepared.place_of_supply_state_code,
            company_name=prepared.company.name,
            company_address=prepared.company.address,
            company_city=prepared.company.city,
            company_state=prepared.company.state,
            company_state_code=prepared.company.state_code,
            company_gstin=prepared.company.gstin,
            company_phone=prepared.company.phone,
            company_email=prepared.company.email,
            company_bank_name=prepared.company.bank_name,
            company_bank_account=prepared.company.bank_account,
            company_bank_ifsc=prepared.company.bank_ifsc,
            company_bank_branch=prepared.company.bank_branch,
            company_jurisdiction=prepared.company.jurisdiction,
            invoice_date=payload.invoice_date,
            tax_regime=prepared.tax_regime,
            status="ACTIVE",
            payment_mode=payload.payment_mode,
            subtotal=prepared.totals.subtotal,
            discount_total=prepared.totals.discount_total,
            taxable_total=prepared.totals.taxable_total,
            gst_total=prepared.totals.gst_total,
            grand_total=prepared.totals.grand_total,
            notes=payload.notes,
            created_by_user_id=current_user.id,
        )
        session.add(invoice)
        session.flush()
        _insert_invoice_items(session, invoice, prepared)
        _apply_stock_and_ledger(session, invoice, prepared, current_user)
        session.commit()
        session.refresh(invoice)
        return InvoiceCreateResponse(invoice=_build_invoice_detail(session, invoice), warnings=prepared.warnings)
    except HTTPException:
        session.rollback()
        raise
    except IntegrityError as exc:
        session.rollback()
        existing = session.scalar(select(Invoice).where(Invoice.request_id == payload.request_id))
        if existing is not None:
            request_hash = _build_invoice_request_hash(payload, existing.place_of_supply_state_code)
            if existing.request_hash == request_hash:
                return InvoiceCreateResponse(invoice=_build_invoice_detail(session, existing), warnings=[])
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "An invoice already exists for this request_id with different content"}}) from exc
        raise _create_failed("Invoice creation failed") from exc
    except Exception as exc:
        session.rollback()
        raise _create_failed("Invoice creation failed") from exc


def list_invoices(
    session: Session,
    *,
    from_date: date | None = None,
    to_date: date | None = None,
    seller_id: UUID | None = None,
    status_filter: str | None = None,
    payment_mode: str | None = None,
    invoice_number: int | None = None,
) -> InvoiceListResponse:
    query = select(Invoice).order_by(Invoice.invoice_number.desc())
    if from_date is not None:
        query = query.where(Invoice.invoice_date >= from_date)
    if to_date is not None:
        query = query.where(Invoice.invoice_date <= to_date)
    if seller_id is not None:
        query = query.where(Invoice.seller_id == seller_id)
    if status_filter is not None:
        query = query.where(Invoice.status == status_filter)
    if payment_mode is not None:
        query = query.where(Invoice.payment_mode == payment_mode)
    if invoice_number is not None:
        query = query.where(Invoice.invoice_number == invoice_number)
    invoices = list(session.scalars(query).all())
    return InvoiceListResponse(
        invoices=[
            InvoiceListItemResponse(
                id=invoice.id,
                invoice_number=invoice.invoice_number,
                seller_id=invoice.seller_id,
                seller_name=invoice.seller_name,
                invoice_date=invoice.invoice_date,
                status=invoice.status,
                payment_mode=invoice.payment_mode,
                grand_total=invoice.grand_total,
            )
            for invoice in invoices
        ]
    )


def get_invoice_detail(session: Session, invoice_id: UUID) -> InvoiceDetailResponse:
    invoice = session.get(Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Invoice not found"}})
    return _build_invoice_detail(session, invoice)


def cancel_invoice(session: Session, invoice_id: UUID, payload: InvoiceCancelRequest, current_user: CurrentUserResponse) -> InvoiceCreateResponse:
    invoice = session.scalar(select(Invoice).where(Invoice.id == invoice_id).with_for_update())
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Invoice not found"}})

    cancel_request_hash = _build_cancel_request_hash(payload)
    if invoice.status == "CANCELED":
        if invoice.cancel_request_id == payload.request_id:
            if invoice.cancel_request_hash != cancel_request_hash:
                raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "Cancel request_id already used with different payload"}})
            return InvoiceCreateResponse(invoice=_build_invoice_detail(session, invoice), warnings=[])
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "INVOICE_ALREADY_CANCELED", "message": "Invoice is already canceled"}})

    items = list(session.scalars(select(InvoiceItem).where(InvoiceItem.invoice_id == invoice.id).order_by(InvoiceItem.product_id).with_for_update()).all())
    product_ids = [item.product_id for item in items]
    products_by_id = _lock_or_load_products(session, product_ids, lock=True)
    canceled_at = datetime.now(UTC)
    cancellation_date = canceled_at.date()

    try:
        invoice.status = "CANCELED"
        invoice.cancel_request_id = payload.request_id
        invoice.cancel_request_hash = cancel_request_hash
        invoice.cancel_reason = payload.cancel_reason
        invoice.canceled_at = canceled_at
        invoice.canceled_by_user_id = current_user.id

        for item in items:
            product = products_by_id[item.product_id]
            product.quantity_on_hand += item.quantity
            session.add(
                StockMovement(
                    product_id=product.id,
                    invoice_id=invoice.id,
                    movement_type="INVOICE_CANCEL_REVERSAL",
                    quantity_delta=item.quantity,
                    reason=f"Cancel invoice {invoice.invoice_number}",
                    created_by_user_id=current_user.id,
                )
            )

        if invoice.payment_mode == "CREDIT":
            session.add(
                SellerTransaction(
                    seller_id=invoice.seller_id,
                    invoice_id=invoice.id,
                    entry_type="INVOICE_CANCEL_REVERSAL",
                    amount=invoice.grand_total,
                    occurred_on=cancellation_date,
                    notes=f"Cancel invoice {invoice.invoice_number}",
                    created_by_user_id=current_user.id,
                )
            )

        session.commit()
        session.refresh(invoice)
        return InvoiceCreateResponse(invoice=_build_invoice_detail(session, invoice), warnings=[])
    except HTTPException:
        session.rollback()
        raise
    except Exception as exc:
        session.rollback()
        raise _create_failed("Invoice cancellation failed") from exc
