import uuid
from datetime import datetime
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


class BuyerCreateRequest(BaseModel):
    name: str
    address: str = ""
    phone: str | None = None
    gstin: str | None = None
    state: str | None = None
    state_code: str | None = None


class BuyerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    address: str
    phone: str | None
    gstin: str | None
    state: str | None
    state_code: str | None
    is_active: bool
    pending_payable: str = "0.00"


class BuyerLedgerEntryRequest(BaseModel):
    request_id: uuid.UUID
    amount: Decimal
    occurred_at: datetime
    notes: str | None = None

    @field_validator("amount")
    @classmethod
    def validate_positive_amount(cls, value: Decimal) -> Decimal:
        return validate_money_amount(value)

    @field_validator("occurred_at")
    @classmethod
    def validate_timezone_aware_datetime(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("occurred_at must include timezone information")
        return value


class BuyerAdjustmentRequest(BuyerLedgerEntryRequest):
    direction: Literal["INCREASE", "DECREASE"]


class BuyerTransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    entry_type: str
    amount: Decimal
    occurred_at: datetime
    notes: str | None


class BuyerLedgerResponse(BaseModel):
    buyer: BuyerResponse
    transactions: list[BuyerTransactionResponse]
