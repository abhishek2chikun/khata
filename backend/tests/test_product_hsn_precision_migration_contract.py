from pathlib import Path

import pytest

pytestmark = pytest.mark.no_db

MIGRATION_PATH = (
    Path(__file__).resolve().parents[1]
    / "alembic"
    / "versions"
    / "0010_product_hsn_and_unit_price_precision.py"
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


def test_upgrade_adds_hsn_columns_and_expands_unit_price_precision():
    assert MIGRATION_PATH.exists(), "0010 migration is missing"
    source = MIGRATION_PATH.read_text()

    assert 'revision: str = "0010_product_hsn_and_unit_price_precision"' in source
    assert 'down_revision: str | None = "0009_invoice_gst_flags"' in source
    assert 'op.add_column("products", sa.Column("hsn_code"' in source
    assert 'op.add_column(\n        "invoice_items",\n        sa.Column("product_hsn_code"' in source

    for column in (
        "buying_price",
        "selling_price",
        "entered_unit_price",
        "unit_price_excl_tax",
        "unit_price_incl_tax",
    ):
        assert column in source

    upgrade_index = source.index("def upgrade")
    downgrade_index = source.index("def downgrade")
    upgrade_body = source[upgrade_index:downgrade_index]
    for forbidden in FORBIDDEN_FINANCIAL_MUTATIONS:
        assert forbidden not in upgrade_body, f"Migration must not mutate: {forbidden}"

    assert 'op.drop_column("invoice_items", "product_hsn_code")' in source
    assert 'op.drop_column("products", "hsn_code")' in source
