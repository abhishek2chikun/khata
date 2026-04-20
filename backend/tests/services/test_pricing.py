from decimal import Decimal

from app.core.pricing import normalize_line


def test_tax_inclusive_price_normalizes_correctly():
    line = normalize_line(
        quantity=Decimal("2"),
        unit_price=Decimal("118.00"),
        pricing_mode="TAX_INCLUSIVE",
        gst_rate=Decimal("18.00"),
        discount_percent=Decimal("5.00"),
    )

    assert line.unit_price_excl_tax == Decimal("100.00")
    assert line.unit_price_incl_tax == Decimal("118.00")
    assert line.discount_amount == Decimal("10.00")
    assert line.taxable_amount == Decimal("190.00")
    assert line.gst_amount == Decimal("34.20")
    assert line.cgst_rate == Decimal("9.00")
    assert line.sgst_rate == Decimal("9.00")
    assert line.igst_rate == Decimal("0.00")
    assert line.cgst_amount == Decimal("17.10")
    assert line.sgst_amount == Decimal("17.10")
    assert line.igst_amount == Decimal("0.00")
    assert line.line_total == Decimal("224.20")


def test_inter_state_pre_tax_line_splits_to_igst():
    line = normalize_line(
        quantity=Decimal("2"),
        unit_price=Decimal("100.00"),
        pricing_mode="PRE_TAX",
        gst_rate=Decimal("18.00"),
        discount_percent=Decimal("0.00"),
        tax_regime="INTER_STATE",
    )

    assert line.unit_price_excl_tax == Decimal("100.00")
    assert line.unit_price_incl_tax == Decimal("118.00")
    assert line.taxable_amount == Decimal("200.00")
    assert line.gst_amount == Decimal("36.00")
    assert line.cgst_amount == Decimal("0.00")
    assert line.sgst_amount == Decimal("0.00")
    assert line.igst_amount == Decimal("36.00")
    assert line.line_total == Decimal("236.00")
