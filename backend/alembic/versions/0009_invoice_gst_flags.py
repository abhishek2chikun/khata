"""invoice gst flags

Revision ID: 0009_invoice_gst_flags
Revises: 0008_invoice_v2
Create Date: 2026-06-13 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "0009_invoice_gst_flags"
down_revision: str | None = "0008_invoice_v2"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("company_profiles", sa.Column("gst_flag", sa.Boolean(), nullable=True))
    op.execute(
        sa.text(
            "UPDATE company_profiles SET gst_flag = "
            "(gstin IS NOT NULL AND TRIM(gstin) <> '')"
        )
    )
    op.alter_column("company_profiles", "gst_flag", nullable=False)

    op.add_column("invoices", sa.Column("gst_flag", sa.Boolean(), nullable=True))
    op.execute(
        sa.text(
            "UPDATE invoices SET gst_flag = "
            "((company_gstin IS NOT NULL AND TRIM(company_gstin) <> '') OR gst_total <> 0)"
        )
    )
    op.alter_column("invoices", "gst_flag", nullable=False)


def downgrade() -> None:
    op.drop_column("invoices", "gst_flag")
    op.drop_column("company_profiles", "gst_flag")
