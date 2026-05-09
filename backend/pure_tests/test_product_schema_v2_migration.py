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
