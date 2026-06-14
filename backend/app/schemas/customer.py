import uuid
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Literal

from pydantic import BaseModel, ConfigDict, field_validator

MONEY_QUANT = Decimal("0.01")
MAX_MONEY = Decimal("999999999999.99")


def validate_money_amount(value: Decimal) -> Decimal:
    if value <= 0:
        raise ValueError("amount must be greater than zero")
    if value > MAX_MONEY:
        raise ValueError("amount exceeds maximum supported value")
    try:
        if value != value.quantize(MONEY_QUANT):
            raise ValueError("amount must have at most two decimal places")
    except InvalidOperation as exc:
        raise ValueError("amount must have at most two decimal places") from exc
    return value


class CustomerCreateRequest(BaseModel):
    name: str
    address: str
    phone: str | None = None
    gstin: str | None = None
    state: str | None = None
    state_code: str | None = None


class CustomerUpdateRequest(BaseModel):
    name: str
    address: str
    phone: str | None = None
    gstin: str | None = None
    state: str | None = None
    state_code: str | None = None


class CustomerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    address: str
    phone: str | None
    gstin: str | None
    state: str | None
    state_code: str | None
    is_active: bool
    pending_balance: str = "0.00"


class OpeningBalanceRequest(BaseModel):
    request_id: uuid.UUID
    amount: Decimal
    occurred_on: date

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        return validate_money_amount(value)


class CollectionRequest(BaseModel):
    request_id: uuid.UUID
    customer_id: uuid.UUID
    amount: Decimal
    occurred_on: date
    notes: str | None = None

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        return validate_money_amount(value)


class BalanceAdjustmentRequest(BaseModel):
    request_id: uuid.UUID
    direction: Literal["INCREASE", "DECREASE"]
    amount: Decimal
    occurred_on: date
    notes: str | None = None

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        return validate_money_amount(value)


class CustomerTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    entry_type: str
    amount: Decimal
    occurred_on: date
    created_at: datetime
    notes: str | None


class CustomerLedgerResponse(BaseModel):
    class InvoiceHistoryEntry(BaseModel):
        invoice_id: uuid.UUID
        invoice_number: str
        invoice_date: date
        grand_total: Decimal
        payment_mode: str
        status: str

    customer: CustomerResponse
    transactions: list[CustomerTransactionResponse]
    invoices: list[InvoiceHistoryEntry] = []


class CollectionGridCustomerRow(BaseModel):
    id: uuid.UUID
    name: str
    pending_balance: str
    existing_totals: dict[str, str]


class CollectionGridResponse(BaseModel):
    from_date: date
    to_date: date
    dates: list[date]
    customers: list[CollectionGridCustomerRow]


class BatchCollectionEntry(BaseModel):
    customer_id: uuid.UUID
    occurred_on: date
    amount: Decimal

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        return validate_money_amount(value)


class BatchCollectionRequest(BaseModel):
    request_id: uuid.UUID
    entries: list[BatchCollectionEntry]


class BatchCollectionResponse(BaseModel):
    request_id: uuid.UUID
    entry_count: int
    total_amount: str
    affected_customers: int
    customers: list[CustomerResponse]
