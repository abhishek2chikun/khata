import pytest
from uuid import uuid4


def _company_payload():
    return {
        "name": "Wholesaler E2E Co",
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


def test_wholesaler_end_to_end_creates_buyer_product_customer_invoice_collection_analytics(
    client, auth_headers
):
    company = client.put("/company-profile", headers=auth_headers, json=_company_payload())
    assert company.status_code == 200

    buyer = client.post(
        "/buyers",
        headers=auth_headers,
        json={"name": "Camlin Distributors", "address": "Mumbai"},
    )
    assert buyer.status_code == 201
    buyer_id = buyer.json()["id"]

    product_payload = {
        "company_name": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_number": "PEN-E2E-001",
        "buying_price": "80.00",
        "selling_price": "118.00",
        "gst_rate": "18.00",
        "quantity_on_hand": "50.000",
        "low_stock_threshold": "5.000",
        "buyer_id": buyer_id,
    }
    product = client.post("/products", headers=auth_headers, json=product_payload)
    assert product.status_code == 201
    product_id = product.json()["id"]

    customer_payload = {
        "name": "ABC Stores",
        "address": "Market Yard",
        "phone": "9876543210",
        "gstin": "27BBBBB0000B1Z5",
        "state": "Maharashtra",
        "state_code": "27",
    }
    customer = client.post("/customers", headers=auth_headers, json=customer_payload)
    assert customer.status_code == 201
    customer_id = customer.json()["id"]

    invoice_payload = {
        "request_id": str(uuid4()),
        "customer_id": customer_id,
        "invoice_date": "2026-05-10",
        "payment_state": "PARTIAL_PAID",
        "paid_amount": "150.00",
        "place_of_supply_state_code": "27",
        "items": [
            {
                "product_id": product_id,
                "quantity": "3.000",
                "pricing_mode": "TAX_INCLUSIVE",
                "unit_price": "130.00",
                "gst_rate": "18.00",
                "discount_percent": "0.00",
            }
        ],
    }

    quote = client.post("/invoices/quote", headers=auth_headers, json=invoice_payload)
    assert quote.status_code == 200
    assert quote.json()["tax_regime"] == "INTRA_STATE"
    assert quote.json()["totals"]["grand_total"] == "390.00"

    created = client.post("/invoices", headers=auth_headers, json=invoice_payload)
    assert created.status_code == 201
    invoice_body = created.json()
    invoice_id = invoice_body["invoice"]["id"]

    assert invoice_body["invoice"]["status"] == "ACTIVE"
    assert invoice_body["invoice"]["payment_state"] == "PARTIAL_PAID"
    assert invoice_body["invoice"]["paid_amount"] == "150.00"
    assert invoice_body["invoice"]["grand_total"] == "390.00"
    assert invoice_body["invoice"]["customer_snapshot"]["id"] == customer_id
    assert invoice_body["invoice"]["company_snapshot"]["name"] == "Wholesaler E2E Co"

    product_after = client.get(f"/products/{product_id}", headers=auth_headers)
    assert product_after.status_code == 200
    assert product_after.json()["quantity_on_hand"] == "47.000"

    ledger = client.get(f"/customers/{customer_id}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    assert ledger.json()["customer"]["pending_balance"] == "240.00"

    txn_types = [t["entry_type"] for t in ledger.json()["transactions"]]
    assert "CREDIT_SALE" in txn_types
    assert "COLLECTION" in txn_types

    credit_sale = next(
        t for t in ledger.json()["transactions"] if t["entry_type"] == "CREDIT_SALE"
    )
    assert float(credit_sale["amount"]) == pytest.approx(390.00)

    partial_collection = next(
        t for t in ledger.json()["transactions"] if t["entry_type"] == "COLLECTION"
    )
    assert float(partial_collection["amount"]) == pytest.approx(150.00)

    collection = client.post(
        "/collections",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "customer_id": customer_id,
            "amount": "100.00",
            "occurred_on": "2026-05-11",
            "notes": "Cash collection",
        },
    )
    assert collection.status_code == 201

    ledger_after = client.get(f"/customers/{customer_id}/ledger", headers=auth_headers)
    assert ledger_after.status_code == 200
    assert float(ledger_after.json()["customer"]["pending_balance"]) == pytest.approx(
        140.00
    )

    customer_detail = client.get(f"/customers/{customer_id}", headers=auth_headers)
    assert customer_detail.status_code == 200
    assert float(customer_detail.json()["pending_balance"]) == pytest.approx(140.00)

    dashboard = client.get("/analytics/dashboard", headers=auth_headers)
    assert dashboard.status_code == 200

    dashboard_data = dashboard.json()
    assert isinstance(dashboard_data["revenue_by_company"], list)
    assert isinstance(dashboard_data["profit_by_company"], list)
    assert isinstance(dashboard_data["customer_khata_balances"], list)
    assert isinstance(dashboard_data["buyer_pending_payables"], list)

    camlin_revenue = [
        r for r in dashboard_data["revenue_by_company"] if r.get("name") == "Camlin"
    ]
    assert len(camlin_revenue) == 1
    assert float(camlin_revenue[0]["revenue"]) == pytest.approx(390.00)

    camlin_profit = [
        p for p in dashboard_data["profit_by_company"] if p.get("name") == "Camlin"
    ]
    assert len(camlin_profit) == 1
    assert float(camlin_profit[0]["profit"]) == pytest.approx(390.00 - (80 * 3))

    abc_balance = [
        b
        for b in dashboard_data["customer_khata_balances"]
        if b.get("customer_name") == "ABC Stores"
    ]
    assert len(abc_balance) == 1
    assert float(abc_balance[0]["balance"]) == pytest.approx(140.00)

    buyer_opening = client.post(
        f"/buyers/{buyer_id}/opening-payable",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "amount": "5000.00",
            "occurred_at": "2026-05-01T00:00:00Z",
        },
    )
    assert buyer_opening.status_code == 201

    buyer_payment = client.post(
        f"/buyers/{buyer_id}/payments-made",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "amount": "2000.00",
            "occurred_at": "2026-05-05T00:00:00Z",
        },
    )
    assert buyer_payment.status_code == 201

    buyer_ledger = client.get(f"/buyers/{buyer_id}/ledger", headers=auth_headers)
    assert buyer_ledger.status_code == 200
    assert float(buyer_ledger.json()["buyer"]["pending_payable"]) == pytest.approx(
        3000.00
    )

    dashboard_final = client.get("/analytics/dashboard", headers=auth_headers)
    assert dashboard_final.status_code == 200
    supplier_payable = [
        p
        for p in dashboard_final.json()["buyer_pending_payables"]
        if p.get("buyer_name") == "Camlin Distributors"
    ]
    assert len(supplier_payable) == 1
    assert float(supplier_payable[0]["payable"]) == pytest.approx(3000.00)

    top_products = dashboard_final.json()["top_products_by_quantity"]
    blue_pen = [p for p in top_products if p.get("product_name") == "Blue Pen"]
    assert len(blue_pen) == 1
    assert float(blue_pen[0]["quantity"]) == pytest.approx(3.0)
