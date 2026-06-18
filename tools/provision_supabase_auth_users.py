#!/usr/bin/env python3
"""Create or update Supabase Auth users from .env test-user variables."""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ[key.strip()] = value.strip()


def discover_users() -> list[tuple[str, str, str]]:
    pattern = re.compile(r"^SUPABASE_TEST_USER_(?P<role>[A-Z_]+)_EMAIL$")
    users: list[tuple[str, str, str]] = []
    for key, email in os.environ.items():
        match = pattern.match(key)
        if not match:
            continue
        role = match.group("role")
        password_key = f"SUPABASE_TEST_USER_{role}_PASSWORD"
        password = os.environ.get(password_key)
        if not password:
            print(f"skip {role}: missing {password_key}", file=sys.stderr)
            continue
        users.append((role, email.strip(), password))
    return users


def admin_request(
    *,
    url: str,
    service_role: str,
    method: str,
    path: str,
    payload: dict | None = None,
) -> tuple[int, dict]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"{url.rstrip('/')}{path}",
        data=body,
        method=method,
        headers={
            "apikey": service_role,
            "Authorization": f"Bearer {service_role}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8")
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"message": raw}
        return error.code, parsed


def list_all_users(url: str, service_role: str) -> list[dict]:
    users: list[dict] = []
    page = 1
    while True:
        status, payload = admin_request(
            url=url,
            service_role=service_role,
            method="GET",
            path=f"/auth/v1/admin/users?page={page}&per_page=200",
        )
        if status >= 400:
            raise RuntimeError(f"list users failed: HTTP {status} {payload}")
        batch = payload.get("users") or []
        users.extend(batch)
        if len(batch) < 200:
            break
        page += 1
    return users


def find_user_by_email(users: list[dict], email: str) -> dict | None:
    target = email.strip().lower()
    for user in users:
        if (user.get("email") or "").strip().lower() == target:
            return user
    return None


def upsert_user(
    url: str,
    service_role: str,
    email: str,
    password: str,
    existing_users: list[dict],
) -> str:
    matched = find_user_by_email(existing_users, email)

    if matched:
        user_id = matched["id"]
        status, result = admin_request(
            url=url,
            service_role=service_role,
            method="PUT",
            path=f"/auth/v1/admin/users/{user_id}",
            payload={
                "password": password,
                "email_confirm": True,
            },
        )
        if status >= 400:
            raise RuntimeError(f"update user failed for {email}: {result}")
        return "updated"

    status, result = admin_request(
        url=url,
        service_role=service_role,
        method="POST",
        path="/auth/v1/admin/users",
        payload={
            "email": email,
            "password": password,
            "email_confirm": True,
        },
    )
    if status >= 400:
        raise RuntimeError(f"create user failed for {email}: {result}")

    user_id = result.get("id")
    if not user_id:
        raise RuntimeError(f"create user missing id for {email}: {result}")

    status, result = admin_request(
        url=url,
        service_role=service_role,
        method="PUT",
        path=f"/auth/v1/admin/users/{user_id}",
        payload={
            "password": password,
            "email_confirm": True,
        },
    )
    if status >= 400:
        raise RuntimeError(f"password sync failed for {email}: {result}")
    return "created"


def main() -> int:
    load_dotenv(ROOT / ".env")
    url = os.environ.get("SUPABASE_URL")
    service_role = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not service_role:
        print("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required in .env", file=sys.stderr)
        return 1

    users = discover_users()
    if not users:
        print("No SUPABASE_TEST_USER_*_EMAIL entries found in .env", file=sys.stderr)
        return 1

    existing_users = list_all_users(url, service_role)

    for role, email, password in users:
        action = upsert_user(url, service_role, email, password, existing_users)
        print(f"{role}: {action} {email}")
        if action == "created":
            existing_users = list_all_users(url, service_role)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
