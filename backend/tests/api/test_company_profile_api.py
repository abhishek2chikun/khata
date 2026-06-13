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


def test_company_profile_round_trips_gst_flag(client, auth_headers):
    created_false = client.put(
        "/company-profile",
        headers=auth_headers,
        json={
            "name": "Non GST Shop",
            "address": "Lane 1",
            "city": "Pune",
            "state": "Maharashtra",
            "state_code": "27",
            "gst_flag": False,
        },
    )
    assert created_false.status_code == 200
    assert created_false.json()["gst_flag"] is False

    created_true = client.put(
        "/company-profile",
        headers=auth_headers,
        json={
            "name": "GST Shop",
            "address": "Lane 2",
            "city": "Pune",
            "state": "Maharashtra",
            "state_code": "27",
            "gstin": "27AAAAA0000A1Z5",
            "gst_flag": True,
        },
    )
    assert created_true.status_code == 200
    body = created_true.json()
    assert body["gst_flag"] is True

    fetched = client.get("/company-profile", headers=auth_headers)
    assert fetched.status_code == 200
    assert fetched.json()["gst_flag"] is True
