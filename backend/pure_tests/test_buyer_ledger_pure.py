from datetime import UTC, datetime
from decimal import Decimal
from inspect import signature
from uuid import uuid4

import pytest

from app.schemas.buyer import BuyerAdjustmentRequest, BuyerLedgerEntryRequest
from app.services import buyer_service


def test_buyer_ledger_entry_requires_positive_amount():
    with pytest.raises(ValueError):
        BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("0.00"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC))


def test_buyer_ledger_entry_rejects_money_with_more_than_two_decimal_places():
    with pytest.raises(ValueError):
        BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("1.001"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC))


def test_buyer_ledger_entry_rejects_money_exceeding_numeric_capacity():
    with pytest.raises(ValueError):
        BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("1000000000000.00"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC))


def test_buyer_ledger_entry_accepts_max_numeric_money_value():
    request = BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("999999999999.99"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC))

    assert request.amount == Decimal("999999999999.99")


def test_buyer_ledger_entry_requires_timezone_aware_occurred_at():
    with pytest.raises(ValueError):
        BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("1.00"), occurred_at=datetime(2026, 5, 9, 10, 30))


def test_buyer_adjustment_accepts_explicit_increase_and_decrease_directions():
    increase = BuyerAdjustmentRequest(request_id=uuid4(), amount=Decimal("1.00"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC), direction="INCREASE")
    decrease = BuyerAdjustmentRequest(request_id=uuid4(), amount=Decimal("1.00"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC), direction="DECREASE")

    assert increase.direction == "INCREASE"
    assert decrease.direction == "DECREASE"


def test_entry_hash_is_deterministic_for_retry_safe_writes():
    payload = {"buyer_id": str(uuid4()), "entry_type": "PURCHASE_AMOUNT", "request_id": str(uuid4()), "amount": "10.00"}

    assert buyer_service._entry_hash(payload) == buyer_service._entry_hash({"amount": "10.00", **payload})


def test_buyer_migration_uses_canonical_payable_entry_types():
    from pathlib import Path

    migration_text = (Path(__file__).resolve().parents[1] / "alembic" / "versions" / "0006_add_buyers.py").read_text()

    assert "OPENING_PAYABLE" in migration_text
    assert "PURCHASE_AMOUNT" in migration_text
    assert "PAYMENT_MADE" in migration_text
    assert "PAYABLE_INCREASE_ADJUSTMENT" in migration_text
    assert "PAYABLE_DECREASE_ADJUSTMENT" in migration_text


def test_buyer_migration_does_not_add_unsafe_product_buyer_foreign_key():
    from pathlib import Path

    migration_text = (Path(__file__).resolve().parents[1] / "alembic" / "versions" / "0006_add_buyers.py").read_text()

    assert "fk_products_buyer_id_buyers" not in migration_text
    assert "create_foreign_key" not in migration_text
    assert "drop_constraint" not in migration_text


def test_product_model_keeps_buyer_id_nullable_without_task7_foreign_key():
    from app.models.product import Product

    buyer_id_column = Product.__table__.c.buyer_id

    assert buyer_id_column.nullable is True
    assert buyer_id_column.foreign_keys == set()


def test_buyer_routes_type_path_ids_as_uuid_for_fastapi_validation():
    from app.routers import buyers
    import uuid

    route_handlers = [
        buyers.get_buyer,
        buyers.create_opening_payable,
        buyers.create_purchase_amount,
        buyers.create_payment_made,
        buyers.create_payable_adjustment,
        buyers.get_buyer_ledger,
    ]

    for handler in route_handlers:
        assert signature(handler).parameters["buyer_id"].annotation is uuid.UUID
