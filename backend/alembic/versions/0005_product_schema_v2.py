"""product schema v2

Revision ID: 0005_product_v2
Revises: 0004_invoice
Create Date: 2026-05-09 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0005_product_v2"
down_revision: str | None = "0004_invoice"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.drop_constraint("uq_products_company_category_item_name", "products", type_="unique")
    op.drop_constraint("uq_products_item_code", "products", type_="unique")

    op.alter_column("products", "item_code", new_column_name="item_number", existing_type=sa.String(length=255), existing_nullable=False)
    op.alter_column("products", "company", new_column_name="company_name", existing_type=sa.String(length=255), existing_nullable=False)
    op.add_column("products", sa.Column("buyer_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("products", sa.Column("buying_price", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("selling_price", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("unit", sa.String(length=50), nullable=True))
    op.add_column("products", sa.Column("gst_rate", sa.Numeric(5, 2), nullable=True))

    # Legacy selling prices were stored pre-tax. Product V2 stores inclusive defaults.
    op.execute(
        sa.text(
            """
            UPDATE products
            SET
                buying_price = buying_price_excl_tax,
                selling_price = ROUND(default_selling_price_excl_tax * (1 + (default_gst_rate / 100)), 2),
                gst_rate = default_gst_rate
            """
        )
    )

    op.alter_column("products", "buying_price", existing_type=sa.Numeric(14, 2), nullable=False)
    op.alter_column("products", "selling_price", existing_type=sa.Numeric(14, 2), nullable=False)
    op.alter_column("products", "gst_rate", existing_type=sa.Numeric(5, 2), nullable=False)

    op.drop_column("products", "buying_price_excl_tax")
    op.drop_column("products", "buying_gst_rate")
    op.drop_column("products", "default_selling_price_excl_tax")
    op.drop_column("products", "default_gst_rate")

    op.create_unique_constraint("uq_products_item_number", "products", ["item_number"])
    op.create_unique_constraint("uq_products_company_name_item_name_category", "products", ["company_name", "item_name", "category"])


def downgrade() -> None:
    op.drop_constraint("uq_products_company_name_item_name_category", "products", type_="unique")
    op.drop_constraint("uq_products_item_number", "products", type_="unique")

    op.add_column("products", sa.Column("default_gst_rate", sa.Numeric(5, 2), nullable=True))
    op.add_column("products", sa.Column("default_selling_price_excl_tax", sa.Numeric(14, 2), nullable=True))
    op.add_column("products", sa.Column("buying_gst_rate", sa.Numeric(5, 2), nullable=True))
    op.add_column("products", sa.Column("buying_price_excl_tax", sa.Numeric(14, 2), nullable=True))

    op.execute(
        sa.text(
            """
            UPDATE products
            SET
                buying_price_excl_tax = buying_price,
                buying_gst_rate = NULL,
                default_selling_price_excl_tax = ROUND(selling_price / (1 + (gst_rate / 100)), 2),
                default_gst_rate = gst_rate
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
