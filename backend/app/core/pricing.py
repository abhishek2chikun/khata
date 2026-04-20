from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP

from app.core.tax import split_gst_rate

MONEY_PRECISION = Decimal("0.01")
RATE_PRECISION = Decimal("0.01")


def _round_money(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(MONEY_PRECISION, rounding=ROUND_HALF_UP)


def _round_rate(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(RATE_PRECISION, rounding=ROUND_HALF_UP)


@dataclass(frozen=True)
class NormalizedLine:
    quantity: Decimal
    pricing_mode: str
    entered_unit_price: Decimal
    unit_price_excl_tax: Decimal
    unit_price_incl_tax: Decimal
    gst_rate: Decimal
    cgst_rate: Decimal
    sgst_rate: Decimal
    igst_rate: Decimal
    discount_percent: Decimal
    discount_amount: Decimal
    taxable_amount: Decimal
    gst_amount: Decimal
    cgst_amount: Decimal
    sgst_amount: Decimal
    igst_amount: Decimal
    line_total: Decimal


def normalize_line(
    *,
    quantity: Decimal,
    unit_price: Decimal,
    pricing_mode: str,
    gst_rate: Decimal,
    discount_percent: Decimal,
    tax_regime: str = "INTRA_STATE",
) -> NormalizedLine:
    normalized_quantity = Decimal(quantity)
    normalized_entered_price = _round_money(unit_price)
    normalized_gst_rate = _round_rate(gst_rate)
    normalized_discount_percent = _round_rate(discount_percent)

    if pricing_mode == "PRE_TAX":
        unit_price_excl_tax = normalized_entered_price
        unit_price_incl_tax = _round_money(unit_price_excl_tax * (Decimal("1") + (normalized_gst_rate / Decimal("100"))))
    elif pricing_mode == "TAX_INCLUSIVE":
        unit_price_incl_tax = normalized_entered_price
        unit_price_excl_tax = _round_money(unit_price_incl_tax / (Decimal("1") + (normalized_gst_rate / Decimal("100"))))
    else:
        raise ValueError(f"Unsupported pricing mode: {pricing_mode}")

    line_subtotal = _round_money(normalized_quantity * unit_price_excl_tax)
    discount_amount = _round_money(line_subtotal * (normalized_discount_percent / Decimal("100")))
    taxable_amount = _round_money(line_subtotal - discount_amount)
    gst_amount = _round_money(taxable_amount * (normalized_gst_rate / Decimal("100")))

    cgst_rate, sgst_rate, igst_rate = split_gst_rate(normalized_gst_rate, tax_regime)
    if tax_regime == "INTER_STATE":
        cgst_amount = Decimal("0.00")
        sgst_amount = Decimal("0.00")
        igst_amount = gst_amount
    else:
        cgst_amount = _round_money(taxable_amount * (cgst_rate / Decimal("100")))
        sgst_amount = _round_money(gst_amount - cgst_amount)
        igst_amount = Decimal("0.00")

    line_total = _round_money(taxable_amount + gst_amount)
    return NormalizedLine(
        quantity=normalized_quantity,
        pricing_mode=pricing_mode,
        entered_unit_price=normalized_entered_price,
        unit_price_excl_tax=unit_price_excl_tax,
        unit_price_incl_tax=unit_price_incl_tax,
        gst_rate=normalized_gst_rate,
        cgst_rate=cgst_rate,
        sgst_rate=sgst_rate,
        igst_rate=igst_rate,
        discount_percent=normalized_discount_percent,
        discount_amount=discount_amount,
        taxable_amount=taxable_amount,
        gst_amount=gst_amount,
        cgst_amount=cgst_amount,
        sgst_amount=sgst_amount,
        igst_amount=igst_amount,
        line_total=line_total,
    )
