from decimal import Decimal, InvalidOperation, ROUND_HALF_UP

MONEY_PRECISION = Decimal("0.01")
UNIT_PRICE_PRECISION = Decimal("0.001")
RATE_PRECISION = Decimal("0.01")
HSN_MAX_LENGTH = 32


def round_money(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(MONEY_PRECISION, rounding=ROUND_HALF_UP)


def round_unit_price(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(UNIT_PRICE_PRECISION, rounding=ROUND_HALF_UP)


def round_rate(value: Decimal | str) -> Decimal:
    return Decimal(value).quantize(RATE_PRECISION, rounding=ROUND_HALF_UP)


def normalize_hsn_code(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = value.strip()
    if not normalized:
        return None
    if len(normalized) > HSN_MAX_LENGTH:
        raise ValueError(f"hsn_code must be at most {HSN_MAX_LENGTH} characters")
    return normalized


def validate_unit_price(value: Decimal) -> Decimal:
    if value <= 0:
        raise ValueError("unit price must be greater than zero")
    try:
        if value != value.quantize(UNIT_PRICE_PRECISION):
            raise ValueError("unit price must have at most three decimal places")
    except InvalidOperation as exc:
        raise ValueError("unit price must have at most three decimal places") from exc
    return round_unit_price(value)


def validate_positive_integral_quantity(value: Decimal) -> Decimal:
    if value <= 0:
        raise ValueError("quantity must be greater than zero")
    if value != value.to_integral_value():
        raise ValueError("quantity must be a whole number")
    if value > Decimal("99999999999"):
        raise ValueError("quantity exceeds maximum supported value")
    return value


def validate_non_negative_integral_quantity(value: Decimal) -> Decimal:
    if value < 0:
        raise ValueError("quantity must be non-negative")
    if value != value.to_integral_value():
        raise ValueError("quantity must be a whole number")
    return value


def validate_non_zero_integral_quantity(value: Decimal) -> Decimal:
    if value == 0:
        raise ValueError("quantity delta must be non-zero")
    validate_positive_integral_quantity(abs(value))
    return value


def validate_discount_disabled(value: Decimal) -> Decimal:
    if value != Decimal("0.00"):
        raise ValueError("discounts are disabled")
    return value


def canonical_unit_price_string(value: Decimal | str) -> str:
    return f"{round_unit_price(value):.3f}"


def canonical_integral_quantity_string(value: Decimal | str) -> str:
    return str(int(Decimal(value)))
