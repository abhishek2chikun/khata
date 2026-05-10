from uuid import uuid4


def _company_payload() -> dict:
    return {
        "name": "Acme Traders",
        "address": "Main Road",
        "city": "Pune",
        "state": "Maharashtra",
        "state_code": "27",
    }


def _customer_payload() -> dict:
    return {
        "name": f"ABC Stores {uuid4()}",
        "address": "Market Yard",
        "state": "Maharashtra",
        "state_code": "27",
    }


def _product_payload() -> dict:
    suffix = str(uuid4())
    return {
        "company_name": "Camlin",
        "category": "Pens",
        "item_name": f"Blue Pen {suffix}",
        "item_number": f"PEN-{suffix}",
        "buying_price": "70.00",
        "selling_price": "118.00",
        "gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000",
        "unit": "box",
    }


def _seed_invoice_inputs(client, auth_headers):
    company = client.put("/company-profile", headers=auth_headers, json=_company_payload())
    assert company.status_code == 200
    customer = client.post("/customers", headers=auth_headers, json=_customer_payload())
    assert customer.status_code == 201
    product = client.post("/products", headers=auth_headers, json=_product_payload())
    assert product.status_code == 201
    return customer.json(), product.json()


def test_invoice_v2_quote_defaults_to_product_price_and_snapshots_product(client, auth_headers):
    customer, product = _seed_invoice_inputs(client, auth_headers)

    response = client.post(
        "/invoices/quote",
        headers=auth_headers,
        json={
            "customer_id": customer["id"],
            "payment_state": "CREDIT",
            "place_of_supply_state_code": "27",
            "items": [{"product_id": product["id"], "quantity": "2.000"}],
        },
    )

    assert response.status_code == 200
    line = response.json()["items"][0]
    assert line["pricing_mode"] == "TAX_INCLUSIVE"
    assert line["entered_unit_price"] == "118.00"
    assert line["product_item_number"] == product["item_number"]
    assert line["buying_price"] == "70.00"
    assert line["profit_amount"] == "60.00"


def test_invoice_v2_total_paid_debits_and_collects_customer_khata(client, auth_headers):
    customer, product = _seed_invoice_inputs(client, auth_headers)

    response = client.post(
        "/invoices",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "customer_id": customer["id"],
            "invoice_datetime": "2026-04-19T15:30:00Z",
            "payment_state": "TOTAL_PAID",
            "paid_amount": "236.00",
            "place_of_supply_state_code": "27",
            "items": [{"product_id": product["id"], "quantity": "2.000"}],
        },
    )

    assert response.status_code == 201
    invoice = response.json()["invoice"]
    assert invoice["payment_state"] == "TOTAL_PAID"
    assert invoice["paid_amount"] == "236.00"
    assert invoice["invoice_datetime"].startswith("2026-04-19T15:30:00")

    ledger = client.get(f"/customers/{customer['id']}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    assert [(entry["entry_type"], entry["amount"]) for entry in ledger.json()["transactions"]] == [
        ("CREDIT_SALE", "236.00"),
        ("COLLECTION", "236.00"),
    ]
