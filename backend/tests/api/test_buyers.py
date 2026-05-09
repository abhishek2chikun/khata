from datetime import UTC, datetime
from uuid import uuid4


def _buyer_payload(**overrides):
    payload = {
        "name": "Camlin Distributors",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
        "state": "Maharashtra",
        "state_code": "27",
    }
    payload.update(overrides)
    return payload


def _entry_payload(**overrides):
    payload = {
        "request_id": str(uuid4()),
        "amount": "100.00",
        "occurred_at": datetime(2026, 5, 9, 10, 30, tzinfo=UTC).isoformat(),
        "notes": "manual entry",
    }
    payload.update(overrides)
    return payload


def test_create_list_and_search_buyers(client, auth_headers):
    created = client.post("/buyers", headers=auth_headers, json=_buyer_payload())
    assert created.status_code == 201
    body = created.json()
    assert body["name"] == "Camlin Distributors"
    assert body["phone"] == "9999999999"
    assert body["pending_payable"] == "0.00"

    client.post("/buyers", headers=auth_headers, json=_buyer_payload(name="Navneet Traders", phone="8888888888"))

    listing = client.get("/buyers", headers=auth_headers)
    assert listing.status_code == 200
    assert [buyer["name"] for buyer in listing.json()] == ["Camlin Distributors", "Navneet Traders"]

    searched = client.get("/buyers?search=nav", headers=auth_headers)
    assert searched.status_code == 200
    assert [buyer["name"] for buyer in searched.json()] == ["Navneet Traders"]


def test_buyer_detail_includes_computed_pending_payable(client, auth_headers):
    buyer_id = client.post("/buyers", headers=auth_headers, json=_buyer_payload()).json()["id"]
    client.post(f"/buyers/{buyer_id}/opening-payable", headers=auth_headers, json=_entry_payload(amount="250.00"))

    detail = client.get(f"/buyers/{buyer_id}", headers=auth_headers)

    assert detail.status_code == 200
    assert detail.json()["pending_payable"] == "250.00"


def test_add_purchase_amount_endpoint(client, auth_headers):
    buyer_id = client.post("/buyers", headers=auth_headers, json=_buyer_payload()).json()["id"]

    response = client.post(f"/buyers/{buyer_id}/purchase-amounts", headers=auth_headers, json=_entry_payload(amount="90.00"))

    assert response.status_code == 201
    assert response.json()["entry_type"] == "PURCHASE_AMOUNT"
    assert client.get(f"/buyers/{buyer_id}", headers=auth_headers).json()["pending_payable"] == "90.00"


def test_add_payment_made_endpoint(client, auth_headers):
    buyer_id = client.post("/buyers", headers=auth_headers, json=_buyer_payload()).json()["id"]
    client.post(f"/buyers/{buyer_id}/opening-payable", headers=auth_headers, json=_entry_payload(amount="250.00"))

    response = client.post(f"/buyers/{buyer_id}/payments-made", headers=auth_headers, json=_entry_payload(amount="80.00"))

    assert response.status_code == 201
    assert response.json()["entry_type"] == "PAYMENT_MADE"
    assert client.get(f"/buyers/{buyer_id}", headers=auth_headers).json()["pending_payable"] == "170.00"


def test_add_adjustment_endpoints(client, auth_headers):
    buyer_id = client.post("/buyers", headers=auth_headers, json=_buyer_payload()).json()["id"]
    client.post(f"/buyers/{buyer_id}/opening-payable", headers=auth_headers, json=_entry_payload(amount="200.00"))

    increase = client.post(f"/buyers/{buyer_id}/payable-adjustments", headers=auth_headers, json={**_entry_payload(amount="25.00"), "direction": "INCREASE"})
    decrease = client.post(f"/buyers/{buyer_id}/payable-adjustments", headers=auth_headers, json={**_entry_payload(amount="10.00"), "direction": "DECREASE"})

    assert increase.status_code == 201
    assert increase.json()["entry_type"] == "PAYABLE_INCREASE_ADJUSTMENT"
    assert decrease.status_code == 201
    assert decrease.json()["entry_type"] == "PAYABLE_DECREASE_ADJUSTMENT"
    assert client.get(f"/buyers/{buyer_id}", headers=auth_headers).json()["pending_payable"] == "215.00"
