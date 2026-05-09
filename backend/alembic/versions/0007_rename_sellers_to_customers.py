"""rename seller tables and columns to customers

Revision ID: 0007_customers
Revises: 0006_buyers
Create Date: 2026-05-10 00:00:00
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "0007_customers"
down_revision: str | None = "0006_add_buyers"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    _rename_table_if_present("sellers", "customers")
    _rename_table_if_present("seller_transactions", "customer_transactions")
    _rename_column_if_present("customer_transactions", "seller_id", "customer_id")
    _rename_column_if_present("customer_transactions", "opening_balance_seller_id", "opening_balance_customer_id")
    _rename_column_if_present("invoices", "seller_id", "customer_id")
    _rename_column_if_present("invoices", "seller_name", "customer_name")
    _rename_column_if_present("invoices", "seller_address", "customer_address")
    _rename_column_if_present("invoices", "seller_state", "customer_state")
    _rename_column_if_present("invoices", "seller_state_code", "customer_state_code")
    _rename_column_if_present("invoices", "seller_phone", "customer_phone")
    _rename_column_if_present("invoices", "seller_gstin", "customer_gstin")
    op.execute(sa.text("UPDATE customer_transactions SET entry_type = 'COLLECTION' WHERE entry_type = 'PAYMENT'"))
    _rename_constraint_if_present("customers", "uq_sellers_name_phone", "uq_customers_name_phone")
    _rename_constraint_if_present("customer_transactions", "ck_seller_transactions_amount_positive", "ck_customer_transactions_amount_positive")
    _rename_constraint_if_present("customer_transactions", "ck_seller_transactions_shape", "ck_customer_transactions_shape")
    _rename_constraint_if_present("customer_transactions", "uq_seller_transactions_request_id", "uq_customer_transactions_request_id")
    op.execute(sa.text("ALTER INDEX IF EXISTS uq_seller_transactions_opening_balance RENAME TO uq_customer_transactions_opening_balance"))
    _rename_constraint_if_present("customer_transactions", "fk_seller_transactions_invoice_id_invoices", "fk_customer_transactions_invoice_id_invoices")
    op.execute(sa.text("ALTER TABLE customer_transactions DROP CONSTRAINT IF EXISTS ck_customer_transactions_shape"))
    op.create_check_constraint(
        "ck_customer_transactions_shape",
        "customer_transactions",
        "(entry_type IN ('OPENING_BALANCE','COLLECTION','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(entry_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )


def downgrade() -> None:
    op.execute(sa.text("ALTER TABLE customer_transactions DROP CONSTRAINT IF EXISTS ck_customer_transactions_shape"))
    op.create_check_constraint(
        "ck_seller_transactions_shape",
        "customer_transactions",
        "(entry_type IN ('OPENING_BALANCE','PAYMENT','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
        "(entry_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
    )
    op.execute(sa.text("UPDATE customer_transactions SET entry_type = 'PAYMENT' WHERE entry_type = 'COLLECTION'"))
    _rename_column_if_present("invoices", "customer_gstin", "seller_gstin")
    _rename_column_if_present("invoices", "customer_phone", "seller_phone")
    _rename_column_if_present("invoices", "customer_state_code", "seller_state_code")
    _rename_column_if_present("invoices", "customer_state", "seller_state")
    _rename_column_if_present("invoices", "customer_address", "seller_address")
    _rename_column_if_present("invoices", "customer_name", "seller_name")
    _rename_column_if_present("invoices", "customer_id", "seller_id")
    _rename_column_if_present("customer_transactions", "opening_balance_customer_id", "opening_balance_seller_id")
    _rename_column_if_present("customer_transactions", "customer_id", "seller_id")
    _rename_table_if_present("customer_transactions", "seller_transactions")
    _rename_table_if_present("customers", "sellers")


def _rename_table_if_present(old_name: str, new_name: str) -> None:
    op.execute(sa.text(f"""
        DO $$
        BEGIN
            IF to_regclass('{old_name}') IS NOT NULL AND to_regclass('{new_name}') IS NULL THEN
                ALTER TABLE {old_name} RENAME TO {new_name};
            END IF;
        END $$;
    """))


def _rename_column_if_present(table_name: str, old_name: str, new_name: str) -> None:
    op.execute(sa.text(f"""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = '{table_name}' AND column_name = '{old_name}'
            ) AND NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = '{table_name}' AND column_name = '{new_name}'
            ) THEN
                ALTER TABLE {table_name} RENAME COLUMN {old_name} TO {new_name};
            END IF;
        END $$;
    """))


def _rename_constraint_if_present(table_name: str, old_name: str, new_name: str) -> None:
    op.execute(sa.text(f"""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM pg_constraint WHERE conname = '{old_name}'
            ) AND NOT EXISTS (
                SELECT 1 FROM pg_constraint WHERE conname = '{new_name}'
            ) THEN
                ALTER TABLE {table_name} RENAME CONSTRAINT {old_name} TO {new_name};
            END IF;
        END $$;
    """))
