"""add buyers

Revision ID: 0006_add_buyers
Revises: 0005_product_v2
Create Date: 2026-05-09 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0006_add_buyers"
down_revision: str | None = "0005_product_v2"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "buyers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("state", sa.String(length=255), nullable=True),
        sa.Column("state_code", sa.String(length=50), nullable=True),
        sa.Column("phone", sa.String(length=50), nullable=True),
        sa.Column("gstin", sa.String(length=50), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("name", name="uq_buyers_name"),
    )
    op.create_table(
        "buyer_transactions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("buyer_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("buyers.id"), nullable=False),
        sa.Column("request_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("request_hash", sa.String(length=255), nullable=True),
        sa.Column("entry_type", sa.String(length=64), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.String(length=500), nullable=True),
        sa.Column("created_by_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("app_users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("amount > 0", name="ck_buyer_transactions_amount_positive"),
        sa.CheckConstraint(
            "entry_type IN ('OPENING_PAYABLE','PURCHASE_AMOUNT','PAYMENT_MADE','PAYABLE_INCREASE_ADJUSTMENT','PAYABLE_DECREASE_ADJUSTMENT') "
            "AND request_id IS NOT NULL AND request_hash IS NOT NULL",
            name="ck_buyer_transactions_shape",
        ),
        sa.UniqueConstraint("request_id", name="uq_buyer_transactions_request_id"),
    )
    op.create_index("uq_buyer_transactions_opening_payable", "buyer_transactions", ["buyer_id"], unique=True, postgresql_where=sa.text("entry_type = 'OPENING_PAYABLE'"))


def downgrade() -> None:
    op.drop_index("uq_buyer_transactions_opening_payable", table_name="buyer_transactions")
    op.drop_table("buyer_transactions")
    op.drop_table("buyers")
