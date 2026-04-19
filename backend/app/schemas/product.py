import uuid
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class ProductCreateRequest(BaseModel):
    company: str
    category: str
    item_name: str
    item_code: str
    default_selling_price_excl_tax: Decimal
    default_gst_rate: Decimal
    quantity_on_hand: Decimal = Decimal("0")
    low_stock_threshold: Decimal = Decimal("0")
    buying_price_excl_tax: Decimal | None = None
    buying_gst_rate: Decimal | None = None


class ProductUpdateRequest(BaseModel):
    company: str | None = None
    category: str | None = None
    item_name: str | None = None
    item_code: str | None = None
    default_selling_price_excl_tax: Decimal | None = None
    default_gst_rate: Decimal | None = None
    low_stock_threshold: Decimal | None = None
    buying_price_excl_tax: Decimal | None = None
    buying_gst_rate: Decimal | None = None
    quantity_on_hand: Decimal | None = None


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    company: str
    category: str
    item_name: str
    item_code: str
    default_selling_price_excl_tax: Decimal
    default_gst_rate: Decimal
    quantity_on_hand: Decimal
    low_stock_threshold: Decimal
    is_active: bool
