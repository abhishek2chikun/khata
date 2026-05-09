import inspect
from datetime import date, datetime, timezone
from decimal import Decimal
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.core.pricing import normalize_line
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.customer_transaction import CustomerTransaction
from app.routers import invoices
from app.schemas.invoice import InvoiceCreateRequest, InvoiceLineRequest, InvoiceQuoteRequest
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


@pytest.mark.parametrize(
    "payload",
    [
        {"pricing_mode": "MYSTERY"},
        {"pricing_mode": "PRE_TAX", "unit_price": None},
        {"unit_price": Decimal("0.00")},
        {"unit_price": Decimal("-1.00")},
        {"gst_rate": Decimal("-0.01")},
        {"gst_rate": Decimal("100.01")},
        {"discount_percent": Decimal("-0.01")},
        {"discount_percent": Decimal("100.01")},
    ],
)
def test_invoice_line_request_rejects_invalid_overrides(payload):
    with pytest.raises(ValidationError):
        InvoiceLineRequest(product_id=uuid4(), quantity=Decimal("1.000"), **payload)


def test_tax_inclusive_pricing_preserves_entered_total_after_rounding():
    line = normalize_line(
        quantity=Decimal("3.000"),
        unit_price=Decimal("99.99"),
        pricing_mode="TAX_INCLUSIVE",
        gst_rate=Decimal("18.00"),
        discount_percent=Decimal("10.00"),
    )

    undiscounted_total = Decimal("299.97")
    expected_discount = Decimal("30.00")
    assert line.line_total == undiscounted_total - expected_discount
    assert line.gst_amount == line.line_total - line.taxable_amount
    assert line.line_total >= 0


def test_invoice_datetime_must_be_timezone_aware_and_match_invoice_date_when_supplied():
    with pytest.raises(ValidationError):
        InvoiceQuoteRequest(customer_id=uuid4(), invoice_datetime=datetime(2026, 4, 19, 12, 0), items=[{"product_id": uuid4(), "quantity": "1.000"}])

    with pytest.raises(ValidationError):
        InvoiceQuoteRequest(
            customer_id=uuid4(),
            invoice_datetime=datetime(2026, 4, 19, 12, 0, tzinfo=timezone.utc),
            invoice_date=date(2026, 4, 20),
            items=[{"product_id": uuid4(), "quantity": "1.000"}],
        )


def test_total_paid_request_hash_uses_resolved_paid_amount():
    request_id = uuid4()
    product_id = uuid4()
    customer_id = uuid4()
    invoice_datetime = datetime(2026, 4, 19, 12, 0, tzinfo=timezone.utc)
    base_payload = {
        "request_id": request_id,
        "customer_id": customer_id,
        "invoice_datetime": invoice_datetime,
        "payment_state": "TOTAL_PAID",
        "place_of_supply_state_code": "27",
        "items": [{"product_id": product_id, "quantity": "2.000"}],
    }

    omitted_paid_amount = InvoiceCreateRequest(**base_payload)
    explicit_paid_amount = InvoiceCreateRequest(**{**base_payload, "paid_amount": "236.00"})

    assert invoice_service._build_invoice_request_hash(omitted_paid_amount, "27", invoice_datetime, Decimal("236.00")) == invoice_service._build_invoice_request_hash(explicit_paid_amount, "27", invoice_datetime, Decimal("236.00"))


def test_invoice_model_and_migration_represent_payment_state_amount_constraints():
    constraint_sql = "\n".join(str(constraint.sqltext) for constraint in Invoice.__table__.constraints if constraint.name and constraint.name.startswith("ck_invoices_payment"))
    migration_text = _invoice_v2_migration_text()

    assert "payment_state = 'CREDIT' AND paid_amount = 0" in constraint_sql
    assert "payment_state = 'TOTAL_PAID' AND paid_amount = grand_total" in constraint_sql
    assert "payment_state = 'PARTIAL_PAID' AND paid_amount > 0 AND paid_amount < grand_total" in constraint_sql
    assert "ck_invoices_payment_amount_matches_state" in migration_text


def test_invoice_v2_migration_preserves_historical_item_snapshots_before_product_fallback():
    migration_text = _invoice_v2_migration_text()

    assert "COALESCE(ii.product_code, p.item_number)" in migration_text
    assert "COALESCE(ii.product_name, p.item_name)" in migration_text
    assert "COALESCE(ii.category, p.category)" in migration_text
    assert "COALESCE(ii.company, p.company_name)" in migration_text
    assert "COALESCE(ii.unit_price_incl_tax, p.selling_price, 0)" in migration_text


def test_invoice_v2_migration_synthesizes_paid_invoice_ledger_rows():
    migration_text = _invoice_v2_migration_text()

    assert "INSERT INTO customer_transactions" in migration_text
    assert "CREDIT_SALE" in migration_text
    assert "COLLECTION" in migration_text
    assert "payment_state = 'TOTAL_PAID'" in migration_text
    assert "NOT EXISTS" in migration_text


def test_invoice_v2_downgrade_handles_collection_rows_before_legacy_constraint():
    migration_text = _invoice_v2_migration_text()
    collection_handling = migration_text.index("DELETE FROM customer_transactions")
    constraint_creation = migration_text.index("op.create_check_constraint", migration_text.index("def downgrade"))

    assert collection_handling < constraint_creation
    assert "COLLECTION_REVERSAL" in migration_text


def _invoice_v2_migration_text() -> str:
    from pathlib import Path

    return (Path(__file__).resolve().parents[1] / "alembic" / "versions" / "0008_invoice_v2.py").read_text()
