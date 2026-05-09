def _product_payload(**overrides):
    payload = {
        "item_number": "PEN-001",
        "company_name": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "buying_price": "8.00",
        "selling_price": "12.00",
        "unit": None,
        "gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000",
    }
    payload.update(overrides)
    return payload


def test_create_product_requires_auth_and_creates_opening_stock_movement(client, auth_headers):
    payload = _product_payload()
    unauthorized = client.post("/products", json=payload)
    assert unauthorized.status_code == 401

    created = client.post("/products", headers=auth_headers, json=payload)
    assert created.status_code == 201
    body = created.json()
    assert body["item_number"] == "PEN-001"
    assert body["company_name"] == "Camlin"
    assert body["buying_price"] == "8.00"
    assert body["selling_price"] == "12.00"
    assert body["unit"] is None
    assert body["gst_rate"] == "18.00"
    assert body["quantity_on_hand"] == "5.000"
    assert body["low_stock_threshold"] == "2.000"
    assert body["is_active"] is True
    assert "item_code" not in body


def test_create_product_does_not_require_old_item_code(client, auth_headers):
    created = client.post("/products", headers=auth_headers, json=_product_payload())

    assert created.status_code == 201


def test_product_uniqueness_rules_and_filters(client, auth_headers):
    created = client.post("/products", headers=auth_headers, json=_product_payload(low_stock_threshold="10.000"))
    assert created.status_code == 201

    duplicate_number = client.post(
        "/products",
        headers=auth_headers,
        json=_product_payload(
            company_name="Camlin",
            category="Markers",
            item_name="Black Marker",
            selling_price="15.00",
            quantity_on_hand="0.000",
            low_stock_threshold="1.000",
        ),
    )
    assert duplicate_number.status_code == 409

    duplicate_identity = client.post(
        "/products",
        headers=auth_headers,
        json=_product_payload(item_number="PEN-002", quantity_on_hand="0.000", low_stock_threshold="1.000"),
    )
    assert duplicate_identity.status_code == 409

    filtered = client.get("/products?company_name=Camlin&category=Pens&search=PEN-001&active=true&low_stock_only=true", headers=auth_headers)
    assert filtered.status_code == 200
    body = filtered.json()
    assert len(body) == 1
    assert body[0]["item_number"] == "PEN-001"


def test_update_product_rejects_blind_stock_rewrite(client, auth_headers):
    created = client.post("/products", headers=auth_headers, json=_product_payload())
    product_id = created.json()["id"]

    response = client.put(f"/products/{product_id}", headers=auth_headers, json={"quantity_on_hand": "99.000"})
    assert response.status_code == 400


def test_delete_product_archives_instead_of_removing(client, auth_headers):
    created = client.post("/products", headers=auth_headers, json=_product_payload())
    product_id = created.json()["id"]

    deleted = client.delete(f"/products/{product_id}", headers=auth_headers)
    assert deleted.status_code == 200
    assert deleted.json()["is_active"] is False

    inactive = client.get("/products?active=false", headers=auth_headers)
    assert inactive.status_code == 200
    assert [product["id"] for product in inactive.json()] == [product_id]
