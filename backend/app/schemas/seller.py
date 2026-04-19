import uuid

from pydantic import BaseModel, ConfigDict


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
