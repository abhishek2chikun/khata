#!/usr/bin/env python3
"""Seed Supabase buyers/products from master_catalog.json via seed_master_catalog RPC."""

from __future__ import annotations

import argparse
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


def rpc_seed(
    url: str,
    anon_key: str,
    access_token: str,
    catalog: dict,
    *,
    allow_stock_reset: bool,
) -> dict:
    payload = json.dumps(
        {
            "p_catalog": catalog,
            "p_allow_stock_reset": allow_stock_reset,
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


def active_product_count(database_url: str) -> int:
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", "SELECT count(*) FROM products WHERE is_active = true;"],
        check=True,
        capture_output=True,
        text=True,
    )
    return int(result.stdout.strip())


def latest_catalog_version(database_url: str) -> int:
    result = subprocess.run(
        [
            "psql",
            database_url,
            "-t",
            "-A",
            "-c",
            "SELECT COALESCE(MAX(catalog_version), 0) FROM catalog_seed_runs;",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return int(result.stdout.strip())


def _parse_psql_count(output: str) -> int:
    text = output.strip()
    if text.startswith("DELETE ") or text.startswith("UPDATE "):
        return int(text.split()[1])
    return int(text or "0")


def stage_catalog_identities_for_reseed(database_url: str, catalog: dict) -> int:
    """Temporarily rename existing catalog rows so canonical names can upsert cleanly."""
    catalog_ids = [product["id"] for product in catalog["products"]]
    if not catalog_ids:
        return 0
    quoted_ids = ", ".join(f"'{product_id}'" for product_id in catalog_ids)
    sql = (
        "UPDATE products "
        "SET item_name = id::text || '::__catalog_tmp__', updated_at = NOW() "
        f"WHERE id IN ({quoted_ids});"
    )
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", sql],
        check=True,
        capture_output=True,
        text=True,
    )
    return _parse_psql_count(result.stdout)


def delete_unreferenced_products(database_url: str) -> int:
    sql = (
        "DELETE FROM products p "
        "WHERE NOT EXISTS ("
        "SELECT 1 FROM invoice_items ii WHERE ii.product_id = p.id"
        ");"
    )
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", sql],
        check=True,
        capture_output=True,
        text=True,
    )
    return _parse_psql_count(result.stdout)


def delete_unreferenced_catalog_orphans(database_url: str, catalog: dict) -> int:
    catalog_ids = [product["id"] for product in catalog["products"]]
    if not catalog_ids:
        return 0
    quoted_ids = ", ".join(f"'{product_id}'" for product_id in catalog_ids)
    sql = (
        "DELETE FROM products p "
        f"WHERE p.id NOT IN ({quoted_ids}) "
        "AND NOT EXISTS ("
        "SELECT 1 FROM invoice_items ii WHERE ii.product_id = p.id"
        ");"
    )
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", sql],
        check=True,
        capture_output=True,
        text=True,
    )
    return _parse_psql_count(result.stdout)


def deactivate_catalog_orphans(database_url: str, catalog: dict) -> int:
    catalog_ids = [product["id"] for product in catalog["products"]]
    if not catalog_ids:
        return 0
    quoted_ids = ", ".join(f"'{product_id}'" for product_id in catalog_ids)
    sql = (
        "UPDATE products "
        "SET is_active = false, updated_at = NOW() "
        f"WHERE is_active = true AND id NOT IN ({quoted_ids});"
    )
    result = subprocess.run(
        ["psql", database_url, "-t", "-A", "-c", sql],
        check=True,
        capture_output=True,
        text=True,
    )
    return _parse_psql_count(result.stdout)


def reset_catalog_seed_history(database_url: str) -> None:
    subprocess.run(
        ["psql", database_url, "-c", "DELETE FROM catalog_seed_runs;"],
        check=True,
        capture_output=True,
        text=True,
    )


def ensure_catalog_json() -> dict:
    subprocess.run([sys.executable, str(BUILD_SCRIPT)], check=True, cwd=REPO_ROOT)
    catalog = json.loads(CATALOG_JSON.read_text(encoding="utf-8"))
    expected_buyers = len(catalog.get("buyers", []))
    expected_products = len(catalog.get("products", []))
    if expected_buyers == 0 or expected_products == 0:
        raise RuntimeError("master_catalog.json is empty; check data/source/MASTER CATALOG.xlsx")
    return catalog


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Force catalog reseed with stock reset from master_catalog.json",
    )
    args = parser.parse_args()

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
    catalog_version = int(catalog["catalog_version"])

    buyers_before, products_before, _ = table_counts(database_url)
    active_before = active_product_count(database_url)
    seeded_version = latest_catalog_version(database_url)
    print(
        f"before: buyers={buyers_before} products={products_before} "
        f"active_products={active_before} catalog_seed_version={seeded_version}"
    )

    if (
        not args.reset
        and seeded_version >= catalog_version
        and active_before == expected_products
    ):
        print(
            "catalog already present in Supabase "
            f"(version>={catalog_version}, active_products={expected_products}); skipping seed"
        )
        return 0

    token = auth_token(url, anon_key, email, password)
    if args.reset:
        reset_catalog_seed_history(database_url)
        print(f"cleared catalog_seed_runs for forced reseed to v{catalog_version}")
        seeded_version = 0

    if seeded_version < catalog_version:
        staged = stage_catalog_identities_for_reseed(database_url, catalog)
        if staged:
            print(f"staged {staged} existing catalog product names for reseed")
        removed = delete_unreferenced_products(database_url)
        if removed:
            print(
                f"removed {removed} unreferenced products before catalog v{catalog_version} seed"
            )
    else:
        removed = delete_unreferenced_catalog_orphans(database_url, catalog)
        if removed:
            print(f"removed {removed} unreferenced products outside catalog v{catalog_version}")

    result = rpc_seed(
        url,
        anon_key,
        token,
        catalog,
        allow_stock_reset=args.reset or seeded_version < catalog_version,
    )
    print("seed result:", json.dumps(result, sort_keys=True))

    deactivated = deactivate_catalog_orphans(database_url, catalog)
    if deactivated:
        print(f"deactivated {deactivated} products not in catalog v{catalog_version}")

    buyers_after, products_after, runs_after = table_counts(database_url)
    active_after = active_product_count(database_url)
    print(
        f"after: buyers={buyers_after} products={products_after} "
        f"active_products={active_after} seed_runs={runs_after}"
    )

    if buyers_after < expected_buyers or active_after != expected_products:
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
