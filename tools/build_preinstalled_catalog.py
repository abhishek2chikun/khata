#!/usr/bin/env python3
"""Build bundled Drift catalog JSON and Supabase seed JSON from the master workbook."""

from __future__ import annotations

import json
import re
import uuid
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter
from datetime import UTC, datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_XLSX = REPO_ROOT / "data" / "source" / "MASTER CATALOG.xlsx"
OUTPUT_JSON = REPO_ROOT / "mobile" / "assets" / "catalog" / "preinstalled_catalog.json"
SUPABASE_SEED_JSON = REPO_ROOT / "supabase" / "seed" / "master_catalog.json"
CATALOG_VERSION = 4
CATALOG_NAMESPACE = uuid.UUID("8f4e2c1a-9b3d-4f6e-a7c5-1d2e3f4a5b6c")

HEADER_ALIASES = {
    "company": "company",
    "category": "category",
    "item name": "item_name",
    "item_name": "item_name",
    "hsn code": "hsn_code",
    "hsn_code": "hsn_code",
    "buying price": "buying_price",
    "buying_price": "buying_price",
    "selling price (dp)": "selling_price",
    "selling price": "selling_price",
    "selling_price": "selling_price",
    "unit": "unit",
    "gst rate": "gst_rate",
    "gst_rate": "gst_rate",
    "quantity on hand": "quantity_on_hand",
    "quantity_on_hand": "quantity_on_hand",
}

HEADERS = [
    "company",
    "category",
    "item_name",
    "hsn_code",
    "buying_price",
    "selling_price",
    "unit",
    "gst_rate",
    "quantity_on_hand",
]


def company_slug(name: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", name)
    if not words:
        return "COMPANY"
    slug = re.sub(r"[^A-Za-z0-9]", "", words[0]).upper()
    return slug or "COMPANY"


def normalize_hsn(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if len(normalized) > 32:
        raise ValueError("hsn_code must be at most 32 characters")
    return normalized


def normalize_decimal(value: str, *, scale: int = 2, default: str = "") -> str:
    text = value.strip()
    if not text:
        if default:
            return default
        raise ValueError("missing decimal value")
    number = Decimal(text)
    quantizer = Decimal("1") if scale == 0 else Decimal("1." + ("0" * (scale - 1)) + "1")
    normalized = number.quantize(quantizer, rounding=ROUND_HALF_UP)
    rendered = format(normalized, "f")
    if "." in rendered:
        rendered = rendered.rstrip("0").rstrip(".")
    return rendered or "0"


def normalize_gst_rate(value: str) -> str:
    text = value.strip().rstrip("%")
    if not text:
        raise ValueError("missing gst rate")
    rate = Decimal(text)
    if rate <= 1:
        rate = rate * 100
    return normalize_decimal(str(rate), scale=2)


def normalize_unit(value: str) -> str | None:
    text = value.strip()
    if not text:
        return None
    if text in {"1", "1.0", "1.00"}:
        return "pcs"
    return text


def _normalize_header(value: str) -> str | None:
    return HEADER_ALIASES.get(value.strip().casefold())


def read_rows(path: Path) -> list[dict[str, str]]:
    with zipfile.ZipFile(path) as workbook:
        shared_strings: list[str] = []
        if "xl/sharedStrings.xml" in workbook.namelist():
            root = ET.fromstring(workbook.read("xl/sharedStrings.xml"))
            namespace = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
            for item in root.findall(".//m:si", namespace):
                parts = [part.text or "" for part in item.findall(".//m:t", namespace)]
                shared_strings.append("".join(parts))

        sheet = ET.fromstring(workbook.read("xl/worksheets/sheet1.xml"))
        namespace = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
        all_rows = sheet.findall(".//m:sheetData/m:row", namespace)
        if not all_rows:
            return []

        header_values: list[str] = []
        for cell in all_rows[0].findall("m:c", namespace):
            cell_type = cell.get("t")
            raw_value = cell.find("m:v", namespace)
            if raw_value is None or raw_value.text is None:
                header_values.append("")
            elif cell_type == "s":
                header_values.append(shared_strings[int(raw_value.text)])
            else:
                header_values.append(raw_value.text)

        header_map: dict[int, str] = {}
        for index, header in enumerate(header_values):
            normalized = _normalize_header(header)
            if normalized is not None:
                header_map[index] = normalized

        parsed_rows: list[dict[str, str]] = []
        for row in all_rows[1:]:
            values: list[str] = []
            for cell in row.findall("m:c", namespace):
                cell_type = cell.get("t")
                raw_value = cell.find("m:v", namespace)
                if raw_value is None or raw_value.text is None:
                    values.append("")
                elif cell_type == "s":
                    values.append(shared_strings[int(raw_value.text)])
                else:
                    values.append(raw_value.text)
            if not values:
                continue

            record = {field: "" for field in HEADERS}
            for index, field in header_map.items():
                if index < len(values):
                    record[field] = values[index]

            company = record["company"].strip()
            item_name = record["item_name"].strip()
            if not company or not item_name:
                continue
            if company.startswith("Total Unique Products"):
                continue
            parsed_rows.append(record)
        return parsed_rows


def canonicalize_company_names(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    counts = Counter(row["company"].strip() for row in rows)
    preferred: dict[str, str] = {}
    for company, count in counts.items():
        key = company.casefold()
        if key not in preferred or count > counts[preferred[key]]:
            preferred[key] = company
    return [
        {**row, "company": preferred[row["company"].strip().casefold()]}
        for row in rows
    ]


def dedupe_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    """Keep one row per (company, item_name, category); sum quantity on duplicates."""
    merged: dict[tuple[str, str, str], dict[str, str]] = {}
    for row in rows:
        key = (row["company"].strip(), row["item_name"].strip(), row["category"].strip())
        if key not in merged:
            merged[key] = dict(row)
            continue
        existing_qty = Decimal(merged[key]["quantity_on_hand"] or "0")
        incoming_qty = Decimal(row["quantity_on_hand"] or "0")
        merged[key]["quantity_on_hand"] = str(existing_qty + incoming_qty)
    return list(merged.values())


def build_catalog(rows: list[dict[str, str]]) -> dict[str, object]:
    buyers = sorted({row["company"].strip() for row in rows})
    buyer_id_by_name = {
        name: str(uuid.uuid5(CATALOG_NAMESPACE, f"buyer:{name}")) for name in buyers
    }
    buyer_records = [
        {
            "id": buyer_id_by_name[name],
            "name": name,
            "address": "",
            "is_active": True,
        }
        for name in buyers
    ]

    grouped: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        grouped.setdefault(row["company"].strip(), []).append(row)

    products: list[dict[str, str | None | bool]] = []
    for company in sorted(grouped):
        slug = company_slug(company)
        company_rows = sorted(
            grouped[company],
            key=lambda row: (row["category"].strip(), row["item_name"].strip()),
        )
        for index, row in enumerate(company_rows, start=1):
            item_number = f"{slug}-{index:04d}"
            products.append(
                {
                    "id": str(uuid.uuid5(CATALOG_NAMESPACE, f"product:{item_number}")),
                    "item_number": item_number,
                    "item_name": row["item_name"].strip(),
                    "category": row["category"].strip(),
                    "company_name": company,
                    "buyer_id": buyer_id_by_name[company],
                    "hsn_code": normalize_hsn(row["hsn_code"]),
                    "buying_price": normalize_decimal(row["buying_price"], scale=3, default="0"),
                    "selling_price": normalize_decimal(row["selling_price"], scale=3, default="0"),
                    "unit": normalize_unit(row["unit"]),
                    "gst_rate": normalize_gst_rate(row["gst_rate"]),
                    "quantity_on_hand": normalize_decimal(
                        row["quantity_on_hand"], scale=0, default="0"
                    ),
                    "low_stock_threshold": "0",
                    "is_active": True,
                }
            )

    item_numbers = [product["item_number"] for product in products]
    if len(item_numbers) != len(set(item_numbers)):
        duplicates = [key for key, count in Counter(item_numbers).items() if count > 1]
        raise RuntimeError(f"duplicate item_number values: {duplicates[:5]}")

    identity_keys = [
        (product["company_name"], product["item_name"], product["category"])
        for product in products
    ]
    if len(identity_keys) != len(set(identity_keys)):
        raise RuntimeError("duplicate (company_name, item_name, category) tuples found")

    return {
        "catalog_version": CATALOG_VERSION,
        "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "buyers": buyer_records,
        "products": products,
    }


def write_outputs(catalog: dict[str, object]) -> None:
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    SUPABASE_SEED_JSON.parent.mkdir(parents=True, exist_ok=True)
    SUPABASE_SEED_JSON.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    if not SOURCE_XLSX.exists():
        raise SystemExit(f"Source spreadsheet not found: {SOURCE_XLSX}")

    rows = dedupe_rows(canonicalize_company_names(read_rows(SOURCE_XLSX)))
    catalog = build_catalog(rows)
    write_outputs(catalog)
    print(
        f"Wrote {OUTPUT_JSON} and {SUPABASE_SEED_JSON} "
        f"({len(catalog['buyers'])} buyers, {len(catalog['products'])} products)"
    )


if __name__ == "__main__":
    main()
