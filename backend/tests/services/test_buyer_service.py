from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.models.buyer_transaction import BuyerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.buyer import BuyerAdjustmentRequest, BuyerCreateRequest, BuyerLedgerEntryRequest
from app.services import buyer_service


def _current_user(seeded_user) -> CurrentUserResponse:
    return CurrentUserResponse(id=seeded_user.id, username=seeded_user.username, display_name=seeded_user.display_name)


def _buyer_payload(**overrides) -> BuyerCreateRequest:
    data = {
        "name": "Camlin Distributors",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
        "state": "Maharashtra",
        "state_code": "27",
    }
    data.update(overrides)
    return BuyerCreateRequest(**data)


def _entry_payload(**overrides) -> BuyerLedgerEntryRequest:
    data = {
        "request_id": uuid4(),
        "amount": Decimal("100.00"),
        "occurred_at": datetime(2026, 5, 9, 10, 30, tzinfo=UTC),
        "notes": "manual entry",
    }
    data.update(overrides)
    return BuyerLedgerEntryRequest(**data)


def test_create_buyer_with_name_and_optional_contact_fields(db_session):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload(phone=None, gstin=None, state=None, state_code=None))

    assert buyer.name == "Camlin Distributors"
    assert buyer.address == "Market Yard"
    assert buyer.phone is None
    assert buyer.gstin is None
    assert buyer.state is None
    assert buyer.state_code is None
    assert buyer.is_active is True


def test_duplicate_buyer_name_is_rejected_but_duplicate_phone_with_different_name_is_allowed(db_session):
    buyer_service.create_buyer(db_session, _buyer_payload())

    with pytest.raises(HTTPException) as exc_info:
        buyer_service.create_buyer(db_session, _buyer_payload(phone="8888888888"))

    assert exc_info.value.status_code == 409
    assert exc_info.value.detail["error"]["code"] == "DUPLICATE_BUYER"

    allowed = buyer_service.create_buyer(db_session, _buyer_payload(name="Navneet Traders"))
    assert allowed.phone == "9999999999"


def test_opening_pending_amount_creates_opening_ledger_entry(db_session, seeded_user):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload())

    entry = buyer_service.create_opening_payable(db_session, buyer.id, _entry_payload(amount=Decimal("250.50")), _current_user(seeded_user))

    assert entry.buyer_id == buyer.id
    assert entry.entry_type == "OPENING_PAYABLE"
    assert entry.amount == Decimal("250.50")
    assert buyer_service.pending_payable_value(db_session, buyer.id) == Decimal("250.50")


def test_purchase_amount_increases_payable_balance(db_session, seeded_user):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload())

    buyer_service.create_purchase_amount(db_session, buyer.id, _entry_payload(amount=Decimal("90.00")), _current_user(seeded_user))


    assert buyer_service.pending_payable_value(db_session, buyer.id) == Decimal("90.00")


def test_payment_made_decreases_payable_balance(db_session, seeded_user):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload())
    buyer_service.create_opening_payable(db_session, buyer.id, _entry_payload(amount=Decimal("250.00")), _current_user(seeded_user))

    buyer_service.create_payment_made(db_session, buyer.id, _entry_payload(amount=Decimal("80.00")), _current_user(seeded_user))

    assert buyer_service.pending_payable_value(db_session, buyer.id) == Decimal("170.00")


def test_adjustments_increase_and_decrease_payable_balance(db_session, seeded_user):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload())
    buyer_service.create_opening_payable(db_session, buyer.id, _entry_payload(amount=Decimal("200.00")), _current_user(seeded_user))

    buyer_service.create_payable_adjustment(db_session, buyer.id, BuyerAdjustmentRequest(**_entry_payload(amount=Decimal("25.00")).model_dump(), direction="INCREASE"), _current_user(seeded_user))
    buyer_service.create_payable_adjustment(db_session, buyer.id, BuyerAdjustmentRequest(**_entry_payload(amount=Decimal("10.00")).model_dump(), direction="DECREASE"), _current_user(seeded_user))

    assert buyer_service.pending_payable_value(db_session, buyer.id) == Decimal("215.00")


def test_ledger_is_ordered_by_occurred_time_then_created_time(db_session, seeded_user):
    buyer = buyer_service.create_buyer(db_session, _buyer_payload())
    user = _current_user(seeded_user)
    occurred_at = datetime(2026, 5, 9, 9, 0, tzinfo=UTC)
    later_occurred_at = datetime(2026, 5, 10, 9, 0, tzinfo=UTC)
    second = buyer_service.create_purchase_amount(db_session, buyer.id, _entry_payload(amount=Decimal("20.00"), occurred_at=occurred_at), user)
    third = buyer_service.create_payment_made(db_session, buyer.id, _entry_payload(amount=Decimal("5.00"), occurred_at=later_occurred_at), user)
    first = buyer_service.create_opening_payable(db_session, buyer.id, _entry_payload(amount=Decimal("10.00"), occurred_at=occurred_at), user)
    db_session.query(BuyerTransaction).filter(BuyerTransaction.id == first.id).update({"created_at": datetime(2026, 5, 9, 10, 0, tzinfo=UTC)})
    db_session.query(BuyerTransaction).filter(BuyerTransaction.id == second.id).update({"created_at": datetime(2026, 5, 9, 10, 0, 1, tzinfo=UTC)})
    db_session.query(BuyerTransaction).filter(BuyerTransaction.id == third.id).update({"created_at": datetime(2026, 5, 9, 9, 59, tzinfo=UTC)})
    db_session.commit()

    ledger = buyer_service.get_buyer_ledger(db_session, buyer.id)

    assert [transaction.id for transaction in ledger.transactions] == [first.id, second.id, third.id]


def test_rejects_non_positive_ledger_amounts():
    with pytest.raises(ValueError):
        _entry_payload(amount=Decimal("0.00"))


def test_rejects_naive_ledger_dates():
    with pytest.raises(ValueError):
        _entry_payload(occurred_at=datetime.now() + timedelta(days=1))
