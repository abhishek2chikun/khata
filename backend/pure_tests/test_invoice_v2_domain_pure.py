from decimal import Decimal
import inspect

import pytest

from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.customer_transaction import CustomerTransaction
from app.routers import invoices
from app.schemas.invoice import InvoiceLineRequest
from app.services import invoice_service


pytestmark = pytest.mark.no_db


def test_invoice_model_exposes_payment_state_paid_amount_and_datetime_columns():
    columns = Invoice.__table__.c

    assert columns.payment_state.nullable is False
    assert columns.paid_amount.nullable is False
    assert columns.invoice_datetime.nullable is False


def test_invoice_item_model_exposes_product_snapshot_and_profit_input_columns():
    columns = InvoiceItem.__table__.c


    for column_name in [
        "product_item_number",
        "product_item_name",
        "product_category",
        "product_buyer_id",
        "product_company_name",
        "buying_price",
        "selling_price",
        "unit",
        "revenue_amount",
        "buying_amount",
        "profit_amount",
    ]:
        assert column_name in columns


def test_invoice_line_request_defaults_to_product_price_and_gst_overrides_optional():
    request = InvoiceLineRequest(product_id="aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa", quantity=Decimal("1.000"))

    assert request.pricing_mode == "TAX_INCLUSIVE"
    assert request.unit_price is None
    assert request.gst_rate is None


def test_customer_transaction_shape_allows_invoice_linked_collection_and_reversal_entries():
    shape_constraints = [constraint.sqltext.text for constraint in CustomerTransaction.__table__.constraints if constraint.name == "ck_customer_transactions_shape"]

    assert shape_constraints
    shape_sql = shape_constraints[0]
    assert "COLLECTION" in shape_sql
    assert "COLLECTION_REVERSAL" in shape_sql
    assert "invoice_id IS NOT NULL" in shape_sql


def test_invoice_list_api_and_service_expose_payment_state_filter_not_payment_mode():
    router_signature = inspect.signature(invoices.list_invoices)
    service_signature = inspect.signature(invoice_service.list_invoices)

    assert "payment_state" in router_signature.parameters
    assert "payment_state" in service_signature.parameters
    assert "payment_mode" not in router_signature.parameters
    assert "payment_mode" not in service_signature.parameters
