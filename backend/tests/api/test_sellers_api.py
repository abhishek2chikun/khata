def test_seller_crud_and_archive_behavior(client, auth_headers):
    create = client.post(
        "/sellers",
        headers=auth_headers,
        json={
            "name": "ABC Stores",
            "address": "Market Yard",
            "phone": "9999999999",
            "gstin": "27BBBBB0000B1Z5",
        },
    )
    assert create.status_code == 201
    seller_id = create.json()["id"]

    detail = client.get(f"/sellers/{seller_id}", headers=auth_headers)
    assert detail.status_code == 200

    listing = client.get("/sellers", headers=auth_headers)
    assert listing.status_code == 200

    updated = client.put(
        f"/sellers/{seller_id}",
        headers=auth_headers,
        json={
            "name": "ABC Stores",
            "address": "Updated Address",
            "phone": "9999999999",
            "gstin": "27BBBBB0000B1Z5",
        },
    )
    assert updated.status_code == 200

    archived = client.delete(f"/sellers/{seller_id}", headers=auth_headers)
    assert archived.status_code == 200


def test_create_seller_rejects_duplicate_name_phone(client, auth_headers):
    payload = {
        "name": "ABC Stores",
        "address": "Market Yard",
        "phone": "9999999999",
        "gstin": "27BBBBB0000B1Z5",
    }
    first = client.post("/sellers", headers=auth_headers, json=payload)
    assert first.status_code == 201

    second = client.post("/sellers", headers=auth_headers, json=payload)
    assert second.status_code == 409
