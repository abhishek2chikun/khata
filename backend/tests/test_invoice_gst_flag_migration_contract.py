from pathlib import Path

import pytest

pytestmark = pytest.mark.no_db

MIGRATION_PATH = (
    Path(__file__).resolve().parents[1]
    / "alembic"
    / "versions"
    / "0009_invoice_gst_flags.py"
)

FORBIDDEN_FINANCIAL_MUTATIONS = (
    "UPDATE invoice_items",
    "UPDATE customer_transactions",
    "UPDATE stock_movements",
    "UPDATE buyer_transactions",
    "SET subtotal",
    "SET grand_total",
    "SET gst_total",
    "SET taxable_total",
    "SET discount_total",
    "SET request_hash",
    "SET invoice_date",
    "SET invoice_datetime",
)


def test_upgrade_adds_and_backfills_only_gst_flags():
    assert MIGRATION_PATH.exists(), "0009_invoice_gst_flags migration is missing"
    source = MIGRATION_PATH.read_text()

    assert 'revision: str = "0009_invoice_gst_flags"' in source
    assert 'down_revision: str | None = "0008_invoice_v2"' in source
    assert "company_profiles" in source
    assert "invoices" in source
    assert "gst_flag" in source

    company_backfill_parts = (
        "UPDATE company_profiles SET gst_flag =",
        "gstin IS NOT NULL AND TRIM(gstin) <> ''",
    )
    invoice_backfill_parts = (
        "UPDATE invoices SET gst_flag =",
        "company_gstin IS NOT NULL AND TRIM(company_gstin) <> ''",
        "gst_total <> 0",
    )
    for part in company_backfill_parts:
        assert part in source
    for part in invoice_backfill_parts:
        assert part in source

    upgrade_index = source.index("def upgrade")
    downgrade_index = source.index("def downgrade")
    upgrade_body = source[upgrade_index:downgrade_index]
    for forbidden in FORBIDDEN_FINANCIAL_MUTATIONS:
        assert forbidden not in upgrade_body, f"Migration must not mutate: {forbidden}"

    assert "op.drop_column(\"company_profiles\", \"gst_flag\")" in source
    assert "op.drop_column(\"invoices\", \"gst_flag\")" in source
