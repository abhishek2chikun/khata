import uuid
from datetime import UTC, date, datetime
from decimal import Decimal, InvalidOperation

from pydantic import BaseModel, ConfigDict, field_validator, model_validator


class InvoiceLineRequest(BaseModel):
    product_id: uuid.UUID
    quantity: Decimal
    pricing_mode: str = "TAX_INCLUSIVE"
    unit_price: Decimal | None = None
    gst_rate: Decimal | None = None
    discount_percent: Decimal = Decimal("0.00")

    @field_validator("quantity")
    @classmethod
    def validate_positive_quantity(cls, value: Decimal) -> Decimal:
        if value <= 0:
            raise ValueError("quantity must be greater than zero")
        if value > Decimal("99999999999.999"):
            raise ValueError("quantity exceeds maximum supported value")
        try:
            if value != value.quantize(Decimal("0.001")):
                raise ValueError("quantity must have at most three decimal places")
        except InvalidOperation as exc:
            raise ValueError("quantity must have at most three decimal places") from exc
        return value

    @field_validator("pricing_mode")
    @classmethod
    def validate_pricing_mode(cls, value: str) -> str:
        if value not in {"TAX_INCLUSIVE", "PRE_TAX"}:
            raise ValueError("pricing_mode must be TAX_INCLUSIVE or PRE_TAX")
        return value

    @field_validator("unit_price")
    @classmethod
    def validate_unit_price(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and value <= 0:
            raise ValueError("unit_price must be greater than zero")
        return value

    @field_validator("gst_rate")
    @classmethod
    def validate_gst_rate(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and (value < 0 or value > 100):
            raise ValueError("gst_rate must be between 0 and 100")
        return value

    @field_validator("discount_percent")
    @classmethod
    def validate_discount_percent(cls, value: Decimal) -> Decimal:
        if value < 0 or value > 100:
            raise ValueError("discount_percent must be between 0 and 100")
        return value

    @model_validator(mode="after")
    def validate_required_overrides(self) -> "InvoiceLineRequest":
        if self.pricing_mode == "PRE_TAX" and self.unit_price is None:
            raise ValueError("unit_price is required when pricing_mode is PRE_TAX")
        return self


class InvoiceQuoteRequest(BaseModel):
    customer_id: uuid.UUID
    invoice_datetime: datetime | None = None
    invoice_date: date | None = None
    payment_state: str | None = None
    payment_mode: str | None = None
    paid_amount: Decimal = Decimal("0.00")
    place_of_supply_state_code: str | None = None
    notes: str | None = None
    items: list[InvoiceLineRequest]

    @field_validator("payment_state")
    @classmethod
    def validate_payment_state(cls, value: str | None) -> str | None:
        if value is not None and value not in {"CREDIT", "TOTAL_PAID", "PARTIAL_PAID"}:
            raise ValueError("payment_state must be CREDIT, TOTAL_PAID, or PARTIAL_PAID")
        return value

    @field_validator("payment_mode")
    @classmethod
    def validate_legacy_payment_mode(cls, value: str | None) -> str | None:
        if value is not None and value not in {"PAID", "CREDIT"}:
            raise ValueError("payment_mode must be PAID or CREDIT")
        return value

    @field_validator("invoice_datetime")
    @classmethod
    def validate_invoice_datetime_timezone(cls, value: datetime | None) -> datetime | None:
        if value is not None and value.tzinfo is None:
            raise ValueError("invoice_datetime must include timezone information")
        if value is not None and value.utcoffset() is None:
            raise ValueError("invoice_datetime must include timezone information")
        return value

    @model_validator(mode="after")
    def validate_invoice_date_matches_datetime(self) -> "InvoiceQuoteRequest":
        if self.invoice_datetime is not None and self.invoice_date is not None and self.invoice_datetime.date() != self.invoice_date:
            raise ValueError("invoice_date must match invoice_datetime date")
        return self

    def resolved_payment_state(self) -> str:
        if self.payment_state is not None:
            return self.payment_state
        if self.payment_mode == "PAID":
            return "TOTAL_PAID"
        return "CREDIT"

    def resolved_invoice_datetime(self) -> datetime:
        if self.invoice_datetime is not None:
            return self.invoice_datetime
        if self.invoice_date is not None:
            return datetime.combine(self.invoice_date, datetime.min.time(), tzinfo=UTC)
        return datetime.now(UTC)

    def resolved_invoice_date(self) -> date:
        return self.resolved_invoice_datetime().date()


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
    product_item_number: str
    product_item_name: str
    product_category: str
    product_buyer_id: uuid.UUID | None
    product_company_name: str
    buying_price: Decimal
    selling_price: Decimal
    unit: str | None
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
    revenue_amount: Decimal
    buying_amount: Decimal
    profit_amount: Decimal


class InvoiceQuoteResponse(BaseModel):
    place_of_supply_state: str
    place_of_supply_state_code: str
    tax_regime: str
    items: list[InvoiceLineQuoteResponse]
    totals: InvoiceTotalsResponse
    warnings: list[InvoiceWarning]


class InvoiceCustomerSnapshotResponse(BaseModel):
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
    product_item_number: str
    product_item_name: str
    product_category: str
    product_buyer_id: uuid.UUID | None
    product_company_name: str
    buying_price: Decimal
    selling_price: Decimal
    unit: str | None
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
    revenue_amount: Decimal
    buying_amount: Decimal
    profit_amount: Decimal


class InvoiceDetailResponse(BaseModel):
    id: uuid.UUID
    request_id: uuid.UUID
    invoice_number: int
    customer_id: uuid.UUID
    invoice_date: date
    invoice_datetime: datetime
    tax_regime: str
    status: str
    payment_state: str
    payment_mode: str
    paid_amount: Decimal
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
    customer_snapshot: InvoiceCustomerSnapshotResponse
    company_snapshot: InvoiceCompanySnapshotResponse
    items: list[InvoiceItemResponse]


class InvoiceCreateResponse(BaseModel):
    invoice: InvoiceDetailResponse
    warnings: list[InvoiceWarning]


class InvoiceListItemResponse(BaseModel):
    id: uuid.UUID
    invoice_number: int
    customer_id: uuid.UUID
    customer_name: str
    invoice_date: date
    status: str
    payment_state: str
    payment_mode: str
    grand_total: Decimal


class InvoiceListResponse(BaseModel):
    invoices: list[InvoiceListItemResponse]
