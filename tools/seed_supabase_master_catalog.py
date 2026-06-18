#!/usr/bin/env python3
"""Seed Supabase buyers/products from master_catalog.json via seed_master_catalog RPC."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_JSON = REPO_ROOT / "supabase" / "seed" / "master_catalog.json"
BUILD_SCRIPT = REPO_ROOT / "tools" / "build_preinstalled_catalog.py"


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ[key.strip()] = value.strip()


def auth_token(url: str, anon_key: str, email: str, password: str) -> str:
    payload = json.dumps({"email": email, "password": password}).encode()
    request = urllib.request.Request(
        f"{url.rstrip('/')}/auth/v1/token?grant_type=password",
        data=payload,
        method="POST",
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {anon_key}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        data = json.loads(response.read().decode("utf-8"))
    token = data.get("access_token")
    if not token:
        raise RuntimeError("login succeeded but access_token missing")
    return token


def rpc_seed(url: str, anon_key: str, access_token: str, catalog: dict) -> dict:
    payload = json.dumps(
        {
            "p_catalog": catalog,
            "p_allow_stock_reset": False,
        }
    ).encode()
    request = urllib.request.Request(
        f"{url.rstrip('/')}/rest/v1/rpc/seed_master_catalog",
        data=payload,
        method="POST",
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            body = response.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8")
        raise RuntimeError(f"seed_master_catalog failed HTTP {error.code}: {detail}") from error


def table_counts(database_url: str) -> tuple[int, int, int]:
    sql = (
        "SELECT "
        "(SELECT count(*) FROM buyers), "
        "(SELECT count(*) FROM products), "
        "(SELECT count(*) FROM catalog_seed_runs);"
    )
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", sql],
        check=True,
        capture_output=True,
        text=True,
    )
    buyers, products, runs = (int(part.strip()) for part in result.stdout.strip().split("|"))
    return buyers, products, runs


def ensure_catalog_json() -> dict:
    subprocess.run([sys.executable, str(BUILD_SCRIPT)], check=True, cwd=REPO_ROOT)
    catalog = json.loads(CATALOG_JSON.read_text(encoding="utf-8"))
    expected_buyers = len(catalog.get("buyers", []))
    expected_products = len(catalog.get("products", []))
    if expected_buyers == 0 or expected_products == 0:
        raise RuntimeError("master_catalog.json is empty; check data/source/MASTER CATALOG.xlsx")
    return catalog


def main() -> int:
    load_dotenv(REPO_ROOT / ".env")
    url = os.environ.get("SUPABASE_URL")
    anon_key = os.environ.get("SUPABASE_ANON_KEY")
    database_url = os.environ.get("DATABASE_URL")
    email = os.environ.get("SUPABASE_TEST_USER_FATHER_EMAIL")
    password = os.environ.get("SUPABASE_TEST_USER_FATHER_PASSWORD")

    missing = [
        name
        for name, value in [
            ("SUPABASE_URL", url),
            ("SUPABASE_ANON_KEY", anon_key),
            ("DATABASE_URL", database_url),
            ("SUPABASE_TEST_USER_FATHER_EMAIL", email),
            ("SUPABASE_TEST_USER_FATHER_PASSWORD", password),
        ]
        if not value
    ]
    if missing:
        print(f"Missing required .env keys: {', '.join(missing)}", file=sys.stderr)
        return 1

    catalog = ensure_catalog_json()
    expected_buyers = len(catalog["buyers"])
    expected_products = len(catalog["products"])

    buyers_before, products_before, _ = table_counts(database_url)
    print(f"before: buyers={buyers_before} products={products_before}")

    if buyers_before >= expected_buyers and products_before >= expected_products:
        print(
            "catalog already present in Supabase "
            f"(buyers>={expected_buyers}, products>={expected_products}); skipping seed"
        )
        return 0

    token = auth_token(url, anon_key, email, password)
    result = rpc_seed(url, anon_key, token, catalog)
    print("seed result:", json.dumps(result, sort_keys=True))

    buyers_after, products_after, runs_after = table_counts(database_url)
    print(f"after: buyers={buyers_after} products={products_after} seed_runs={runs_after}")

    if buyers_after < expected_buyers or products_after < expected_products:
        print(
            "seed incomplete: "
            f"expected buyers={expected_buyers} products={expected_products}",
            file=sys.stderr,
        )
        return 1

    print("master catalog seed complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
