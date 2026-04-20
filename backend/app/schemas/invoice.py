import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, field_validator


class InvoiceLineRequest(BaseModel):
    product_id: uuid.UUID
    quantity: Decimal
    pricing_mode: str
    unit_price: Decimal
    gst_rate: Decimal
    discount_percent: Decimal = Decimal("0.00")

    @field_validator("quantity")
    @classmethod
    def validate_positive_quantity(cls, value: Decimal) -> Decimal:
        if value <= 0:
            raise ValueError("quantity must be greater than zero")
        return value


class InvoiceQuoteRequest(BaseModel):
    seller_id: uuid.UUID
    invoice_date: date
    payment_mode: str
    place_of_supply_state_code: str | None = None
    notes: str | None = None
    items: list[InvoiceLineRequest]

    @field_validator("payment_mode")
    @classmethod
    def validate_payment_mode(cls, value: str) -> str:
        if value not in {"PAID", "CREDIT"}:
            raise ValueError("payment_mode must be PAID or CREDIT")
        return value


class InvoiceCreateRequest(InvoiceQuoteRequest):
    request_id: uuid.UUID


class InvoiceCancelRequest(BaseModel):
    request_id: uuid.UUID
    cancel_reason: str


class InvoiceWarning(BaseModel):
    code: str
    message: str


class InvoiceTotalsResponse(BaseModel):
    subtotal: Decimal
    discount_total: Decimal
    taxable_total: Decimal
    gst_total: Decimal
    grand_total: Decimal


class InvoiceLineQuoteResponse(BaseModel):
    product_id: uuid.UUID
    quantity: Decimal
    pricing_mode: str
    entered_unit_price: Decimal
    unit_price_excl_tax: Decimal
    unit_price_incl_tax: Decimal
    gst_rate: Decimal
    cgst_rate: Decimal
    sgst_rate: Decimal
    igst_rate: Decimal
    discount_percent: Decimal
    discount_amount: Decimal
    taxable_amount: Decimal
    gst_amount: Decimal
    cgst_amount: Decimal
    sgst_amount: Decimal
    igst_amount: Decimal
    line_total: Decimal


class InvoiceQuoteResponse(BaseModel):
    place_of_supply_state: str
    place_of_supply_state_code: str
    tax_regime: str
    items: list[InvoiceLineQuoteResponse]
    totals: InvoiceTotalsResponse
    warnings: list[InvoiceWarning]


class InvoiceSellerSnapshotResponse(BaseModel):
    id: uuid.UUID
    name: str
    address: str
    state: str | None
    state_code: str | None
    phone: str | None
    gstin: str | None


class InvoiceCompanySnapshotResponse(BaseModel):
    name: str
    address: str
    city: str
    state: str
    state_code: str
    gstin: str | None
    phone: str | None
    email: str | None
    bank_name: str | None
    bank_account: str | None
    bank_ifsc: str | None
    bank_branch: str | None
    jurisdiction: str | None


class InvoiceItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    line_number: int
    product_name: str
    product_code: str
    company: str
    category: str
    quantity: Decimal
    pricing_mode: str
    entered_unit_price: Decimal
    unit_price_excl_tax: Decimal
    unit_price_incl_tax: Decimal
    gst_rate: Decimal
    cgst_rate: Decimal
    sgst_rate: Decimal
    igst_rate: Decimal
    discount_percent: Decimal
    discount_amount: Decimal
    taxable_amount: Decimal
    gst_amount: Decimal
    cgst_amount: Decimal
    sgst_amount: Decimal
    igst_amount: Decimal
    line_total: Decimal


class InvoiceDetailResponse(BaseModel):
    id: uuid.UUID
    request_id: uuid.UUID
    invoice_number: int
    seller_id: uuid.UUID
    invoice_date: date
    tax_regime: str
    status: str
    payment_mode: str
    place_of_supply_state: str
    place_of_supply_state_code: str
    subtotal: Decimal
    discount_total: Decimal
    taxable_total: Decimal
    gst_total: Decimal
    grand_total: Decimal
    notes: str | None
    created_at: datetime
    cancel_request_id: uuid.UUID | None
    cancel_reason: str | None
    canceled_at: datetime | None
    seller_snapshot: InvoiceSellerSnapshotResponse
    company_snapshot: InvoiceCompanySnapshotResponse
    items: list[InvoiceItemResponse]


class InvoiceCreateResponse(BaseModel):
    invoice: InvoiceDetailResponse
    warnings: list[InvoiceWarning]


class InvoiceListItemResponse(BaseModel):
    id: uuid.UUID
    invoice_number: int
    seller_id: uuid.UUID
    seller_name: str
    invoice_date: date
    status: str
    payment_mode: str
    grand_total: Decimal


class InvoiceListResponse(BaseModel):
    invoices: list[InvoiceListItemResponse]
