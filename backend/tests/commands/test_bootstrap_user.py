import subprocess
import sys

from sqlalchemy import select

from app.models.app_user import AppUser


def test_bootstrap_user_creates_first_user(db_session) -> None:
    result = subprocess.run(
        [sys.executable, "-m", "app.commands.bootstrap_user", "--username", "owner", "--password", "secret123"],
        cwd="/Users/abhishek/python_venv/khata_app/backend",
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    created = db_session.scalar(select(AppUser).where(AppUser.username == "owner"))
    assert created is not None


def test_bootstrap_user_rejects_duplicate_username(db_session) -> None:
    first = subprocess.run(
        [sys.executable, "-m", "app.commands.bootstrap_user", "--username", "owner", "--password", "secret123"],
        cwd="/Users/abhishek/python_venv/khata_app/backend",
        capture_output=True,
        text=True,
    )
    assert first.returncode == 0

    second = subprocess.run(
        [sys.executable, "-m", "app.commands.bootstrap_user", "--username", "owner", "--password", "secret123"],
        cwd="/Users/abhishek/python_venv/khata_app/backend",
        capture_output=True,
        text=True,
    )
    assert second.returncode == 1
    assert "exists" in second.stdout
