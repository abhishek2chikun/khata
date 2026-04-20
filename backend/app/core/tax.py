from decimal import Decimal, ROUND_HALF_UP

from app.core.state_codes import get_state_name, normalize_state_code

RATE_PRECISION = Decimal("0.01")


def _round_rate(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(RATE_PRECISION, rounding=ROUND_HALF_UP)


def resolve_place_of_supply_state(state_code: str) -> str:
    return get_state_name(state_code)


def derive_tax_regime(company_state_code: str, place_of_supply_state_code: str) -> str:
    company_code = normalize_state_code(company_state_code)
    supply_code = normalize_state_code(place_of_supply_state_code)
    resolve_place_of_supply_state(company_code)
    resolve_place_of_supply_state(supply_code)
    return "INTRA_STATE" if company_code == supply_code else "INTER_STATE"


def split_gst_rate(gst_rate: Decimal | str, tax_regime: str) -> tuple[Decimal, Decimal, Decimal]:
    normalized_rate = _round_rate(gst_rate)
    if tax_regime == "INTER_STATE":
        return Decimal("0.00"), Decimal("0.00"), normalized_rate
    if tax_regime != "INTRA_STATE":
        raise ValueError(f"Unsupported tax regime: {tax_regime}")

    cgst_rate = _round_rate(normalized_rate / Decimal("2"))
    sgst_rate = _round_rate(normalized_rate - cgst_rate)
    return cgst_rate, sgst_rate, Decimal("0.00")
