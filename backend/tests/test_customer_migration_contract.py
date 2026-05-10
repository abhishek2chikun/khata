import importlib.util
from pathlib import Path

import pytest


pytestmark = pytest.mark.no_db

MIGRATION_PATH = (
    Path(__file__).resolve().parents[1]
    / "alembic"
    / "versions"
    / "0007_rename_sellers_to_customers.py"
)


def _load_migration_module():
    spec = importlib.util.spec_from_file_location("customer_rename_migration", MIGRATION_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_customer_rename_migration_adds_opening_balance_column_when_legacy_column_missing():
    source = MIGRATION_PATH.read_text()

    assert "_ensure_column_if_missing" in source
    assert "opening_balance_customer_id" in source
    assert '_ensure_column_if_missing("customer_transactions", "opening_balance_customer_id", "UUID")' in source


def test_customer_rename_migration_replaces_shape_check_before_entry_type_data_update():
    source = MIGRATION_PATH.read_text()

    drop_index = source.index("DROP CONSTRAINT IF EXISTS ck_customer_transactions_shape")
    create_index = source.index("op.create_check_constraint(\n        \"ck_customer_transactions_shape\"")
    update_index = source.index("UPDATE customer_transactions SET entry_type = 'COLLECTION'")

    assert drop_index < update_index
    assert update_index < create_index


def test_customer_rename_migration_handles_implicit_seller_foreign_key_names():
    source = MIGRATION_PATH.read_text()

    assert "fk_customer_transactions_customer_id_customers" in source
    assert "seller_transactions_seller_id_fkey" in source
    assert "fk_invoices_customer_id_customers" in source
    assert "invoices_seller_id_fkey" in source


def test_customer_rename_migration_helper_emits_add_column_when_missing_sql(monkeypatch):
    migration = _load_migration_module()
    statements: list[str] = []

    class FakeOp:
        def execute(self, statement):
            statements.append(str(statement))

    monkeypatch.setattr(migration, "op", FakeOp())

    migration._ensure_column_if_missing("customer_transactions", "opening_balance_customer_id", "UUID")

    assert "ALTER TABLE customer_transactions ADD COLUMN opening_balance_customer_id UUID" in statements[0]
