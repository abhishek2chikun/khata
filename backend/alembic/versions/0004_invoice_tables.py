"""invoice tables

Revision ID: 0004_invoice
Revises: 0003_ledger
Create Date: 2026-04-19 01:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0004_invoice"
down_revision: str | None = "0003_ledger"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.execute(sa.text("CREATE SEQUENCE invoice_number_seq AS BIGINT START WITH 1 INCREMENT BY 1"))

    op.create_table(
        "invoices",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("request_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("request_hash", sa.String(length=255), nullable=False),
        sa.Column("invoice_number", sa.BigInteger(), server_default=sa.text("nextval('invoice_number_seq')"), nullable=False),
        sa.Column("seller_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("sellers.id"), nullable=False),
        sa.Column("seller_name", sa.Text(), nullable=False),
        sa.Column("seller_address", sa.Text(), nullable=False),
        sa.Column("seller_state", sa.Text(), nullable=True),
        sa.Column("seller_state_code", sa.String(length=50), nullable=True),
        sa.Column("seller_phone", sa.String(length=50), nullable=True),
        sa.Column("seller_gstin", sa.String(length=50), nullable=True),
        sa.Column("place_of_supply_state", sa.Text(), nullable=False),
        sa.Column("place_of_supply_state_code", sa.String(length=50), nullable=False),
        sa.Column("company_name", sa.Text(), nullable=False),
        sa.Column("company_address", sa.Text(), nullable=False),
        sa.Column("company_city", sa.Text(), nullable=False),
        sa.Column("company_state", sa.Text(), nullable=False),
        sa.Column("company_state_code", sa.String(length=50), nullable=False),
        sa.Column("company_gstin", sa.String(length=50), nullable=True),
        sa.Column("company_phone", sa.String(length=50), nullable=True),
        sa.Column("company_email", sa.String(length=255), nullable=True),
        sa.Column("company_bank_name", sa.Text(), nullable=True),
        sa.Column("company_bank_account", sa.String(length=255), nullable=True),
        sa.Column("company_bank_ifsc", sa.String(length=100), nullable=True),
        sa.Column("company_bank_branch", sa.Text(), nullable=True),
        sa.Column("company_jurisdiction", sa.Text(), nullable=True),
        sa.Column("invoice_date", sa.Date(), nullable=False),
        sa.Column("tax_regime", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("payment_mode", sa.String(length=32), nullable=False),
        sa.Column("subtotal", sa.Numeric(14, 2), nullable=False),
        sa.Column("discount_total", sa.Numeric(14, 2), nullable=False),
        sa.Column("taxable_total", sa.Numeric(14, 2), nullable=False),
        sa.Column("gst_total", sa.Numeric(14, 2), nullable=False),
        sa.Column("grand_total", sa.Numeric(14, 2), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("app_users.id"), nullable=False),
        sa.Column("cancel_request_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("cancel_request_hash", sa.String(length=255), nullable=True),
        sa.Column("canceled_by_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("app_users.id"), nullable=True),
        sa.Column("cancel_reason", sa.Text(), nullable=True),
        sa.Column("canceled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("tax_regime IN ('INTRA_STATE', 'INTER_STATE')", name="ck_invoices_tax_regime"),
        sa.CheckConstraint("status IN ('ACTIVE', 'CANCELED')", name="ck_invoices_status"),
        sa.CheckConstraint("payment_mode IN ('PAID', 'CREDIT')", name="ck_invoices_payment_mode"),
        sa.CheckConstraint(
            "(status = 'ACTIVE' AND cancel_request_id IS NULL AND cancel_request_hash IS NULL AND canceled_by_user_id IS NULL AND cancel_reason IS NULL AND canceled_at IS NULL) OR "
            "(status = 'CANCELED' AND cancel_request_id IS NOT NULL AND cancel_request_hash IS NOT NULL AND canceled_by_user_id IS NOT NULL AND cancel_reason IS NOT NULL AND canceled_at IS NOT NULL)",
            name="ck_invoices_cancel_fields",
        ),
        sa.UniqueConstraint("request_id", name="uq_invoices_request_id"),
        sa.UniqueConstraint("invoice_number", name="uq_invoices_invoice_number"),
        sa.UniqueConstraint("cancel_request_id", name="uq_invoices_cancel_request_id"),
    )
    op.execute(sa.text("ALTER SEQUENCE invoice_number_seq OWNED BY invoices.invoice_number"))

    op.create_table(
        "invoice_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("invoice_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("invoices.id"), nullable=False),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("line_number", sa.Integer(), nullable=False),
        sa.Column("product_name", sa.Text(), nullable=False),
        sa.Column("product_code", sa.String(length=255), nullable=False),
        sa.Column("company", sa.String(length=255), nullable=False),
        sa.Column("category", sa.String(length=255), nullable=False),
        sa.Column("quantity", sa.Numeric(14, 3), nullable=False),
        sa.Column("pricing_mode", sa.String(length=32), nullable=False),
        sa.Column("entered_unit_price", sa.Numeric(14, 2), nullable=False),
        sa.Column("unit_price_excl_tax", sa.Numeric(14, 2), nullable=False),
        sa.Column("unit_price_incl_tax", sa.Numeric(14, 2), nullable=False),
        sa.Column("gst_rate", sa.Numeric(5, 2), nullable=False),
        sa.Column("cgst_rate", sa.Numeric(5, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("sgst_rate", sa.Numeric(5, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("igst_rate", sa.Numeric(5, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("discount_percent", sa.Numeric(5, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("discount_amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("taxable_amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("gst_amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("cgst_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("sgst_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("igst_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")),
        sa.Column("line_total", sa.Numeric(14, 2), nullable=False),
        sa.CheckConstraint("pricing_mode IN ('PRE_TAX', 'TAX_INCLUSIVE')", name="ck_invoice_items_pricing_mode"),
        sa.CheckConstraint("cgst_rate + sgst_rate + igst_rate = gst_rate", name="ck_invoice_items_rate_sum"),
        sa.CheckConstraint("cgst_amount + sgst_amount + igst_amount = gst_amount", name="ck_invoice_items_amount_sum"),
        sa.UniqueConstraint("invoice_id", "line_number", name="uq_invoice_items_invoice_id_line_number"),
    )

    op.create_foreign_key("fk_seller_transactions_invoice_id_invoices", "seller_transactions", "invoices", ["invoice_id"], ["id"])
    op.create_foreign_key("fk_stock_movements_invoice_id_invoices", "stock_movements", "invoices", ["invoice_id"], ["id"])
    op.execute(sa.text("ALTER TABLE stock_movements DROP CONSTRAINT IF EXISTS ck_stock_movements_shape"))
    op.create_check_constraint(
        "ck_stock_movements_shape",
        "stock_movements",
        "(movement_type = 'OPENING' AND invoice_id IS NULL AND request_id IS NULL AND request_hash IS NOT NULL) OR "
        "(movement_type = 'MANUAL_ADJUSTMENT' AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(movement_type IN ('INVOICE_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )


def downgrade() -> None:
    op.execute(sa.text("ALTER TABLE stock_movements DROP CONSTRAINT IF EXISTS ck_stock_movements_shape"))
    op.create_check_constraint(
        "ck_stock_movements_shape",
        "stock_movements",
        "(movement_type = 'OPENING' AND invoice_id IS NULL AND request_id IS NULL AND request_hash IS NOT NULL) OR "
        "(movement_type = 'MANUAL_ADJUSTMENT' AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(movement_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )
    op.drop_constraint("fk_stock_movements_invoice_id_invoices", "stock_movements", type_="foreignkey")
    op.drop_constraint("fk_seller_transactions_invoice_id_invoices", "seller_transactions", type_="foreignkey")
    op.drop_table("invoice_items")
    op.drop_table("invoices")
