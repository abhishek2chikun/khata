"""seller ledger tables

Revision ID: 0003_ledger
Revises: 0002_master
Create Date: 2026-04-19 00:20:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0003_ledger"
down_revision: str | None = "0002_master"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.create_check_constraint(
        "ck_stock_movements_shape",
        "stock_movements",
        "(movement_type = 'OPENING' AND invoice_id IS NULL AND request_id IS NULL AND request_hash IS NOT NULL) OR "
        "(movement_type = 'MANUAL_ADJUSTMENT' AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(movement_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )
    op.create_table(
        "seller_transactions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("seller_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("sellers.id"), nullable=False),
        sa.Column("invoice_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("request_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("request_hash", sa.String(length=255), nullable=True),
        sa.Column("entry_type", sa.String(length=64), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("occurred_on", sa.Date(), nullable=False),
        sa.Column("notes", sa.String(length=500), nullable=True),
        sa.Column("created_by_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("app_users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("amount > 0", name="ck_seller_transactions_amount_positive"),
        sa.CheckConstraint(
            "(entry_type IN ('OPENING_BALANCE','PAYMENT','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
            "(entry_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
            name="ck_seller_transactions_shape",
        ),
        sa.UniqueConstraint("request_id", name="uq_seller_transactions_request_id"),
    )
    op.create_index("uq_seller_transactions_opening_balance", "seller_transactions", ["seller_id"], unique=True, postgresql_where=sa.text("entry_type = 'OPENING_BALANCE'"))


def downgrade() -> None:
    op.drop_index("uq_seller_transactions_opening_balance", table_name="seller_transactions")
    op.drop_table("seller_transactions")
    op.drop_constraint("ck_stock_movements_shape", "stock_movements", type_="check")
