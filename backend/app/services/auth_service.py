import hashlib
import secrets
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.core.security import InvalidTokenError, create_access_token, decode_token, hash_password, verify_password
from app.models.app_user import AppUser
from app.models.user_session import UserSession
from app.schemas.auth import AuthTokens, CurrentUserResponse, LoginRequest, RefreshRequest


def _hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _new_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def bootstrap_user(session: Session, username: str, password: str, display_name: str | None = None) -> AppUser:
    existing = session.scalar(select(AppUser).where(AppUser.username == username))
    if existing is not None:
        raise ValueError("username already exists")

    user = AppUser(username=username, password_hash=hash_password(password), display_name=display_name)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def login(session: Session, payload: LoginRequest) -> AuthTokens:
    user = session.scalar(select(AppUser).where(AppUser.username == payload.username, AppUser.is_active.is_(True)))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_CREDENTIALS", "message": "Invalid username or password"}},
        )

    refresh_token = _new_refresh_token()
    settings = get_settings()
    now = datetime.now(UTC)
    user_session = UserSession(
        user_id=user.id,
        refresh_token_hash=_hash_refresh_token(refresh_token),
        expires_at=now + timedelta(days=30),
        last_used_at=now,
        created_at=now,
    )
    session.add(user_session)
    session.commit()

    return AuthTokens(access_token=create_access_token(subject=str(user.id)), refresh_token=refresh_token)


def refresh(session: Session, payload: RefreshRequest) -> AuthTokens:
    token_hash = _hash_refresh_token(payload.refresh_token)
    current_session = session.scalar(select(UserSession).where(UserSession.refresh_token_hash == token_hash))
    now = datetime.now(UTC)
    if current_session is None or current_session.revoked_at is not None or current_session.expires_at <= now:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_REFRESH_TOKEN", "message": "Refresh token is invalid or expired"}},
        )

    user = session.get(AppUser, current_session.user_id)
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_REFRESH_TOKEN", "message": "Refresh token is invalid or expired"}},
        )

    current_session.revoked_at = now

    new_refresh_token = _new_refresh_token()
    rotated_session = UserSession(
        user_id=user.id,
        refresh_token_hash=_hash_refresh_token(new_refresh_token),
        expires_at=now + timedelta(days=30),
        last_used_at=now,
        created_at=now,
    )
    session.add(rotated_session)
    session.commit()

    return AuthTokens(access_token=create_access_token(subject=str(user.id)), refresh_token=new_refresh_token)


def logout(session: Session, refresh_token: str) -> None:
    token_hash = _hash_refresh_token(refresh_token)
    current_session = session.scalar(select(UserSession).where(UserSession.refresh_token_hash == token_hash))
    if current_session is not None and current_session.revoked_at is None:
        current_session.revoked_at = datetime.now(UTC)
        session.commit()


def current_user(session: Session, bearer_token: str) -> CurrentUserResponse:
    try:
        payload = decode_token(bearer_token)
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_ACCESS_TOKEN", "message": "Access token is invalid"}},
        ) from exc

    user = session.get(AppUser, payload["sub"])
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_ACCESS_TOKEN", "message": "Access token is invalid"}},
        )
    return CurrentUserResponse(id=str(user.id), username=user.username, display_name=user.display_name)
