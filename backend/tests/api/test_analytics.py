from datetime import date
from uuid import uuid4

import pytest


def _seed_full_flow(client, auth_headers):
    company_payload = {
        "name": "Analytics Co",
        "address": "Main Road",
        "city": "Pune",
        "state": "Maharashtra",
        "state_code": "27",
    }
    company_resp = client.put("/company-profile", headers=auth_headers, json=company_payload)
    assert company_resp.status_code == 200

    customer_payload = {"name": f"Analytics Cust {uuid4()}", "address": "Market"}
    customer_resp = client.post("/customers", headers=auth_headers, json=customer_payload)
    assert customer_resp.status_code == 201
    customer = customer_resp.json()

    buyer_payload = {"name": f"Analytics Buyer {uuid4()}"}
    buyer_resp = client.post("/buyers", headers=auth_headers, json=buyer_payload)
    assert buyer_resp.status_code == 201
    buyer = buyer_resp.json()

    product_payload = {
        "company_name": "TestCo",
        "category": "AnalyticsCat",
        "item_name": f"Analytics Prod {uuid4()}",
        "item_number": f"AP-{uuid4()}",
        "buying_price": "50.00",
        "selling_price": "100.00",
        "gst_rate": "0.00",
        "quantity_on_hand": "10.000",
        "low_stock_threshold": "2.000",
        "buyer_id": buyer["id"],
    }
    product_resp = client.post("/products", headers=auth_headers, json=product_payload)
    assert product_resp.status_code == 201
    product = product_resp.json()

    invoice_resp = client.post(
        "/invoices",
        headers=auth_headers,
        json={
            "request_id": str(uuid4()),
            "customer_id": customer["id"],
            "invoice_datetime": "2026-04-20T10:00:00Z",
            "payment_state": "CREDIT",
            "place_of_supply_state_code": "27",
            "items": [{"product_id": product["id"], "quantity": "2.000"}],
        },
    )
    assert invoice_resp.status_code == 201

    return customer, buyer, product


def test_analytics_endpoint_returns_all_dashboard_sections(client, auth_headers):
    _seed_full_flow(client, auth_headers)

    response = client.get("/analytics/dashboard", headers=auth_headers)
    assert response.status_code == 200

    data = response.json()
    expected_keys = [
        "revenue_by_buyer",
        "profit_by_buyer",
        "revenue_by_company",
        "profit_by_company",
        "revenue_by_customer",
        "customer_khata_balances",
        "buyer_pending_payables",
        "top_products_by_quantity",
        "top_products_by_revenue",
        "top_products_by_profit",
        "low_stock",
    ]
    for key in expected_keys:
        assert key in data, f"Missing dashboard section: {key}"


def test_analytics_date_filters_work(client, auth_headers):
    _seed_full_flow(client, auth_headers)

    response = client.get(
        "/analytics/dashboard",
        headers=auth_headers,
        params={"from_date": "2026-04-01", "to_date": "2026-04-30"},
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data["revenue_by_buyer"], list)

    response_empty = client.get(
        "/analytics/dashboard",
        headers=auth_headers,
        params={"from_date": "2025-01-01", "to_date": "2025-12-31"},
    )
    assert response_empty.status_code == 200
    empty_data = response_empty.json()
    total_rev = sum(b.get("revenue", 0) for b in empty_data["revenue_by_buyer"])
    assert total_rev == 0


def test_analytics_empty_data_returns_zeros_and_empty_lists(client, auth_headers):
    response = client.get("/analytics/dashboard", headers=auth_headers)
    assert response.status_code == 200

    data = response.json()
    assert data["revenue_by_buyer"] == []
    assert data["profit_by_buyer"] == []
    assert data["revenue_by_company"] == []
    assert data["profit_by_company"] == []
    assert data["revenue_by_customer"] == []
    assert data["customer_khata_balances"] == []
    assert data["buyer_pending_payables"] == []
    assert data["top_products_by_quantity"] == []
    assert data["top_products_by_revenue"] == []
    assert data["top_products_by_profit"] == []
    assert data["low_stock"] == []
