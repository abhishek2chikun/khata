#!/usr/bin/env python3
"""Build the bundled preinstalled product catalog JSON from the source spreadsheet."""

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
SOURCE_XLSX = REPO_ROOT / "data" / "source" / "products.xlsx"
OUTPUT_JSON = REPO_ROOT / "mobile" / "assets" / "catalog" / "preinstalled_catalog.json"
CATALOG_VERSION = 2
CATALOG_NAMESPACE = uuid.UUID("8f4e2c1a-9b3d-4f6e-a7c5-1d2e3f4a5b6c")

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
    return normalize_decimal(text, scale=2)


def normalize_unit(value: str) -> str | None:
    text = value.strip()
    if not text:
        return None
    if text in {"1", "1.0", "1.00"}:
        return "pcs"
    return text


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
        parsed_rows: list[dict[str, str]] = []
        for row in sheet.findall(".//m:sheetData/m:row", namespace)[1:]:
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
            while len(values) < len(HEADERS):
                values.append("")
            record = dict(zip(HEADERS, values[: len(HEADERS)], strict=False))
            company = record["company"].strip()
            item_name = record["item_name"].strip()
            if not company or not item_name:
                continue
            if company.startswith("Total Unique Products"):
                continue
            parsed_rows.append(record)
        return parsed_rows


def build_catalog(rows: list[dict[str, str]]) -> dict[str, object]:
    buyers = sorted({row["company"].strip() for row in rows})
    buyer_records = [
        {
            "id": str(uuid.uuid5(CATALOG_NAMESPACE, f"buyer:{name}")),
            "name": name,
            "address": "",
        }
        for name in buyers
    ]

    grouped: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        grouped.setdefault(row["company"].strip(), []).append(row)

    products: list[dict[str, str | None]] = []
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
                    "hsn_code": normalize_hsn(row["hsn_code"]),
                    "buying_price": normalize_decimal(row["buying_price"], scale=3, default="0"),
                    "selling_price": normalize_decimal(row["selling_price"], scale=3, default="0"),
                    "unit": normalize_unit(row["unit"]),
                    "gst_rate": normalize_gst_rate(row["gst_rate"]),
                    "quantity_on_hand": normalize_decimal(
                        row["quantity_on_hand"], scale=0, default="0"
                    ),
                    "low_stock_threshold": "0",
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


def main() -> None:
    if not SOURCE_XLSX.exists():
        raise SystemExit(f"Source spreadsheet not found: {SOURCE_XLSX}")

    rows = read_rows(SOURCE_XLSX)
    catalog = build_catalog(rows)
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    print(
        f"Wrote {OUTPUT_JSON} "
        f"({len(catalog['buyers'])} buyers, {len(catalog['products'])} products)"
    )


if __name__ == "__main__":
    main()
