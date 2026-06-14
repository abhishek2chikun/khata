from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.core.decimals import (
    canonical_integral_quantity_string,
    canonical_unit_price_string,
    normalize_hsn_code,
    validate_discount_disabled,
    validate_non_negative_integral_quantity,
    validate_positive_integral_quantity,
    validate_unit_price,
)
from app.schemas.invoice import InvoiceLineRequest

pytestmark = pytest.mark.no_db


def test_normalize_hsn_code_trims_and_rejects_long_values():
    assert normalize_hsn_code(" 9608 ") == "9608"
    assert normalize_hsn_code("") is None
    assert normalize_hsn_code(None) is None

    with pytest.raises(ValueError, match="hsn_code must be at most 32 characters"):
        normalize_hsn_code("x" * 33)


def test_validate_unit_price_requires_positive_three_decimal_places():
    assert validate_unit_price(Decimal("10.125")) == Decimal("10.125")

    with pytest.raises(ValueError, match="unit price must be greater than zero"):
        validate_unit_price(Decimal("0"))

    with pytest.raises(ValueError, match="three decimal places"):
        validate_unit_price(Decimal("10.1234"))


def test_validate_integral_quantities():
    assert validate_positive_integral_quantity(Decimal("5")) == Decimal("5")
    assert validate_non_negative_integral_quantity(Decimal("0")) == Decimal("0")

    with pytest.raises(ValueError, match="whole number"):
        validate_positive_integral_quantity(Decimal("1.5"))

    with pytest.raises(ValueError, match="whole number"):
        validate_non_negative_integral_quantity(Decimal("1.25"))


def test_validate_discount_disabled():
    assert validate_discount_disabled(Decimal("0.00")) == Decimal("0.00")

    with pytest.raises(ValueError, match="discounts are disabled"):
        validate_discount_disabled(Decimal("0.01"))


def test_canonical_strings_for_invoice_hash():
    assert canonical_unit_price_string(Decimal("118")) == "118.000"
    assert canonical_integral_quantity_string(Decimal("2")) == "2"


def test_invoice_line_request_rejects_fractional_quantity_and_discount():
    with pytest.raises(ValidationError):
        InvoiceLineRequest(
            product_id="aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa",
            quantity=Decimal("1.5"),
        )

    with pytest.raises(ValidationError):
        InvoiceLineRequest(
            product_id="aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa",
            quantity=Decimal("1"),
            discount_percent=Decimal("5.00"),
        )

    with pytest.raises(ValidationError):
        InvoiceLineRequest(
            product_id="aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa",
            quantity=Decimal("1"),
            unit_price=Decimal("10.1234"),
        )
