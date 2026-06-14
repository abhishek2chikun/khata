from collections import defaultdict
from dataclasses import dataclass
from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.decimals import (
    canonical_integral_quantity_string,
    canonical_unit_price_string,
    normalize_hsn_code,
)
from app.core.idempotency import canonical_request_hash
from app.core.pricing import NormalizedLine, _round_money, normalize_line, normalize_non_gst_line
from app.core.state_codes import get_state_name, normalize_state_code
from app.core.tax import derive_tax_regime
from app.models.company_profile import CompanyProfile
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.product import Product
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.models.stock_movement import StockMovement
from app.schemas.auth import CurrentUserResponse
from app.schemas.invoice import InvoiceCancelRequest, InvoiceCompanySnapshotResponse, InvoiceCreateRequest, InvoiceCreateResponse, InvoiceDetailResponse, InvoiceItemResponse, InvoiceLineQuoteResponse, InvoiceListItemResponse, InvoiceListResponse, InvoiceQuoteRequest, InvoiceQuoteResponse, InvoiceCustomerSnapshotResponse, InvoiceTotalsResponse, InvoiceWarning


@dataclass(frozen=True)
class PreparedInvoiceLine:
    product: Product
    request_item: object
    normalized_line: NormalizedLine
    line_number: int


@dataclass(frozen=True)
class PreparedInvoice:
    customer: Customer
    company: CompanyProfile
    gst_flag: bool
    place_of_supply_state_code: str
    place_of_supply_state: str
    tax_regime: str
    lines: list[PreparedInvoiceLine]
    warnings: list[InvoiceWarning]
    totals: InvoiceTotalsResponse


def _validation_error(message: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "VALIDATION_ERROR", "message": message}})


def _policy_error(code: str, message: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": code, "message": message}})


def _validate_company_gst_profile(company: CompanyProfile) -> None:
    has_gstin = company.gstin is not None and company.gstin.strip() != ""
    if company.gst_flag and not has_gstin:
        raise _policy_error("INVALID_GST_PROFILE", "GST registered seller requires a GSTIN")
    if not company.gst_flag and has_gstin:
        raise _policy_error("INVALID_GST_PROFILE", "Non-GST seller cannot have a GSTIN")


def _resolve_gst_flag(payload: InvoiceQuoteRequest, company: CompanyProfile) -> bool:
    if payload.gst_flag is not None:
        return payload.gst_flag
    return company.gst_flag


def _resolve_line_gst_rate(item: object, product: Product) -> Decimal:
    request_rate = getattr(item, "gst_rate", None)
    if request_rate is not None:
        return Decimal(request_rate)
    return Decimal(product.gst_rate)


def _validate_invoice_gst_mode(company: CompanyProfile, resolved_gst_flag: bool, payload: InvoiceQuoteRequest, products_by_id: dict[UUID, Product]) -> None:
    _validate_company_gst_profile(company)
    if resolved_gst_flag and not company.gst_flag:
        raise _policy_error("GST_INVOICE_NOT_ALLOWED", "Non-GST seller cannot issue GST invoices")
    if not resolved_gst_flag and company.gst_flag:
        for item in payload.items:
            product = products_by_id[item.product_id]
            if _resolve_line_gst_rate(item, product) != Decimal("0.00"):
                raise _policy_error("NON_GST_TAXABLE_LINES", "Non-GST invoice cannot include taxable lines")
    if resolved_gst_flag:
        for item in payload.items:
            product = products_by_id[item.product_id]
            if normalize_hsn_code(product.hsn_code) is None:
                raise _policy_error(
                    "MISSING_PRODUCT_HSN",
                    f"Product {product.item_name} requires an HSN for GST invoices",
                )


def _normalize_prepared_line(*, item: object, product: Product, tax_regime: str, resolved_gst_flag: bool, company: CompanyProfile) -> NormalizedLine:
    unit_price = item.unit_price if item.unit_price is not None else product.selling_price
    if resolved_gst_flag:
        gst_rate = _resolve_line_gst_rate(item, product)
        return normalize_line(
            quantity=item.quantity,
            unit_price=unit_price,
            pricing_mode=item.pricing_mode,
            gst_rate=gst_rate,
            discount_percent=item.discount_percent,
            tax_regime=tax_regime,
        )
    return normalize_non_gst_line(
        quantity=item.quantity,
        unit_price=unit_price,
        pricing_mode=item.pricing_mode,
        discount_percent=item.discount_percent,
    )


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


def _resolve_place_of_supply_state_code(customer: Customer, provided_state_code: str | None) -> str:
    if provided_state_code:
        return normalize_state_code(provided_state_code)

    if customer.state_code and customer.state:
        normalized_code = normalize_state_code(customer.state_code)
        canonical_state = get_state_name(normalized_code)
        if canonical_state.lower() != customer.state.strip().lower():
            raise _validation_error("Customer state and state_code do not match")
        return normalized_code

    if customer.state_code:
        normalized_code = normalize_state_code(customer.state_code)
        get_state_name(normalized_code)
        return normalized_code

    raise _validation_error("place_of_supply_state_code is required when customer state metadata is incomplete")


def _lock_or_load_products(session: Session, product_ids: list[UUID], lock: bool) -> dict[UUID, Product]:
    unique_ids = sorted(set(product_ids))
    query = select(Product).where(Product.id.in_(unique_ids)).order_by(Product.id)
    if lock:
        query = query.with_for_update()
    products = list(session.scalars(query).all())
    return {product.id: product for product in products}


def _build_invoice_request_hash(payload: InvoiceCreateRequest, resolved_state_code: str, invoice_datetime: datetime, gst_flag: bool, paid_amount: Decimal | None = None) -> str:
    def money(value: Decimal) -> str:
        return f"{Decimal(value):.2f}"

    def quantity(value: Decimal) -> str:
        return canonical_integral_quantity_string(value)

    def unit_price(value: Decimal) -> str:
        return canonical_unit_price_string(value)

    normalized_payload = {
        "customer_id": str(payload.customer_id),
        "invoice_datetime": invoice_datetime.isoformat(),
        "payment_state": payload.resolved_payment_state(),
        "paid_amount": money(payload.paid_amount if paid_amount is None else paid_amount),
        "place_of_supply_state_code": resolved_state_code,
        "gst_flag": gst_flag,
        "notes": payload.notes,
        "items": [
            {
                "product_id": str(item.product_id),
                "quantity": quantity(item.quantity),
                "pricing_mode": item.pricing_mode,
                "unit_price": None if item.unit_price is None else unit_price(item.unit_price),
                "gst_rate": None if item.gst_rate is None else money(item.gst_rate),
                "discount_percent": money(item.discount_percent),
            }
            for item in payload.items
        ],
    }
    return canonical_request_hash(normalized_payload)


def _prepare_invoice(session: Session, payload: InvoiceQuoteRequest, *, lock_products: bool) -> PreparedInvoice:
    customer = session.get(Customer, payload.customer_id)
    if customer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Customer not found"}})
    if not customer.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error": {"code": "CUSTOMER_ARCHIVED", "message": "Archived customer cannot be invoiced"}})

    company = _get_active_company_for_invoicing(session)
    resolved_gst_flag = _resolve_gst_flag(payload, company)
    resolved_state_code = _resolve_place_of_supply_state_code(customer, payload.place_of_supply_state_code)
    resolved_state = get_state_name(resolved_state_code)
    tax_regime = derive_tax_regime(company.state_code, resolved_state_code)

    product_ids = [item.product_id for item in payload.items]
    products_by_id = _lock_or_load_products(session, product_ids, lock_products)
    if len(products_by_id) != len(set(product_ids)):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "One or more products were not found"}})

    _validate_invoice_gst_mode(company, resolved_gst_flag, payload, products_by_id)

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

        normalized_line = _normalize_prepared_line(
            item=item,
            product=product,
            tax_regime=tax_regime,
            resolved_gst_flag=resolved_gst_flag,
            company=company,
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
        customer=customer,
        company=company,
        gst_flag=resolved_gst_flag,
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
        gst_flag=prepared.gst_flag,
        items=[
            InvoiceLineQuoteResponse(
                product_id=line.product.id,
                product_item_number=line.product.item_number,
                product_item_name=line.product.item_name,
                product_category=line.product.category,
                product_buyer_id=line.product.buyer_id,
                product_company_name=line.product.company_name,
                product_hsn_code=normalize_hsn_code(line.product.hsn_code),
                buying_price=line.product.buying_price,
                selling_price=line.product.selling_price,
                unit=line.product.unit,
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
                revenue_amount=line.normalized_line.taxable_amount,
                buying_amount=_round_money(line.normalized_line.quantity * line.product.buying_price),
                profit_amount=_round_money(line.normalized_line.taxable_amount - _round_money(line.normalized_line.quantity * line.product.buying_price)),
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
            product_item_number=line.product.item_number,
            product_item_name=line.product.item_name,
            product_hsn_code=normalize_hsn_code(line.product.hsn_code),
            product_category=line.product.category,
            product_buyer_id=line.product.buyer_id,
            product_company_name=line.product.company_name,
            buying_price=line.product.buying_price,
            selling_price=line.product.selling_price,
            unit=line.product.unit,
            product_name=line.product.item_name,
            product_code=line.product.item_number,
            company=line.product.company_name,
            category=line.product.category,
            quantity=line.request_item.quantity,
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
            revenue_amount=line.normalized_line.taxable_amount,
            buying_amount=_round_money(line.normalized_line.quantity * line.product.buying_price),
            profit_amount=_round_money(line.normalized_line.taxable_amount - _round_money(line.normalized_line.quantity * line.product.buying_price)),
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

    session.add(
        CustomerTransaction(
            customer_id=invoice.customer_id,
            invoice_id=invoice.id,
            entry_type="CREDIT_SALE",
            amount=invoice.grand_total,
            occurred_on=invoice.invoice_date,
            notes=f"Invoice {invoice.invoice_number}",
            created_by_user_id=current_user.id,
        )
    )
    if invoice.paid_amount > 0:
        session.add(
            CustomerTransaction(
                customer_id=invoice.customer_id,
                invoice_id=invoice.id,
                entry_type="COLLECTION",
                amount=invoice.paid_amount,
                occurred_on=invoice.invoice_date,
                notes=f"Invoice {invoice.invoice_number} collection",
                created_by_user_id=current_user.id,
            )
        )


def _resolve_paid_amount(payment_state: str, paid_amount: Decimal, grand_total: Decimal) -> Decimal:
    if payment_state == "CREDIT":
        if paid_amount != Decimal("0.00"):
            raise _validation_error("paid_amount must be 0.00 for CREDIT invoices")
        return Decimal("0.00")
    if payment_state == "TOTAL_PAID":
        if paid_amount not in {Decimal("0.00"), grand_total}:
            raise _validation_error("paid_amount must equal grand_total for TOTAL_PAID invoices")
        return grand_total
    if paid_amount <= 0 or paid_amount >= grand_total:
        raise _validation_error("paid_amount must be greater than zero and less than grand_total for PARTIAL_PAID invoices")
    return _round_money(paid_amount)


def _build_invoice_detail(session: Session, invoice: Invoice) -> InvoiceDetailResponse:
    items = list(session.scalars(select(InvoiceItem).where(InvoiceItem.invoice_id == invoice.id).order_by(InvoiceItem.line_number)).all())
    return InvoiceDetailResponse(
        id=invoice.id,
        request_id=invoice.request_id,
        invoice_number=invoice.invoice_number,
        customer_id=invoice.customer_id,
        invoice_date=invoice.invoice_date,
        invoice_datetime=invoice.invoice_datetime,
        tax_regime=invoice.tax_regime,
        gst_flag=invoice.gst_flag,
        status=invoice.status,
        payment_state=invoice.payment_state,
        payment_mode=invoice.payment_state,
        paid_amount=invoice.paid_amount,
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
        customer_snapshot=InvoiceCustomerSnapshotResponse(
            id=invoice.customer_id,
            name=invoice.customer_name,
            address=invoice.customer_address,
            state=invoice.customer_state,
            state_code=invoice.customer_state_code,
            phone=invoice.customer_phone,
            gstin=invoice.customer_gstin,
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
            paid_amount = _resolve_paid_amount(payload.resolved_payment_state(), payload.paid_amount, existing.grand_total)
            request_hash = _build_invoice_request_hash(
                payload, existing.place_of_supply_state_code, existing.invoice_datetime, existing.gst_flag, paid_amount
            )
            if existing.request_hash != request_hash:
                raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail={"error": {"code": "IDEMPOTENCY_CONFLICT", "message": "An invoice already exists for this request_id with different content"}})
            return InvoiceCreateResponse(invoice=_build_invoice_detail(session, existing), warnings=[])

        prepared = _prepare_invoice(session, payload, lock_products=True)
        invoice_datetime = payload.resolved_invoice_datetime()
        payment_state = payload.resolved_payment_state()
        paid_amount = _resolve_paid_amount(payment_state, payload.paid_amount, prepared.totals.grand_total)
        request_hash = _build_invoice_request_hash(
            payload, prepared.place_of_supply_state_code, invoice_datetime, prepared.gst_flag, paid_amount
        )

        invoice = Invoice(
            request_id=payload.request_id,
            request_hash=request_hash,
            customer_id=prepared.customer.id,
            customer_name=prepared.customer.name,
            customer_address=prepared.customer.address,
            customer_state=prepared.customer.state,
            customer_state_code=prepared.customer.state_code,
            customer_phone=prepared.customer.phone,
            customer_gstin=prepared.customer.gstin,
            place_of_supply_state_code=prepared.place_of_supply_state_code,
            company_name=prepared.company.name,
            company_address=prepared.company.address,
            company_city=prepared.company.city,
            company_state=prepared.company.state,
            company_state_code=prepared.company.state_code,
            company_gstin=prepared.company.gstin if prepared.gst_flag else None,
            company_phone=prepared.company.phone,
            company_email=prepared.company.email,
            company_bank_name=prepared.company.bank_name,
            company_bank_account=prepared.company.bank_account,
            company_bank_ifsc=prepared.company.bank_ifsc,
            company_bank_branch=prepared.company.bank_branch,
            company_jurisdiction=prepared.company.jurisdiction,
            gst_flag=prepared.gst_flag,
            invoice_date=invoice_datetime.date(),
            invoice_datetime=invoice_datetime,
            tax_regime=prepared.tax_regime,
            status="ACTIVE",
            payment_state=payment_state,
            paid_amount=paid_amount,
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
            paid_amount = _resolve_paid_amount(payload.resolved_payment_state(), payload.paid_amount, existing.grand_total)
            request_hash = _build_invoice_request_hash(
                payload, existing.place_of_supply_state_code, existing.invoice_datetime, existing.gst_flag, paid_amount
            )
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
    customer_id: UUID | None = None,
    status_filter: str | None = None,
    payment_state: str | None = None,
    invoice_number: int | None = None,
) -> InvoiceListResponse:
    query = select(Invoice).order_by(Invoice.invoice_number.desc())
    if from_date is not None:
        query = query.where(Invoice.invoice_date >= from_date)
    if to_date is not None:
        query = query.where(Invoice.invoice_date <= to_date)
    if customer_id is not None:
        query = query.where(Invoice.customer_id == customer_id)
    if status_filter is not None:
        query = query.where(Invoice.status == status_filter)
    if payment_state is not None:
        query = query.where(Invoice.payment_state == payment_state)
    if invoice_number is not None:
        query = query.where(Invoice.invoice_number == invoice_number)
    invoices = list(session.scalars(query).all())
    return InvoiceListResponse(
        invoices=[
            InvoiceListItemResponse(
                id=invoice.id,
                invoice_number=invoice.invoice_number,
                customer_id=invoice.customer_id,
                customer_name=invoice.customer_name,
                invoice_date=invoice.invoice_date,
                status=invoice.status,
                gst_flag=invoice.gst_flag,
                payment_state=invoice.payment_state,
                payment_mode=invoice.payment_state,
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

        session.add(
            CustomerTransaction(
                customer_id=invoice.customer_id,
                invoice_id=invoice.id,
                entry_type="INVOICE_CANCEL_REVERSAL",
                amount=invoice.grand_total,
                occurred_on=cancellation_date,
                notes=f"Cancel invoice {invoice.invoice_number}",
                created_by_user_id=current_user.id,
            )
        )
        if invoice.paid_amount > 0:
            session.add(
                CustomerTransaction(
                    customer_id=invoice.customer_id,
                    invoice_id=invoice.id,
                    entry_type="COLLECTION_REVERSAL",
                    amount=invoice.paid_amount,
                    occurred_on=cancellation_date,
                    notes=f"Cancel invoice {invoice.invoice_number} collection",
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
