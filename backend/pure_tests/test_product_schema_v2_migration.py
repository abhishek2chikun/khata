from decimal import Decimal
import importlib.util
from pathlib import Path


module_path = Path(__file__).resolve().parents[1] / "alembic" / "versions" / "0005_product_schema_v2.py"
spec = importlib.util.spec_from_file_location("product_schema_v2", module_path)
product_schema_v2 = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(product_schema_v2)


def test_buying_price_conversion_uses_inclusive_price_when_gst_rate_is_present():
    assert product_schema_v2.to_inclusive_money(Decimal("100.00"), Decimal("18.00")) == Decimal("118.00")


def test_buying_price_conversion_falls_back_to_zero_when_legacy_price_is_null():
    assert product_schema_v2.to_inclusive_money(None, Decimal("18.00")) == Decimal("0.00")


def test_buying_price_conversion_preserves_value_when_gst_rate_is_null():
    assert product_schema_v2.to_inclusive_money(Decimal("100.00"), None) == Decimal("100.00")


def test_downgrade_buying_price_conversion_restores_pre_tax_value():
    assert product_schema_v2.to_pre_tax_money(Decimal("118.00"), Decimal("18.00")) == Decimal("100.00")


def test_downgrade_buying_price_conversion_uses_preserved_buying_gst_rate():
    assert product_schema_v2.to_pre_tax_money(Decimal("112.00"), Decimal("12.00")) == Decimal("100.00")


def test_downgrade_buying_price_conversion_preserves_value_when_gst_rate_is_zero_or_null():
    assert product_schema_v2.to_pre_tax_money(Decimal("100.00"), Decimal("0.00")) == Decimal("100.00")
    assert product_schema_v2.to_pre_tax_money(Decimal("100.00"), None) == Decimal("100.00")


def test_product_v2_migration_preserves_buying_gst_rate_for_downgrade():
    migration_text = module_path.read_text()

    assert 'op.drop_column("products", "buying_gst_rate")' not in migration_text
    assert "buyer_id" in migration_text
    assert "buying_gst_rate" in migration_text


def test_seed_invoice_lines_use_tax_inclusive_product_prices():
    from app.commands.seed_demo_data import _demo_product_payloads, _demo_invoice_line_payloads

    products = _demo_product_payloads()
    lines = _demo_invoice_line_payloads(products)

    assert lines["PEN-001"].pricing_mode == "TAX_INCLUSIVE"
    assert lines["PEN-001"].unit_price == products["PEN-001"].selling_price
    assert lines["NOTE-001"].pricing_mode == "TAX_INCLUSIVE"
    assert lines["NOTE-001"].unit_price == products["NOTE-001"].selling_price
    assert lines["FILE-001"].pricing_mode == "TAX_INCLUSIVE"
    assert lines["FILE-001"].unit_price == products["FILE-001"].selling_price
    assert lines["MRK-001"].pricing_mode == "TAX_INCLUSIVE"
    assert lines["MRK-001"].unit_price == products["MRK-001"].selling_price


def test_seed_product_sync_updates_existing_product_to_current_v2_defaults():
    from app.commands.seed_demo_data import _sync_seed_product

    class ExistingProduct:
        company_name = "Old Company"
        category = "Old Category"
        item_name = "Old Name"
        item_number = "PEN-001"
        buying_price = Decimal("8.00")
        selling_price = Decimal("12.00")
        unit = "old"
        gst_rate = Decimal("5.00")
        quantity_on_hand = Decimal("1.000")
        low_stock_threshold = Decimal("1.000")

    from app.commands.seed_demo_data import _demo_product_payloads

    product = ExistingProduct()
    payload = _demo_product_payloads()["PEN-001"]

    _sync_seed_product(product, payload)

    assert product.company_name == payload.company_name
    assert product.category == payload.category
    assert product.item_name == payload.item_name
    assert product.buying_price == payload.buying_price
    assert product.selling_price == payload.selling_price
    assert product.unit == payload.unit
    assert product.gst_rate == payload.gst_rate
    assert product.low_stock_threshold == payload.low_stock_threshold
    assert product.quantity_on_hand == Decimal("1.000")


def test_seed_invoice_request_ids_are_versioned_for_tax_inclusive_payloads():
    from app.commands.seed_demo_data import _demo_invoice_request_ids, _seed_uuid

    request_ids = _demo_invoice_request_ids()

    assert request_ids["abc_stores_credit"] == _seed_uuid("invoice-v2", "abc-stores", "credit-1")
    assert request_ids["abc_stores_credit"] != _seed_uuid("invoice", "abc-stores", "credit-1")


def test_seed_invoice_creation_skips_when_legacy_or_v2_request_id_exists():
    from app.commands.seed_demo_data import _demo_invoice_request_ids, _legacy_demo_invoice_request_ids, _should_create_demo_invoice

    v2_request_ids = _demo_invoice_request_ids()
    legacy_request_ids = _legacy_demo_invoice_request_ids()

    assert _should_create_demo_invoice("abc_stores_credit", set()) is True
    assert _should_create_demo_invoice("abc_stores_credit", {legacy_request_ids["abc_stores_credit"]}) is False
    assert _should_create_demo_invoice("abc_stores_credit", {v2_request_ids["abc_stores_credit"]}) is False
