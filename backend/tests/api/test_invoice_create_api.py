from uuid import uuid4


def _company_payload(state: str = "Maharashtra", state_code: str = "27") -> dict:
    return {
        "name": "Acme Traders",
        "address": "Main Road",
        "city": "Pune",
        "state": state,
        "state_code": state_code,
        "gstin": "27AAAAA0000A1Z5",
        "phone": "9999999999",
        "email": "owner@example.com",
        "bank_name": "ABC Bank",
        "bank_account": "1234567890",
        "bank_ifsc": "ABC0001234",
        "bank_branch": "Pune",
        "jurisdiction": "Pune",
    }


def _seller_payload(state: str | None = None, state_code: str | None = None) -> dict:
    payload = {
        "name": "ABC Stores",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
    }
    if state is not None:
        payload["state"] = state
    if state_code is not None:
        payload["state_code"] = state_code
    return payload


def _product_payload(item_code: str = "PEN-001", quantity: str = "5.000") -> dict:
    return {
        "company": "Camlin",
        "category": "Pens",
        "item_name": f"Blue Pen {item_code}",
        "item_code": item_code,
        "default_selling_price_excl_tax": "100.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": quantity,
        "low_stock_threshold": "2.000",
    }


def _invoice_payload(seller_id: str, product_id: str, request_id: str | None = None, **overrides) -> dict:
    payload = {
        "request_id": request_id or str(uuid4()),
        "seller_id": seller_id,
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "place_of_supply_state_code": "27",
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
    payload.update(overrides)
    return payload


def test_quote_requires_company_profile_state_and_returns_totals(client, auth_headers):
    company = client.put("/company-profile", headers=auth_headers, json=_company_payload())
    assert company.status_code == 200

    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="27"))
    product = client.post("/products", headers=auth_headers, json=_product_payload())

    response = client.post(
        "/invoices/quote",
        headers=auth_headers,
        json=_invoice_payload(seller.json()["id"], product.json()["id"]),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["totals"]["grand_total"] == "236.00"
    assert body["warnings"] == []


def test_quote_rejects_missing_or_unresolved_tax_state_inputs(client, auth_headers):
    company = client.put("/company-profile", headers=auth_headers, json=_company_payload())
    assert company.status_code == 200

    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload())
    product = client.post("/products", headers=auth_headers, json=_product_payload())

    payload = _invoice_payload(seller.json()["id"], product.json()["id"])
    payload.pop("place_of_supply_state_code")

    response = client.post("/invoices/quote", headers=auth_headers, json=payload)
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_quote_rejects_inconsistent_seller_state_name_and_code(client, auth_headers):
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="29"))
    product = client.post("/products", headers=auth_headers, json=_product_payload())

    payload = _invoice_payload(seller.json()["id"], product.json()["id"])
    payload.pop("place_of_supply_state_code")

    response = client.post("/invoices/quote", headers=auth_headers, json=payload)
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_create_credit_invoice_is_atomic_and_idempotent(client, auth_headers):
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="27"))
    product = client.post("/products", headers=auth_headers, json=_product_payload())
    request_id = str(uuid4())
    payload = _invoice_payload(seller.json()["id"], product.json()["id"], request_id=request_id)

    first = client.post("/invoices", headers=auth_headers, json=payload)
    second = client.post("/invoices", headers=auth_headers, json=payload)

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["invoice"]["id"] == first.json()["invoice"]["id"]


def test_paid_invoice_creates_no_credit_ledger_row(client, auth_headers):
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="27"))
    product = client.post("/products", headers=auth_headers, json=_product_payload())
    payload = _invoice_payload(seller.json()["id"], product.json()["id"], payment_mode="PAID")

    response = client.post("/invoices", headers=auth_headers, json=payload)
    assert response.status_code == 201

    ledger = client.get(f"/sellers/{seller.json()['id']}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    assert ledger.json()["transactions"] == []


def test_invoice_create_rolls_back_on_internal_failure(client, auth_headers, monkeypatch):
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="27"))
    product = client.post("/products", headers=auth_headers, json=_product_payload())
    payload = _invoice_payload(seller.json()["id"], product.json()["id"])

    def explode(*args, **kwargs):
        raise RuntimeError("boom")

    monkeypatch.setattr("app.services.invoice_service._insert_invoice_items", explode, raising=False)
    response = client.post("/invoices", headers=auth_headers, json=payload)

    assert response.status_code == 500

    products = client.get("/products", headers=auth_headers)
    assert products.status_code == 200
    assert products.json()[0]["quantity_on_hand"] == "5.000"


def test_negative_stock_warning_is_returned_on_create(client, auth_headers):
    client.put("/company-profile", headers=auth_headers, json=_company_payload())
    seller = client.post("/sellers", headers=auth_headers, json=_seller_payload(state="Maharashtra", state_code="27"))
    product = client.post("/products", headers=auth_headers, json=_product_payload(quantity="1.000"))
    payload = _invoice_payload(seller.json()["id"], product.json()["id"])
    payload["items"][0]["quantity"] = "999.000"

    response = client.post("/invoices", headers=auth_headers, json=payload)
    assert response.status_code == 201
    assert response.json()["warnings"]
