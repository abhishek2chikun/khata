"""product hsn and price precision

Revision ID: 0010_product_hsn_and_unit_price_precision
Revises: 0009_invoice_gst_flags
Create Date: 2026-06-14 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "0010_product_hsn_and_unit_price_precision"
down_revision: str | None = "0009_invoice_gst_flags"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("products", sa.Column("hsn_code", sa.String(length=32), nullable=True))

    op.add_column(
        "invoice_items",
        sa.Column("product_hsn_code", sa.String(length=32), nullable=True),
    )

    for table, columns in (
        ("products", ("buying_price", "selling_price")),
        (
            "invoice_items",
            (
                "buying_price",
                "selling_price",
                "entered_unit_price",
                "unit_price_excl_tax",
                "unit_price_incl_tax",
            ),
        ),
    ):
        for column in columns:
            op.alter_column(
                table,
                column,
                existing_type=sa.Numeric(14, 2),
                type_=sa.Numeric(14, 3),
                existing_nullable=False,
            )


def downgrade() -> None:
    for table, columns in (
        ("products", ("buying_price", "selling_price")),
        (
            "invoice_items",
            (
                "buying_price",
                "selling_price",
                "entered_unit_price",
                "unit_price_excl_tax",
                "unit_price_incl_tax",
            ),
        ),
    ):
        for column in columns:
            op.alter_column(
                table,
                column,
                existing_type=sa.Numeric(14, 3),
                type_=sa.Numeric(14, 2),
                existing_nullable=False,
            )

    op.drop_column("invoice_items", "product_hsn_code")
    op.drop_column("products", "hsn_code")
