from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.db import get_db
from app.schemas.analytics import DashboardResponse
from app.schemas.auth import CurrentUserResponse
from app.services import analytics_service

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(
    from_date: date | None = None,
    to_date: date | None = None,
    _: CurrentUserResponse = Depends(get_current_user),
    session: Session = Depends(get_db),
) -> DashboardResponse:
    return DashboardResponse(
        **analytics_service.get_dashboard(session, from_date=from_date, to_date=to_date)
    )
