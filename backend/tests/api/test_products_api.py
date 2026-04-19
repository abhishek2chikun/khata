def test_create_product_requires_auth_and_creates_opening_stock_movement(client, auth_headers):
    payload = {
        "company": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_code": "PEN-001",
        "default_selling_price_excl_tax": "10.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000",
    }
    unauthorized = client.post("/products", json=payload)
    assert unauthorized.status_code == 401

    created = client.post("/products", headers=auth_headers, json=payload)
    assert created.status_code == 201
    body = created.json()
    assert body["item_code"] == "PEN-001"
    assert body["quantity_on_hand"] == "5.000"


def test_product_uniqueness_rules_and_filters(client, auth_headers):
    payload = {
        "company": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_code": "PEN-001",
        "default_selling_price_excl_tax": "10.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "10.000",
    }
    created = client.post("/products", headers=auth_headers, json=payload)
    assert created.status_code == 201

    duplicate_code = client.post(
        "/products",
        headers=auth_headers,
        json={
            "company": "Camlin",
            "category": "Markers",
            "item_name": "Black Marker",
            "item_code": "PEN-001",
            "default_selling_price_excl_tax": "15.00",
            "default_gst_rate": "18.00",
            "quantity_on_hand": "0.000",
            "low_stock_threshold": "1.000",
        },
    )
    assert duplicate_code.status_code == 409

    duplicate_name = client.post(
        "/products",
        headers=auth_headers,
        json={
            "company": "Camlin",
            "category": "Pens",
            "item_name": "Blue Pen",
            "item_code": "PEN-002",
            "default_selling_price_excl_tax": "10.00",
            "default_gst_rate": "18.00",
            "quantity_on_hand": "0.000",
            "low_stock_threshold": "1.000",
        },
    )
    assert duplicate_name.status_code == 409

    filtered = client.get("/products?company=Camlin&category=Pens&search=Blue&active=true&low_stock_only=true", headers=auth_headers)
    assert filtered.status_code == 200
    assert len(filtered.json()) == 1


def test_update_product_rejects_blind_stock_rewrite(client, auth_headers):
    payload = {
        "company": "Camlin",
        "category": "Pens",
        "item_name": "Blue Pen",
        "item_code": "PEN-001",
        "default_selling_price_excl_tax": "10.00",
        "default_gst_rate": "18.00",
        "quantity_on_hand": "5.000",
        "low_stock_threshold": "2.000",
    }
    created = client.post("/products", headers=auth_headers, json=payload)
    product_id = created.json()["id"]

    response = client.put(f"/products/{product_id}", headers=auth_headers, json={"quantity_on_hand": "99.000"})
    assert response.status_code == 400
