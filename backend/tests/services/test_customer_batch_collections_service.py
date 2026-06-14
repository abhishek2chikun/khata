from datetime import date, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.app_user import AppUser
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.schemas.auth import CurrentUserResponse
from app.schemas.customer import BatchCollectionEntry, BatchCollectionRequest
from app.services import customer_service


def test_create_collection_batch_idempotent_and_updates_balances(db_session: Session, seeded_user: AppUser):
    today = date.today()
    customer = Customer(name="Batch Service Customer", address="Market")
    db_session.add(customer)
    db_session.flush()
    db_session.add(
        CustomerTransaction(
            customer_id=customer.id,
            request_id=uuid4(),
            request_hash="opening-hash",
            opening_balance_customer_id=customer.id,
            entry_type="OPENING_BALANCE",
            amount=Decimal("500.00"),
            occurred_on=today - timedelta(days=4),
            created_by_user_id=seeded_user.id,
        )
    )
    db_session.commit()

    current_user = CurrentUserResponse.model_validate(seeded_user)
    request_id = uuid4()
    payload = BatchCollectionRequest(
        request_id=request_id,
        entries=[
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today, amount=Decimal("100.00")),
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today - timedelta(days=1), amount=Decimal("50.00")),
        ],
    )

    first = customer_service.create_collection_batch(db_session, payload, current_user, today=today)
    second = customer_service.create_collection_batch(db_session, payload, current_user, today=today)

    assert first.entry_count == 2
    assert first.total_amount == "150.00"
    assert second.request_id == first.request_id
    assert second.entry_count == first.entry_count
    assert customer_service.build_customer_response(db_session, customer).pending_balance == "350.00"


def test_create_collection_batch_rejects_overpayment(db_session: Session, seeded_user: AppUser):
    today = date.today()
    customer = Customer(name="Overpay Customer", address="Market")
    db_session.add(customer)
    db_session.flush()
    db_session.add(
        CustomerTransaction(
            customer_id=customer.id,
            request_id=uuid4(),
            request_hash="opening-hash",
            opening_balance_customer_id=customer.id,
            entry_type="OPENING_BALANCE",
            amount=Decimal("100.00"),
            occurred_on=today - timedelta(days=4),
            created_by_user_id=seeded_user.id,
        )
    )
    db_session.commit()

    current_user = CurrentUserResponse.model_validate(seeded_user)
    payload = BatchCollectionRequest(
        request_id=uuid4(),
        entries=[
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today, amount=Decimal("60.00")),
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today - timedelta(days=1), amount=Decimal("50.00")),
        ],
    )

    with pytest.raises(Exception) as exc_info:
        customer_service.create_collection_batch(db_session, payload, current_user, today=today)
    assert exc_info.value.status_code == 409

    rows = db_session.query(CustomerTransaction).filter(CustomerTransaction.entry_type == "COLLECTION").all()
    assert rows == []
