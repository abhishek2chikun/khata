from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from app.schemas.buyer import BuyerAdjustmentRequest, BuyerLedgerEntryRequest
from app.services import buyer_service


def test_buyer_ledger_entry_requires_positive_amount():
    with pytest.raises(ValueError):
        BuyerLedgerEntryRequest(request_id=uuid4(), amount=Decimal("0.00"), occurred_at=datetime(2026, 5, 9, 10, 30, tzinfo=UTC))


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


def test_product_model_links_buyer_id_to_buyers_table():
    from app.models.product import Product

    [buyer_id_column] = Product.__table__.c.buyer_id.foreign_keys

    assert buyer_id_column.target_fullname == "buyers.id"
