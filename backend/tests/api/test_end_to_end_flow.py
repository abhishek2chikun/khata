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


def _seller_payload() -> dict:
    return {
        "name": "ABC Stores",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
        "state": "Maharashtra",
        "state_code": "27",
    }


def _product_payload() -> dict:
    return {
        "company": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_code": "PEN-001",
        "default_selling_price_excl_tax": "100.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000",
    }


def test_credit_sale_payment_flow_updates_invoice_stock_and_ledger(client, auth_headers):
    company = client.put("/company-profile", headers=auth_headers, json=_company_payload())
    assert company.status_code == 200

    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload())
    assert seller.status_code == 201
    seller_id = seller.json()["id"]

    product = client.post("/products", headers=auth_headers, json=_product_payload())
    assert product.status_code == 201
    product_id = product.json()["id"]

    invoice_payload = {
        "request_id": str(uuid4()),
        "seller_id": seller_id,
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "items": [
            {
                "product_id": product_id,
                "quantity": "2.000",
                "pricing_mode": "PRE_TAX",
                "unit_price": "100.00",
                "gst_rate": "18.00",
                "discount_percent": "0.00",
            }
        ],
    }

    quote = client.post("/invoices/quote", headers=auth_headers, json=invoice_payload)
    assert quote.status_code == 200
    assert quote.json()["tax_regime"] == "INTRA_STATE"
    assert quote.json()["totals"]["grand_total"] == "236.00"
    assert quote.json()["warnings"] == []

    created = client.post("/invoices", headers=auth_headers, json=invoice_payload)
    assert created.status_code == 201
    created_body = created.json()
    invoice_id = created_body["invoice"]["id"]
    invoice_number = created_body["invoice"]["invoice_number"]

    assert created_body["invoice"]["status"] == "ACTIVE"
    assert created_body["invoice"]["payment_mode"] == "CREDIT"
    assert created_body["invoice"]["grand_total"] == "236.00"
    assert created_body["invoice"]["seller_snapshot"]["id"] == seller_id
    assert created_body["invoice"]["company_snapshot"]["name"] == "Acme Traders"
    assert created_body["invoice"]["items"][0]["product_id"] == product_id
    assert created_body["invoice"]["items"][0]["quantity"] == "2.000"

    invoice_list = client.get("/invoices?seller_id=" + seller_id + "&payment_mode=CREDIT&status=ACTIVE", headers=auth_headers)
    assert invoice_list.status_code == 200
    assert invoice_list.json()["invoices"] == [
        {
            "id": invoice_id,
            "invoice_number": invoice_number,
            "seller_id": seller_id,
            "seller_name": "ABC Stores",
            "invoice_date": "2026-04-19",
            "status": "ACTIVE",
            "payment_mode": "CREDIT",
            "grand_total": "236.00",
        }
    ]

    invoice_detail = client.get(f"/invoices/{invoice_id}", headers=auth_headers)
    assert invoice_detail.status_code == 200
    assert invoice_detail.json()["items"][0]["line_total"] == "236.00"

    product_detail = client.get(f"/products/{product_id}", headers=auth_headers)
    assert product_detail.status_code == 200
    assert product_detail.json()["quantity_on_hand"] == "3.000"

    ledger_after_sale = client.get(f"/sellers/{seller_id}/ledger", headers=auth_headers)
    assert ledger_after_sale.status_code == 200
    assert ledger_after_sale.json()["seller"]["pending_balance"] == "236.00"
    assert ledger_after_sale.json()["transactions"] == [
        {
            "id": ledger_after_sale.json()["transactions"][0]["id"],
            "entry_type": "CREDIT_SALE",
            "amount": "236.00",
            "occurred_on": "2026-04-19",
            "notes": f"Invoice {invoice_number}",
        }
    ]
    assert ledger_after_sale.json()["invoices"] == [
        {
            "invoice_id": invoice_id,
            "invoice_number": str(invoice_number),
            "invoice_date": "2026-04-19",
            "grand_total": "236.00",
            "payment_mode": "CREDIT",
            "status": "ACTIVE",
        }
    ]

    payment = client.post(
        "/payments",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "seller_id": seller_id,
            "amount": "100.00",
            "occurred_on": "2026-04-20",
            "notes": "Cash collection",
        },
    )
    assert payment.status_code == 201
    assert payment.json()["entry_type"] == "PAYMENT"
    assert payment.json()["amount"] == "100.00"
    assert payment.json()["occurred_on"] == "2026-04-20"
    assert payment.json()["notes"] == "Cash collection"

    seller_detail = client.get(f"/sellers/{seller_id}", headers=auth_headers)
    assert seller_detail.status_code == 200
    assert seller_detail.json()["pending_balance"] == "136.00"

    ledger_after_payment = client.get(f"/sellers/{seller_id}/ledger", headers=auth_headers)
    assert ledger_after_payment.status_code == 200
    assert ledger_after_payment.json()["seller"]["pending_balance"] == "136.00"
    assert [entry["entry_type"] for entry in ledger_after_payment.json()["transactions"]] == ["CREDIT_SALE", "PAYMENT"]
    assert [entry["amount"] for entry in ledger_after_payment.json()["transactions"]] == ["236.00", "100.00"]
    assert ledger_after_payment.json()["transactions"][1]["occurred_on"] == "2026-04-20"
    assert ledger_after_payment.json()["transactions"][1]["notes"] == "Cash collection"
