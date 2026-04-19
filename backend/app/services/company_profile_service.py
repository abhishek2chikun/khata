from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.company_profile import CompanyProfile
from app.schemas.company_profile import CompanyProfileUpsertRequest


def get_active_company_profile(session: Session) -> CompanyProfile:
    profile = session.scalar(select(CompanyProfile).where(CompanyProfile.is_active.is_(True)))
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error": {"code": "NOT_FOUND", "message": "Company profile not found"}})
    return profile


def upsert_company_profile(session: Session, payload: CompanyProfileUpsertRequest) -> CompanyProfile:
    profile = session.scalar(select(CompanyProfile).where(CompanyProfile.is_active.is_(True)))
    if profile is None:
        profile = CompanyProfile(**payload.model_dump())
        session.add(profile)
    else:
        for key, value in payload.model_dump().items():
            setattr(profile, key, value)

    session.commit()
    session.refresh(profile)
    return profile
