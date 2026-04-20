import uuid
from datetime import date
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, field_validator


class SellerCreateRequest(BaseModel):
    name: str
    address: str
    phone: str | None = None
    gstin: str | None = None
    state: str | None = None
    state_code: str | None = None


class SellerUpdateRequest(BaseModel):
    name: str
    address: str
    phone: str | None = None
    gstin: str | None = None
    state: str | None = None
    state_code: str | None = None


class SellerResponse(BaseModel):
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
        if value <= 0:
            raise ValueError("amount must be greater than zero")
        return value


class PaymentRequest(BaseModel):
    request_id: uuid.UUID
    seller_id: uuid.UUID
    amount: Decimal
    occurred_on: date
    notes: str | None = None

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        if value <= 0:
            raise ValueError("amount must be greater than zero")
        return value


class BalanceAdjustmentRequest(BaseModel):
    request_id: uuid.UUID
    direction: Literal["INCREASE", "DECREASE"]
    amount: Decimal
    occurred_on: date
    notes: str | None = None

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        if value <= 0:
            raise ValueError("amount must be greater than zero")
        return value


class SellerTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    entry_type: str
    amount: Decimal
    occurred_on: date
    notes: str | None


class SellerLedgerResponse(BaseModel):
    class InvoiceHistoryEntry(BaseModel):
        invoice_id: uuid.UUID
        invoice_number: str
        invoice_date: date
        grand_total: Decimal
        payment_mode: str
        status: str

    seller: SellerResponse
    transactions: list[SellerTransactionResponse]
    invoices: list[InvoiceHistoryEntry] = []
