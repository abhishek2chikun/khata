from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.services import auth_service


def get_current_user(authorization: str | None = Header(default=None), session: Session = Depends(get_db)) -> CurrentUserResponse:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "AUTH_REQUIRED", "message": "Authentication required"}},
        )

    token = authorization.removeprefix("Bearer ").strip()
    return auth_service.current_user(session, token)
