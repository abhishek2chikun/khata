from decimal import Decimal
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.customer import BalanceAdjustmentRequest, CollectionRequest, OpeningBalanceRequest


@pytest.mark.no_db
@pytest.mark.parametrize(
    "request_cls,payload",
    [
        (OpeningBalanceRequest, {}),
        (CollectionRequest, {"customer_id": uuid4()}),
        (BalanceAdjustmentRequest, {"direction": "INCREASE"}),
    ],
)
@pytest.mark.parametrize("amount", [Decimal("0"), Decimal("-0.01"), Decimal("1.001"), Decimal("1000000000000.00")])
def test_customer_money_requests_reject_invalid_amounts(request_cls, payload, amount):
    with pytest.raises(ValidationError):
        request_cls(
            request_id=uuid4(),
            amount=amount,
            occurred_on="2026-04-20",
            **payload,
        )


@pytest.mark.no_db
@pytest.mark.parametrize(
    "request_cls,payload",
    [
        (OpeningBalanceRequest, {}),
        (CollectionRequest, {"customer_id": uuid4()}),
        (BalanceAdjustmentRequest, {"direction": "DECREASE"}),
    ],
)
@pytest.mark.parametrize("amount", [Decimal("0.01"), Decimal("999999999999.99"), Decimal("125.50")])
def test_customer_money_requests_accept_valid_amounts(request_cls, payload, amount):
    request = request_cls(
        request_id=uuid4(),
        amount=amount,
        occurred_on="2026-04-20",
        **payload,
    )

    assert request.amount == amount
