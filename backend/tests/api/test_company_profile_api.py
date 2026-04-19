def test_company_profile_create_get_and_error_envelope(client, auth_headers):
    invalid = client.post("/products", headers=auth_headers, json={})
    assert invalid.status_code == 400
    assert invalid.json()["error"]["code"] == "VALIDATION_ERROR"

    created = client.put(
        "/company-profile",
        headers=auth_headers,
        json={
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
        },
    )
    assert created.status_code == 200

    fetched = client.get("/company-profile", headers=auth_headers)
    assert fetched.status_code == 200
    assert fetched.json()["name"] == "Acme Traders"
