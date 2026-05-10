"""product schema v2

Revision ID: 0005_product_v2
Revises: 0004_invoice
Create Date: 2026-05-09 00:00:00
"""

from collections.abc import Sequence
from decimal import Decimal, ROUND_HALF_UP

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0005_product_v2"
down_revision: str | None = "0004_invoice"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None

MONEY_QUANT = Decimal("0.01")


def to_inclusive_money(value: Decimal | None, gst_rate: Decimal | None) -> Decimal:
    """Convert legacy pre-tax money to V2 inclusive money with safe fallback."""
    if value is None:
        return Decimal("0.00")
    tax_rate = Decimal("0.00") if gst_rate is None else Decimal(gst_rate)
    return (Decimal(value) * (Decimal("1.00") + (tax_rate / Decimal("100.00")))).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)


def to_pre_tax_money(value: Decimal | None, gst_rate: Decimal | None) -> Decimal:
    """Convert V2 inclusive money back to legacy pre-tax money with safe fallback."""
    if value is None:
        return Decimal("0.00")
    tax_rate = Decimal("0.00") if gst_rate is None else Decimal(gst_rate)
    if tax_rate == 0:
        return Decimal(value).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)
    return (Decimal(value) / (Decimal("1.00") + (tax_rate / Decimal("100.00")))).quantize(MONEY_QUANT, rounding=ROUND_HALF_UP)


def upgrade() -> None:
    op.drop_constraint("uq_products_company_category_item_name", "products", type_="unique")
    op.drop_constraint("uq_products_item_code", "products", type_="unique")

    op.alter_column("products", "item_code", new_column_name="item_number", existing_type=sa.String(length=255), existing_nullable=False)
    op.alter_column("products", "company", new_column_name="company_name", existing_type=sa.String(length=255), existing_nullable=False)
    # buyer_id remains nullable until the Buyer task introduces buyers and backfills
    # by matching products.company_name to buyers.name.
    op.add_column("products", sa.Column("buyer_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("products", sa.Column("buying_price", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("selling_price", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("unit", sa.String(length=50), nullable=True))
    op.add_column("products", sa.Column("gst_rate", sa.Numeric(5, 2), nullable=True))

    # Legacy product prices were stored pre-tax. Product V2 stores inclusive defaults.
    # Null legacy buying prices fall back to 0.00 so buying_price can be made NOT NULL;
    # null GST rates are treated as 0.00, preserving the legacy numeric value.
    op.execute(
        sa.text(
            """
            UPDATE products
            SET
                buying_price = ROUND(COALESCE(buying_price_excl_tax, 0.00) * (1 + (COALESCE(buying_gst_rate, 0.00) / 100)), 2),
                selling_price = ROUND(COALESCE(default_selling_price_excl_tax, 0.00) * (1 + (COALESCE(default_gst_rate, 0.00) / 100)), 2),
                gst_rate = COALESCE(default_gst_rate, 0.00)
            """
        )
    )

    op.alter_column("products", "buying_price", existing_type=sa.Numeric(14, 2), nullable=False)
    op.alter_column("products", "selling_price", existing_type=sa.Numeric(14, 2), nullable=False)
    op.alter_column("products", "gst_rate", existing_type=sa.Numeric(5, 2), nullable=False)

    op.drop_column("products", "buying_price_excl_tax")
    op.drop_column("products", "default_selling_price_excl_tax")
    op.drop_column("products", "default_gst_rate")
    op.drop_column("products", "buying_gst_rate")

    op.create_unique_constraint("uq_products_item_number", "products", ["item_number"])
    op.create_unique_constraint("uq_products_company_name_item_name_category", "products", ["company_name", "item_name", "category"])


def downgrade() -> None:
    op.drop_constraint("uq_products_company_name_item_name_category", "products", type_="unique")
    op.drop_constraint("uq_products_item_number", "products", type_="unique")

    op.add_column("products", sa.Column("default_gst_rate", sa.Numeric(5, 2), nullable=True))
    op.add_column("products", sa.Column("default_selling_price_excl_tax", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("buying_price_excl_tax", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("buying_gst_rate", sa.Numeric(5, 2), nullable=True))

    # Downgrade is lossy when legacy buying_gst_rate differed from default_gst_rate;
    # V2 intentionally keeps only canonical gst_rate.
    op.execute(
        sa.text(
            """
            UPDATE products
            SET
                buying_price_excl_tax = CASE
                    WHEN COALESCE(gst_rate, 0.00) = 0.00 THEN COALESCE(buying_price, 0.00)
                    ELSE ROUND(COALESCE(buying_price, 0.00) / (1 + (gst_rate / 100)), 2)
                END,
                default_selling_price_excl_tax = CASE
                    WHEN COALESCE(gst_rate, 0.00) = 0.00 THEN COALESCE(selling_price, 0.00)
                    ELSE ROUND(COALESCE(selling_price, 0.00) / (1 + (gst_rate / 100)), 2)
                END,
                default_gst_rate = gst_rate,
                buying_gst_rate = gst_rate
            """
        )
    )

    op.alter_column("products", "default_gst_rate", existing_type=sa.Numeric(5, 2), nullable=False)
    op.alter_column("products", "default_selling_price_excl_tax", existing_type=sa.Numeric(14, 2), nullable=False)

    op.drop_column("products", "gst_rate")
    op.drop_column("products", "unit")
    op.drop_column("products", "selling_price")
    op.drop_column("products", "buying_price")
    op.drop_column("products", "buyer_id")
    op.alter_column("products", "company_name", new_column_name="company", existing_type=sa.String(length=255), existing_nullable=False)
    op.alter_column("products", "item_number", new_column_name="item_code", existing_type=sa.String(length=255), existing_nullable=False)

    op.create_unique_constraint("uq_products_item_code", "products", ["item_code"])
    op.create_unique_constraint("uq_products_company_category_item_name", "products", ["company", "category", "item_name"])
