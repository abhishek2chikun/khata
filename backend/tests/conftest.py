import os
import subprocess
import sys
import uuid
from collections.abc import Generator
from urllib.parse import urlparse

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_engine, get_session_factory
from app.main import create_app
from app.models.app_user import AppUser
from app.models.base import Base
from app.models.invoice import Invoice  # noqa: F401
from app.models.invoice_item import InvoiceItem  # noqa: F401
from app.services.auth_service import bootstrap_user


def _assert_safe_test_database() -> None:
    database_url = get_settings().database_url
    if os.environ.get("BILLING_ALLOW_TEST_DATABASE_RESET") == "1":
        return

    parsed = urlparse(database_url)
    database_name = (parsed.path or "").rsplit("/", 1)[-1].lower()
    if "test" in database_name or "pytest" in database_name:
        return

    raise RuntimeError(
        "Refusing to run backend tests against a non-test database. "
        "Use a dedicated test database name containing 'test', or set "
        "BILLING_ALLOW_TEST_DATABASE_RESET=1 if you intentionally want destructive resets."
    )


@pytest.fixture(scope="session", autouse=True)
def migrated_database() -> Generator[None, None, None]:
    _assert_safe_test_database()
    subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], cwd=os.path.join(os.getcwd(), "backend"), check=True)
    yield


@pytest.fixture()
def db_session(migrated_database: None) -> Generator[Session, None, None]:
    session = get_session_factory()()
    yield session
    session.rollback()
    session.close()


@pytest.fixture(autouse=True)
def clean_tables(db_session: Session) -> Generator[None, None, None]:
    table_names = [table.name for table in Base.metadata.sorted_tables]

    def truncate_all() -> None:
        if table_names:
            joined = ", ".join(table_names)
            db_session.execute(text(f"TRUNCATE TABLE {joined} RESTART IDENTITY CASCADE"))
        db_session.commit()

    truncate_all()
    yield
    truncate_all()


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    with TestClient(create_app()) as test_client:
        yield test_client


@pytest.fixture()
def seeded_user(db_session: Session) -> AppUser:
    return bootstrap_user(db_session, username="owner", password="secret123", display_name="Owner")


@pytest.fixture()
def auth_headers(client: TestClient, seeded_user: AppUser) -> dict[str, str]:
    response = client.post("/auth/login", json={"username": seeded_user.username, "password": "secret123"})
    access_token = response.json()["access_token"]
    return {"Authorization": f"Bearer {access_token}"}
