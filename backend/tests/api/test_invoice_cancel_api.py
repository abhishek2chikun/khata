from uuid import uuid4


def _company_payload() -> dict:
    return {
        "name": "Acme Traders",
        "address": "Main Road",
        "city": "Pune",
        "state": "Maharashtra",
        "state_code": "27",
        "gstin": "27AAAAA0000A1Z5",
        "phone": "9999999999",
        "email": "owner@example.com",
        "bank_name": "ABC Bank",
        "bank_account": "1234567890",
        "bank_ifsc": "ABC0001234",
        "bank_branch": "Pune",
        "jurisdiction": "Pune",
    }


def _create_credit_invoice(client, auth_headers) -> dict:
    seller_name = f"ABC Stores {uuid4()}"
    seller_phone = str(uuid4().int)[:10]
    item_suffix = str(uuid4())
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post(
        "/sellers",
        headers=auth_headers,
        json={
            "name": seller_name,
            "address": "Market Yard",
            "phone": seller_phone,
            "gstin": "27BBBBB0000B1Z5",
            "state": "Maharashtra",
            "state_code": "27",
        },
    )
    assert seller.status_code == 201
    product = client.post(
        "/products",
        headers=auth_headers,
        json={
            "company": "Camlin",
            "category": "Pens",
            "item_name": f"Blue Pen {item_suffix}",
            "item_code": f"PEN-{item_suffix}",
            "default_selling_price_excl_tax": "100.00",
            "default_gst_rate": "18.00",
            "quantity_on_hand": "5.000",
            "low_stock_threshold": "2.000",
        },
    )
    assert product.status_code == 201
    invoice = client.post(
        "/invoices",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "seller_id": seller.json()["id"],
            "invoice_date": "2026-04-19",
            "payment_mode": "CREDIT",
            "place_of_supply_state_code": "27",
            "items": [
                {
                    "product_id": product.json()["id"],
                    "quantity": "2.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                }
            ],
        },
    )
    assert invoice.status_code == 201
    return {
        "seller_name": seller_name,
        "seller_id": seller.json()["id"],
        "product_id": product.json()["id"],
        "invoice": invoice.json()["invoice"],
    }


def test_cancel_invoice_is_idempotent_and_reverses_stock_and_credit(client, auth_headers):
    created = _create_credit_invoice(client, auth_headers)
    payload = {"request_id": str(uuid4()), "cancel_reason": "Wrong quantity"}

    first = client.post(f"/invoices/{created['invoice']['id']}/cancel", headers=auth_headers, json=payload)
    second = client.post(f"/invoices/{created['invoice']['id']}/cancel", headers=auth_headers, json=payload)

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["invoice"]["status"] == "CANCELED"

    product = client.get(f"/products/{created['product_id']}", headers=auth_headers)
    assert product.status_code == 200
    assert product.json()["quantity_on_hand"] == "5.000"

    ledger = client.get(f"/sellers/{created['seller_id']}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    assert [entry["entry_type"] for entry in ledger.json()["transactions"]] == ["CREDIT_SALE", "INVOICE_CANCEL_REVERSAL"]


def test_cancel_with_new_request_after_completion_returns_already_canceled(client, auth_headers):
    created = _create_credit_invoice(client, auth_headers)
    first = client.post(
        f"/invoices/{created['invoice']['id']}/cancel",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "cancel_reason": "Wrong quantity"},
    )
    assert first.status_code == 200

    response = client.post(
        f"/invoices/{created['invoice']['id']}/cancel",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "cancel_reason": "Another try"},
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "INVOICE_ALREADY_CANCELED"


def test_invoice_list_filters_work(client, auth_headers):
    first = _create_credit_invoice(client, auth_headers)
    second = _create_credit_invoice(client, auth_headers)

    canceled = client.post(
        f"/invoices/{second['invoice']['id']}/cancel",
        headers=auth_headers,
        json={"request_id": str(uuid4()), "cancel_reason": "Wrong quantity"},
    )
    assert canceled.status_code == 200

    response = client.get(
        f"/invoices?from_date=2026-04-01&to_date=2026-04-30&status=ACTIVE&payment_mode=CREDIT&invoice_number={first['invoice']['invoice_number']}",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert len(response.json()["invoices"]) == 1
    assert response.json()["invoices"][0]["id"] == first["invoice"]["id"]


def test_invoice_detail_returns_persisted_snapshots(client, auth_headers):
    created = _create_credit_invoice(client, auth_headers)
    response = client.get(f"/invoices/{created['invoice']['id']}", headers=auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["seller_snapshot"]["name"] == created["seller_name"]
    assert body["company_snapshot"]["name"] == "Acme Traders"
    assert body["items"][0]["line_number"] == 1
    assert body["items"][0]["cgst_rate"] == "9.00"
    assert body["items"][0]["sgst_rate"] == "9.00"
