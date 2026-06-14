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


def _customer_payload(**overrides):
    payload = {
        "name": "Batch Customer",
        "address": "Market Yard",
        "phone": "9999999999",
    }
    payload.update(overrides)
    return payload


def _create_customer(client, auth_headers, **overrides) -> str:
    response = client.post("/customers", headers=auth_headers, json=_customer_payload(**overrides))
    assert response.status_code == 201
    return response.json()["id"]


def _seed_opening(client, auth_headers, customer_id: str, amount: str, *, occurred_on: str | None = None) -> None:
    response = client.post(
        f"/customers/{customer_id}/opening-balance",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "amount": amount,
            "occurred_on": occurred_on or (date.today() - timedelta(days=4)).isoformat(),
        },
    )
    assert response.status_code == 201


def test_collection_grid_returns_positive_active_customers_only(client, auth_headers):
    today = date.today().isoformat()
    owing_id = _create_customer(client, auth_headers, name="Owing Shop")
    zero_id = _create_customer(client, auth_headers, name="Zero Shop", phone="8888888888")
    archived_id = _create_customer(client, auth_headers, name="Archived Shop", phone="7777777777")
    _seed_opening(client, auth_headers, owing_id, "500.00")
    _seed_opening(client, auth_headers, zero_id, "100.00")
    _seed_opening(client, auth_headers, archived_id, "300.00")
    client.post(
        "/collections",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "customer_id": zero_id,
            "amount": "100.00",
            "occurred_on": today,
        },
    )
    client.delete(f"/customers/{archived_id}", headers=auth_headers)

    response = client.get(
        "/customers/collection-grid",
        headers=auth_headers,
        params={"from_date": today, "to_date": today},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["from_date"] == today
    assert body["to_date"] == today
    assert body["dates"] == [today]
    assert [row["name"] for row in body["customers"]] == ["Owing Shop"]
    assert body["customers"][0]["pending_balance"] == "500.00"


def test_collection_grid_includes_existing_collection_totals(client, auth_headers):
    today = date.today()
    today_str = today.isoformat()
    tomorrow_str = (today + timedelta(days=1)).isoformat()
    customer_id = _create_customer(client, auth_headers)
    _seed_opening(client, auth_headers, customer_id, "500.00")
    client.post(
        "/collections",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "customer_id": customer_id,
            "amount": "75.50",
            "occurred_on": today_str,
        },
    )

    response = client.get(
        "/customers/collection-grid",
        headers=auth_headers,
        params={"from_date": today_str, "to_date": tomorrow_str if tomorrow_str <= today_str else today_str},
    )

    assert response.status_code == 200
    row = response.json()["customers"][0]
    assert row["existing_totals"] == {today_str: "75.50"}


def test_collection_grid_rejects_future_and_old_ranges(client, auth_headers):
    future = client.get(
        "/customers/collection-grid",
        headers=auth_headers,
        params={"from_date": "2099-01-01", "to_date": "2099-01-01"},
    )
    assert future.status_code == 400
    assert future.json()["error"]["code"] == "VALIDATION_ERROR"

    old = client.get(
        "/customers/collection-grid",
        headers=auth_headers,
        params={"from_date": "2020-01-01", "to_date": "2020-01-01"},
    )
    assert old.status_code == 400


def test_collection_batch_posts_one_day_and_seven_day_entries(client, auth_headers):
    today = date.today()
    today_str = today.isoformat()
    customer_a = _create_customer(client, auth_headers, name="Alpha", phone="1111111111")
    customer_b = _create_customer(client, auth_headers, name="Beta", phone="2222222222")
    _seed_opening(client, auth_headers, customer_a, "500.00")
    _seed_opening(client, auth_headers, customer_b, "300.00")

    request_id = str(uuid4())
    entries = [
        {"customer_id": customer_a, "occurred_on": today_str, "amount": "100.00"},
        {"customer_id": customer_b, "occurred_on": today_str, "amount": "50.00"},
    ]
    response = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={"request_id": request_id, "entries": entries},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["request_id"] == request_id
    assert body["entry_count"] == 2
    assert body["total_amount"] == "150.00"
    assert body["affected_customers"] == 2

    seven_day_request = str(uuid4())
    seven_entries = [
        {"customer_id": customer_a, "occurred_on": (today - timedelta(days=offset)).isoformat(), "amount": "10.00"}
        for offset in range(7)
    ]
    seven_response = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={"request_id": seven_day_request, "entries": seven_entries},
    )
    assert seven_response.status_code == 201
    assert seven_response.json()["entry_count"] == 7


def test_collection_batch_is_idempotent_and_rejects_conflicting_retry(client, auth_headers):
    today_str = date.today().isoformat()
    customer_id = _create_customer(client, auth_headers)
    _seed_opening(client, auth_headers, customer_id, "500.00")
    request_id = str(uuid4())
    payload = {
        "request_id": request_id,
        "entries": [{"customer_id": customer_id, "occurred_on": today_str, "amount": "100.00"}],
    }

    first = client.post("/customers/collection-batch", headers=auth_headers, json=payload)
    second = client.post("/customers/collection-batch", headers=auth_headers, json=payload)
    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json() == first.json()

    conflict = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={
            "request_id": request_id,
            "entries": [{"customer_id": customer_id, "occurred_on": today_str, "amount": "120.00"}],
        },
    )
    assert conflict.status_code == 409
    assert conflict.json()["error"]["code"] == "IDEMPOTENCY_CONFLICT"


def test_collection_batch_rejects_duplicate_cells_overpayment_and_archived_customer(client, auth_headers):
    today_str = date.today().isoformat()
    yesterday_str = (date.today() - timedelta(days=1)).isoformat()
    customer_id = _create_customer(client, auth_headers)
    archived_id = _create_customer(client, auth_headers, name="Archived", phone="3333333333")
    _seed_opening(client, auth_headers, customer_id, "100.00")
    _seed_opening(client, auth_headers, archived_id, "200.00")
    client.delete(f"/customers/{archived_id}", headers=auth_headers)

    duplicate = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "entries": [
                {"customer_id": customer_id, "occurred_on": today_str, "amount": "10.00"},
                {"customer_id": customer_id, "occurred_on": today_str, "amount": "20.00"},
            ],
        },
    )
    assert duplicate.status_code == 400

    overpay = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "entries": [
                {"customer_id": customer_id, "occurred_on": today_str, "amount": "60.00"},
                {"customer_id": customer_id, "occurred_on": yesterday_str, "amount": "50.00"},
            ],
        },
    )
    assert overpay.status_code == 409
    assert overpay.json()["error"]["code"] == "STALE_BALANCE"

    archived = client.post(
        "/customers/collection-batch",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "entries": [{"customer_id": archived_id, "occurred_on": today_str, "amount": "10.00"}],
        },
    )
    assert archived.status_code == 400
    assert archived.json()["error"]["code"] == "CUSTOMER_ARCHIVED"


def test_collection_batch_rolls_back_all_rows_on_injected_failure(db_session: Session, seeded_user: AppUser):
    today = date.today()
    customer = Customer(name="Rollback Customer", address="Market")
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

    original_add = db_session.add
    call_count = {"value": 0}

    def flaky_add(instance, *args, **kwargs):
        if isinstance(instance, CustomerTransaction) and instance.entry_type == "COLLECTION":
            call_count["value"] += 1
            if call_count["value"] == 2:
                raise RuntimeError("simulated failure")
        return original_add(instance, *args, **kwargs)

    db_session.add = flaky_add  # type: ignore[method-assign]
    current_user = CurrentUserResponse.model_validate(seeded_user)
    payload = BatchCollectionRequest(
        request_id=uuid4(),
        entries=[
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today, amount=Decimal("10.00")),
            BatchCollectionEntry(customer_id=customer.id, occurred_on=today - timedelta(days=1), amount=Decimal("20.00")),
        ],
    )

    with pytest.raises(RuntimeError):
        customer_service.create_collection_batch(db_session, payload, current_user, today=today)

    db_session.rollback()
    rows = db_session.query(CustomerTransaction).filter(CustomerTransaction.entry_type == "COLLECTION").all()
    assert rows == []
