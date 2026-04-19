from fastapi import APIRouter, Depends, Header
from sqlalchemy.orm import Session

from app.db import get_db
from app.schemas.auth import AuthTokens, CurrentUserResponse, LoginRequest, LogoutRequest, RefreshRequest
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=AuthTokens)
def login(payload: LoginRequest, session: Session = Depends(get_db)) -> AuthTokens:
    return auth_service.login(session, payload)


@router.post("/refresh", response_model=AuthTokens)
def refresh(payload: RefreshRequest, session: Session = Depends(get_db)) -> AuthTokens:
    return auth_service.refresh(session, payload)


@router.post("/logout")
def logout(payload: LogoutRequest, session: Session = Depends(get_db)) -> dict[str, str]:
    auth_service.logout(session, payload.refresh_token)
    return {"status": "ok"}


@router.get("/me", response_model=CurrentUserResponse)
def me(authorization: str = Header(...), session: Session = Depends(get_db)) -> CurrentUserResponse:
    token = authorization.removeprefix("Bearer ").strip()
    return auth_service.current_user(session, token)
