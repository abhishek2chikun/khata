"""Catalog generator parity tests."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
BUILD_SCRIPT = REPO_ROOT / "tools" / "build_preinstalled_catalog.py"
DRIFT_JSON = REPO_ROOT / "mobile" / "assets" / "catalog" / "preinstalled_catalog.json"
SUPABASE_JSON = REPO_ROOT / "supabase" / "seed" / "master_catalog.json"
SOURCE_XLSX = REPO_ROOT / "data" / "source" / "MASTER CATALOG.xlsx"


def test_source_workbook_tracked() -> None:
    assert SOURCE_XLSX.exists(), "MASTER CATALOG.xlsx must exist at data/source/"


def test_generator_produces_matching_outputs() -> None:
    subprocess.run([sys.executable, str(BUILD_SCRIPT)], check=True, cwd=REPO_ROOT)
    drift = json.loads(DRIFT_JSON.read_text(encoding="utf-8"))
    supabase = json.loads(SUPABASE_JSON.read_text(encoding="utf-8"))
    assert drift == supabase
    assert drift["catalog_version"] >= 4
    assert len(drift["products"]) > 0
    assert len(drift["buyers"]) > 0
    product_ids = {item["id"] for item in drift["products"]}
    buyer_ids = {item["id"] for item in drift["buyers"]}
    assert len(product_ids) == len(drift["products"])
    assert len(buyer_ids) == len(drift["buyers"])


if __name__ == "__main__":
    test_source_workbook_tracked()
    test_generator_produces_matching_outputs()
    print("catalog parity tests passed")
