from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.company_profile import CompanyProfileResponse, CompanyProfileUpsertRequest
from app.services import company_profile_service

router = APIRouter(prefix="/company-profile", tags=["company-profile"])


@router.get("", response_model=CompanyProfileResponse)
def get_company_profile(_: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CompanyProfileResponse:
    return CompanyProfileResponse.model_validate(company_profile_service.get_active_company_profile(session))


@router.put("", response_model=CompanyProfileResponse)
def upsert_company_profile(payload: CompanyProfileUpsertRequest, _: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> CompanyProfileResponse:
    return CompanyProfileResponse.model_validate(company_profile_service.upsert_company_profile(session, payload))
