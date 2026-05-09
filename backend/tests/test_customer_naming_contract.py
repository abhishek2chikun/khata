from app.main import create_app
from app.models.base import Base
import pytest


pytestmark = pytest.mark.no_db


def test_backend_routes_expose_customer_not_seller_names():
    paths = {route.path for route in create_app().routes}
    assert "/customers" in paths
    assert "/customers/{customer_id}" in paths
    assert "/customers/{customer_id}/ledger" in paths
    assert "/collections" in paths
    assert not any(path.startswith("/sellers") for path in paths)
    assert "/payments" not in paths


def test_backend_metadata_uses_customer_tables():
    table_names = set(Base.metadata.tables)
    assert "customers" in table_names
    assert "customer_transactions" in table_names
    assert "sellers" not in table_names
    assert "seller_transactions" not in table_names


def test_backend_metadata_uses_customer_columns_for_current_schema():
    invoices = Base.metadata.tables["invoices"]
    customer_transactions = Base.metadata.tables["customer_transactions"]

    assert "customer_id" in invoices.c
    assert "customer_name" in invoices.c
    assert "seller_id" not in invoices.c
    assert "seller_name" not in invoices.c
    assert "customer_id" in customer_transactions.c
    assert "opening_balance_customer_id" in customer_transactions.c
    assert "seller_id" not in customer_transactions.c
