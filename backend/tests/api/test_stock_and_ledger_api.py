from uuid import uuid4


def test_adjust_stock_is_idempotent_and_locks_product_row(client, auth_headers):
    create = client.post(
        "/products",
        headers=auth_headers,
        json={
            "company": "Camlin",
            "category": "Pens",
            "item_name": "Blue Pen",
            "item_code": "PEN-001",
            "default_selling_price_excl_tax": "10.00",
            "default_gst_rate": "18.00",
            "quantity_on_hand": "5.000",
            "low_stock_threshold": "2.000",
        },
    )
    product_id = create.json()["id"]

    request_id = str(uuid4())
    payload = {"request_id": request_id, "quantity_delta": "5.000", "reason": "Stock count correction"}
    first = client.post(f"/products/{product_id}/adjust-stock", headers=auth_headers, json=payload)
    second = client.post(f"/products/{product_id}/adjust-stock", headers=auth_headers, json=payload)
    assert first.status_code == 200
    assert second.json()["quantity_on_hand"] == first.json()["quantity_on_hand"]

    conflict = client.post(
        f"/products/{product_id}/adjust-stock",
        headers=auth_headers,
        json={"request_id": request_id, "quantity_delta": "7.000", "reason": "Different correction"},
    )
    assert conflict.status_code == 409

    zero = client.post(
        f"/products/{product_id}/adjust-stock",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "quantity_delta": "0.000", "reason": "No-op"},
    )
    assert zero.status_code == 400


def test_adjust_stock_rejects_archived_products(client, auth_headers):
    create = client.post(
        "/products",
        headers=auth_headers,
        json={
            "company": "Camlin",
            "category": "Pens",
            "item_name": "Blue Pen",
            "item_code": "PEN-001",
            "default_selling_price_excl_tax": "10.00",
            "default_gst_rate": "18.00",
            "quantity_on_hand": "5.000",
            "low_stock_threshold": "2.000",
        },
    )
    product_id = create.json()["id"]

    archived = client.delete(f"/products/{product_id}", headers=auth_headers)
    assert archived.status_code == 200

    response = client.post(
        f"/products/{product_id}/adjust-stock",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "quantity_delta": "1.000", "reason": "Late count"},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "PRODUCT_ARCHIVED"


def test_opening_balance_payment_adjustment_and_ledger_view(client, auth_headers):
    seller = client.post(
        "/sellers",
        headers=auth_headers,
        json={
            "name": "ABC Stores",
            "address": "Market Yard",
            "phone": "9999999999",
            "gstin": "27BBBBB0000B1Z5",
        },
    )
    seller_id = seller.json()["id"]

    opening = client.post(
        f"/sellers/{seller_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "amount": "500.00", "occurred_on": "2026-04-19"},
    )
    assert opening.status_code == 201

    payment_request_id = str(uuid4())
    payment = client.post(
        "/payments",
        headers=auth_headers,
        json={"request_id": payment_request_id, "seller_id": seller_id, "amount": "100.00", "occurred_on": "2026-04-20", "notes": "Cash"},
    )
    assert payment.status_code == 201

    payment_repeat = client.post(
        "/payments",
        headers=auth_headers,
        json={"request_id": payment_request_id, "seller_id": seller_id, "amount": "100.00", "occurred_on": "2026-04-20", "notes": "Cash"},
    )
    assert payment_repeat.status_code == 201
    assert payment_repeat.json() == payment.json()

    payment_conflict = client.post(
        "/payments",
        headers=auth_headers,
        json={"request_id": payment_request_id, "seller_id": seller_id, "amount": "150.00", "occurred_on": "2026-04-20", "notes": "Changed"},
    )
    assert payment_conflict.status_code == 409

    adjustment_request_id = str(uuid4())
    adjustment = client.post(
        f"/sellers/{seller_id}/balance-adjustment",
        headers=auth_headers,
        json={"request_id": adjustment_request_id, "direction": "INCREASE", "amount": "50.00", "occurred_on": "2026-04-21", "notes": "Legacy correction"},
    )
    assert adjustment.status_code == 201

    adjustment_repeat = client.post(
        f"/sellers/{seller_id}/balance-adjustment",
        headers=auth_headers,
        json={"request_id": adjustment_request_id, "direction": "INCREASE", "amount": "50.00", "occurred_on": "2026-04-21", "notes": "Legacy correction"},
    )
    assert adjustment_repeat.status_code == 201
    assert adjustment_repeat.json() == adjustment.json()

    ledger = client.get(f"/sellers/{seller_id}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    assert len(ledger.json()["transactions"]) == 3
    assert ledger.json()["seller"]["pending_balance"] == "450.00"
    assert ledger.json()["invoices"] == []

    seller_detail = client.get(f"/sellers/{seller_id}", headers=auth_headers)
    assert seller_detail.status_code == 200
    assert seller_detail.json()["pending_balance"] == "450.00"


def test_opening_balance_and_adjustments_reject_invalid_or_archived_sellers(client, auth_headers):
    seller = client.post(
        "/sellers",
        headers=auth_headers,
        json={
            "name": "ABC Stores",
            "address": "Market Yard",
            "phone": "9999999999",
            "gstin": "27BBBBB0000B1Z5",
        },
    )
    seller_id = seller.json()["id"]

    zero_opening = client.post(
        f"/sellers/{seller_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "amount": "0.00", "occurred_on": "2026-04-19"},
    )
    assert zero_opening.status_code == 400

    first_opening_request_id = str(uuid4())
    first_opening = client.post(
        f"/sellers/{seller_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": first_opening_request_id, "amount": "500.00", "occurred_on": "2026-04-19"},
    )
    assert first_opening.status_code == 201

    repeat_opening = client.post(
        f"/sellers/{seller_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": first_opening_request_id, "amount": "500.00", "occurred_on": "2026-04-19"},
    )
    assert repeat_opening.status_code == 201
    assert repeat_opening.json() == first_opening.json()

    second_opening = client.post(
        f"/sellers/{seller_id}/opening-balance",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "amount": "200.00", "occurred_on": "2026-04-20"},
    )
    assert second_opening.status_code == 409
    assert second_opening.json()["error"]["code"] == "OPENING_BALANCE_EXISTS"

    zero_payment = client.post(
        "/payments",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "seller_id": seller_id, "amount": "0.00", "occurred_on": "2026-04-20", "notes": "Cash"},
    )
    assert zero_payment.status_code == 400

    zero_adjustment = client.post(
        f"/sellers/{seller_id}/balance-adjustment",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "direction": "INCREASE", "amount": "0.00", "occurred_on": "2026-04-21", "notes": "Legacy correction"},
    )
    assert zero_adjustment.status_code == 400

    archived = client.delete(f"/sellers/{seller_id}", headers=auth_headers)
    assert archived.status_code == 200

    archived_payment = client.post(
        "/payments",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "seller_id": seller_id, "amount": "100.00", "occurred_on": "2026-04-20", "notes": "Cash"},
    )
    assert archived_payment.status_code == 400
    assert archived_payment.json()["error"]["code"] == "SELLER_ARCHIVED"

    archived_adjustment = client.post(
        f"/sellers/{seller_id}/balance-adjustment",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "direction": "INCREASE", "amount": "50.00", "occurred_on": "2026-04-21", "notes": "Legacy correction"},
    )
    assert archived_adjustment.status_code == 400
    assert archived_adjustment.json()["error"]["code"] == "SELLER_ARCHIVED"
