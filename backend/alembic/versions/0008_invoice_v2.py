"""invoice v2 domain

Revision ID: 0008_invoice_v2
Revises: 0007_customers
Create Date: 2026-05-10 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0008_invoice_v2"
down_revision: str | None = "0007_customers"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("invoices", sa.Column("invoice_datetime", sa.DateTime(timezone=True), nullable=True))
    op.execute(sa.text("UPDATE invoices SET invoice_datetime = invoice_date::timestamp AT TIME ZONE 'UTC' WHERE invoice_datetime IS NULL"))
    op.alter_column("invoices", "invoice_datetime", nullable=False)
    op.add_column("invoices", sa.Column("payment_state", sa.String(length=32), nullable=True))
    op.execute(sa.text("UPDATE invoices SET payment_state = CASE WHEN payment_mode = 'PAID' THEN 'TOTAL_PAID' ELSE 'CREDIT' END WHERE payment_state IS NULL"))
    op.alter_column("invoices", "payment_state", nullable=False)
    op.add_column("invoices", sa.Column("paid_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.execute(sa.text("UPDATE invoices SET paid_amount = CASE WHEN payment_state = 'TOTAL_PAID' THEN grand_total ELSE 0 END"))
    op.drop_constraint("ck_invoices_payment_mode", "invoices", type_="check")
    op.drop_column("invoices", "payment_mode")
    op.create_check_constraint("ck_invoices_payment_state", "invoices", "payment_state IN ('CREDIT', 'TOTAL_PAID', 'PARTIAL_PAID')")
    op.create_check_constraint("ck_invoices_paid_amount_non_negative", "invoices", "paid_amount >= 0")
    op.create_check_constraint(
        "ck_invoices_payment_amount_matches_state",
        "invoices",
        "(payment_state = 'CREDIT' AND paid_amount = 0) OR "
        "(payment_state = 'TOTAL_PAID' AND paid_amount = grand_total) OR "
        "(payment_state = 'PARTIAL_PAID' AND paid_amount > 0 AND paid_amount < grand_total)",
    )

    op.add_column("invoice_items", sa.Column("product_item_number", sa.String(length=255), nullable=True))
    op.add_column("invoice_items", sa.Column("product_item_name", sa.Text(), nullable=True))
    op.add_column("invoice_items", sa.Column("product_category", sa.String(length=255), nullable=True))
    op.add_column("invoice_items", sa.Column("product_buyer_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("invoice_items", sa.Column("product_company_name", sa.String(length=255), nullable=True))
    op.add_column("invoice_items", sa.Column("buying_price", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.add_column("invoice_items", sa.Column("selling_price", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.add_column("invoice_items", sa.Column("unit", sa.String(length=50), nullable=True))
    op.add_column("invoice_items", sa.Column("revenue_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.add_column("invoice_items", sa.Column("buying_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.add_column("invoice_items", sa.Column("profit_amount", sa.Numeric(14, 2), nullable=False, server_default=sa.text("0")))
    op.execute(sa.text("""
        UPDATE invoice_items ii
        SET
            product_item_number = COALESCE(ii.product_code, p.item_number),
            product_item_name = COALESCE(ii.product_name, p.item_name),
            product_category = COALESCE(ii.category, p.category),
            product_buyer_id = p.buyer_id,
            product_company_name = COALESCE(ii.company, p.company_name),
            buying_price = COALESCE(p.buying_price, 0),
            selling_price = COALESCE(ii.unit_price_incl_tax, p.selling_price, 0),
            unit = p.unit,
            revenue_amount = ii.taxable_amount,
            buying_amount = ROUND((ii.quantity * COALESCE(p.buying_price, 0))::numeric, 2),
            profit_amount = ROUND((ii.taxable_amount - (ii.quantity * COALESCE(p.buying_price, 0)))::numeric, 2)
        FROM products p
        WHERE ii.product_id = p.id
    """))
    op.alter_column("invoice_items", "product_item_number", nullable=False)
    op.alter_column("invoice_items", "product_item_name", nullable=False)
    op.alter_column("invoice_items", "product_category", nullable=False)
    op.alter_column("invoice_items", "product_company_name", nullable=False)

    op.execute(sa.text("ALTER TABLE customer_transactions DROP CONSTRAINT IF EXISTS ck_customer_transactions_shape"))
    op.execute(sa.text("""
        INSERT INTO customer_transactions (id, customer_id, invoice_id, request_id, request_hash, opening_balance_customer_id, entry_type, amount, occurred_on, notes, created_by_user_id, created_at)
        SELECT gen_random_uuid(), i.customer_id, i.id, NULL, NULL, NULL, 'CREDIT_SALE', i.grand_total, i.invoice_date, 'Migrated invoice ' || i.invoice_number, i.created_by_user_id, now()
        FROM invoices i
        WHERE i.payment_state = 'TOTAL_PAID'
          AND NOT EXISTS (
              SELECT 1 FROM customer_transactions ct
              WHERE ct.invoice_id = i.id AND ct.entry_type = 'CREDIT_SALE'
          )
    """))
    op.execute(sa.text("""
        INSERT INTO customer_transactions (id, customer_id, invoice_id, request_id, request_hash, opening_balance_customer_id, entry_type, amount, occurred_on, notes, created_by_user_id, created_at)
        SELECT gen_random_uuid(), i.customer_id, i.id, NULL, NULL, NULL, 'COLLECTION', i.paid_amount, i.invoice_date, 'Migrated invoice ' || i.invoice_number || ' collection', i.created_by_user_id, now()
        FROM invoices i
        WHERE i.payment_state = 'TOTAL_PAID'
          AND i.paid_amount > 0
          AND NOT EXISTS (
              SELECT 1 FROM customer_transactions ct
              WHERE ct.invoice_id = i.id AND ct.entry_type = 'COLLECTION'
          )
    """))
    op.create_check_constraint(
        "ck_customer_transactions_shape",
        "customer_transactions",
        "(entry_type IN ('OPENING_BALANCE','COLLECTION','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(entry_type IN ('CREDIT_SALE','COLLECTION','INVOICE_CANCEL_REVERSAL','COLLECTION_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )


def downgrade() -> None:
    op.execute(sa.text("ALTER TABLE customer_transactions DROP CONSTRAINT IF EXISTS ck_customer_transactions_shape"))
    op.execute(sa.text("DELETE FROM customer_transactions WHERE entry_type IN ('COLLECTION','COLLECTION_REVERSAL') AND invoice_id IS NOT NULL"))
    op.create_check_constraint(
        "ck_customer_transactions_shape",
        "customer_transactions",
        "(entry_type IN ('OPENING_BALANCE','COLLECTION','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(entry_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )
    op.drop_column("invoice_items", "profit_amount")
    op.drop_column("invoice_items", "buying_amount")
    op.drop_column("invoice_items", "revenue_amount")
    op.drop_column("invoice_items", "unit")
    op.drop_column("invoice_items", "selling_price")
    op.drop_column("invoice_items", "buying_price")
    op.drop_column("invoice_items", "product_company_name")
    op.drop_column("invoice_items", "product_buyer_id")
    op.drop_column("invoice_items", "product_category")
    op.drop_column("invoice_items", "product_item_name")
    op.drop_column("invoice_items", "product_item_number")
    op.add_column("invoices", sa.Column("payment_mode", sa.String(length=32), nullable=True))
    op.execute(sa.text("UPDATE invoices SET payment_mode = CASE WHEN payment_state = 'CREDIT' THEN 'CREDIT' ELSE 'PAID' END"))
    op.alter_column("invoices", "payment_mode", nullable=False)
    op.drop_constraint("ck_invoices_payment_amount_matches_state", "invoices", type_="check")
    op.drop_constraint("ck_invoices_paid_amount_non_negative", "invoices", type_="check")
    op.drop_constraint("ck_invoices_payment_state", "invoices", type_="check")
    op.create_check_constraint("ck_invoices_payment_mode", "invoices", "payment_mode IN ('PAID', 'CREDIT')")
    op.drop_column("invoices", "paid_amount")
    op.drop_column("invoices", "payment_state")
    op.drop_column("invoices", "invoice_datetime")
