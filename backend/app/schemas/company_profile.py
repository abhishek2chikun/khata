import uuid

from pydantic import BaseModel, ConfigDict


class CompanyProfileUpsertRequest(BaseModel):
    name: str
    address: str
    city: str
    state: str
    state_code: str
    gstin: str | None = None
    phone: str | None = None
    email: str | None = None
    bank_name: str | None = None
    bank_account: str | None = None
    bank_ifsc: str | None = None
    bank_branch: str | None = None
    jurisdiction: str | None = None


class CompanyProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
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
    is_active: bool
