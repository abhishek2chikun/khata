from uuid import uuid4


def _customer_payload(**overrides):
    payload = {
        "name": "ABC Stores",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
    }
    payload.update(overrides)
    return payload


def test_customer_crud_and_archive_behavior(client, auth_headers):
    create = client.post("/customers", headers=auth_headers, json=_customer_payload())
    assert create.status_code == 201
    customer_id = create.json()["id"]

    detail = client.get(f"/customers/{customer_id}", headers=auth_headers)
    assert detail.status_code == 200
    assert "pending_balance" in detail.json()

    listing = client.get("/customers", headers=auth_headers)
    assert listing.status_code == 200
    assert listing.json()[0]["id"] == customer_id

    updated = client.put(
        f"/customers/{customer_id}",
        headers=auth_headers,
        json=_customer_payload(address="Updated Address"),
    )
    assert updated.status_code == 200
    assert updated.json()["address"] == "Updated Address"

    archived = client.delete(f"/customers/{customer_id}", headers=auth_headers)
    assert archived.status_code == 200
    assert archived.json()["is_active"] is False


def test_customer_ledger_preserves_balance_math_and_ordering(client, auth_headers):
    customer = client.post("/customers", headers=auth_headers, json=_customer_payload())
    assert customer.status_code == 201
    customer_id = customer.json()["id"]

    later_adjustment = client.post(
        f"/customers/{customer_id}/balance-adjustment",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "direction": "INCREASE",
            "amount": "50.00",
            "occurred_on": "2026-04-21",
            "notes": "Legacy correction",
        },
    )
    assert later_adjustment.status_code == 201

    opening = client.post(
        f"/customers/{customer_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "amount": "500.00", "occurred_on": "2026-04-19"},
    )
    assert opening.status_code == 201

    collection_request_id = str(uuid4())
    collection = client.post(
        "/collections",
        headers=auth_headers,
        json={
            "request_id": collection_request_id,
            "customer_id": customer_id,
            "amount": "100.00",
            "occurred_on": "2026-04-20",
            "notes": "Cash",
        },
    )
    assert collection.status_code == 201

    repeat = client.post(
        "/collections",
        headers=auth_headers,
        json={
            "request_id": collection_request_id,
            "customer_id": customer_id,
            "amount": "100.00",
            "occurred_on": "2026-04-20",
            "notes": "Cash",
        },
    )
    assert repeat.status_code == 201
    assert repeat.json() == collection.json()

    ledger = client.get(f"/customers/{customer_id}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    body = ledger.json()
    assert body["customer"]["pending_balance"] == "450.00"
    assert [transaction["entry_type"] for transaction in body["transactions"]] == [
        "OPENING_BALANCE",
        "COLLECTION",
        "BALANCE_INCREASE_ADJUSTMENT",
    ]
    assert [transaction["occurred_on"] for transaction in body["transactions"]] == [
        "2026-04-19",
        "2026-04-20",
        "2026-04-21",
    ]


def test_seller_routes_are_not_active(client, auth_headers):
    response = client.get("/sellers", headers=auth_headers)
    assert response.status_code == 404
