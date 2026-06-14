import uuid
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, field_validator

from app.core.decimals import (
    normalize_hsn_code,
    validate_non_negative_integral_quantity,
    validate_non_zero_integral_quantity,
    validate_unit_price,
)


class ProductCreateRequest(BaseModel):
    item_number: str
    item_name: str
    category: str
    buyer_id: uuid.UUID | None = None
    company_name: str
    buying_price: Decimal
    selling_price: Decimal
    unit: str | None = None
    gst_rate: Decimal
    hsn_code: str | None = None
    quantity_on_hand: Decimal = Decimal("0")
    low_stock_threshold: Decimal = Decimal("0")

    @field_validator("hsn_code")
    @classmethod
    def validate_hsn_code(cls, value: str | None) -> str | None:
        return normalize_hsn_code(value)

    @field_validator("buying_price", "selling_price")
    @classmethod
    def validate_prices(cls, value: Decimal) -> Decimal:
        return validate_unit_price(value)

    @field_validator("quantity_on_hand", "low_stock_threshold")
    @classmethod
    def validate_quantities(cls, value: Decimal) -> Decimal:
        return validate_non_negative_integral_quantity(value)


class ProductUpdateRequest(BaseModel):
    item_number: str | None = None
    item_name: str | None = None
    category: str | None = None
    buyer_id: uuid.UUID | None = None
    company_name: str | None = None
    buying_price: Decimal | None = None
    selling_price: Decimal | None = None
    unit: str | None = None
    gst_rate: Decimal | None = None
    hsn_code: str | None = None
    quantity_on_hand: Decimal | None = None
    low_stock_threshold: Decimal | None = None

    @field_validator("hsn_code")
    @classmethod
    def validate_hsn_code(cls, value: str | None) -> str | None:
        return normalize_hsn_code(value)

    @field_validator("buying_price", "selling_price")
    @classmethod
    def validate_prices(cls, value: Decimal | None) -> Decimal | None:
        if value is None:
            return None
        return validate_unit_price(value)

    @field_validator("quantity_on_hand", "low_stock_threshold")
    @classmethod
    def validate_quantities(cls, value: Decimal | None) -> Decimal | None:
        if value is None:
            return None
        return validate_non_negative_integral_quantity(value)


class StockAdjustmentRequest(BaseModel):
    request_id: uuid.UUID
    quantity_delta: Decimal
    reason: str | None = None

    @field_validator("quantity_delta")
    @classmethod
    def validate_non_zero_quantity(cls, value: Decimal) -> Decimal:
        return validate_non_zero_integral_quantity(value)


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    item_number: str
    item_name: str
    category: str
    buyer_id: uuid.UUID | None
    company_name: str
    buying_price: Decimal
    selling_price: Decimal
    unit: str | None
    hsn_code: str | None
    gst_rate: Decimal
    quantity_on_hand: Decimal
    low_stock_threshold: Decimal
    is_active: bool
