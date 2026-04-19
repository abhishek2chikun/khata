"""master data and stock tables

Revision ID: 0002_master
Revises: 0001_auth
Create Date: 2026-04-19 00:10:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0002_master"
down_revision: str | None = "0001_auth"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "products",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("company", sa.String(length=255), nullable=False),
        sa.Column("category", sa.String(length=255), nullable=False),
        sa.Column("item_name", sa.String(length=255), nullable=False),
        sa.Column("item_code", sa.String(length=255), nullable=False),
        sa.Column("buying_price_excl_tax", sa.Numeric(14, 2), nullable=True),
        sa.Column("buying_gst_rate", sa.Numeric(5, 2), nullable=True),
        sa.Column("default_selling_price_excl_tax", sa.Numeric(14, 2), nullable=False),
        sa.Column("default_gst_rate", sa.Numeric(5, 2), nullable=False),
        sa.Column("quantity_on_hand", sa.Numeric(14, 3), nullable=False),
        sa.Column("low_stock_threshold", sa.Numeric(14, 3), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("item_code", name="uq_products_item_code"),
        sa.UniqueConstraint("company", "category", "item_name", name="uq_products_company_category_item_name"),
    )

    op.create_table(
        "sellers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("state", sa.String(length=255), nullable=True),
        sa.Column("state_code", sa.String(length=50), nullable=True),
        sa.Column("phone", sa.String(length=50), nullable=True),
        sa.Column("gstin", sa.String(length=50), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("name", "phone", name="uq_sellers_name_phone"),
    )

    op.create_table(
        "company_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("city", sa.String(length=255), nullable=False),
        sa.Column("state", sa.String(length=255), nullable=False),
        sa.Column("state_code", sa.String(length=50), nullable=False),
        sa.Column("gstin", sa.String(length=50), nullable=True),
        sa.Column("phone", sa.String(length=50), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("bank_name", sa.String(length=255), nullable=True),
        sa.Column("bank_account", sa.String(length=255), nullable=True),
        sa.Column("bank_ifsc", sa.String(length=100), nullable=True),
        sa.Column("bank_branch", sa.String(length=255), nullable=True),
        sa.Column("jurisdiction", sa.String(length=255), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("uq_company_profiles_single_active", "company_profiles", ["is_active"], unique=True, postgresql_where=sa.text("is_active = true"))

    op.create_table(
        "stock_movements",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("invoice_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("request_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("request_hash", sa.String(length=255), nullable=True),
        sa.Column("movement_type", sa.String(length=50), nullable=False),
        sa.Column("quantity_delta", sa.Numeric(14, 3), nullable=False),
        sa.Column("reason", sa.String(length=500), nullable=True),
        sa.Column("created_by_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("app_users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("quantity_delta <> 0", name="ck_stock_movements_quantity_non_zero"),
        sa.UniqueConstraint("request_id", name="uq_stock_movements_request_id"),
    )


def downgrade() -> None:
    op.drop_table("stock_movements")
    op.drop_index("uq_company_profiles_single_active", table_name="company_profiles")
    op.drop_table("company_profiles")
    op.drop_table("sellers")
    op.drop_table("products")
