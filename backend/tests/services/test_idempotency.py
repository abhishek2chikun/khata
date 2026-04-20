from app.core.idempotency import canonical_request_hash


def test_same_invoice_payload_hashes_identically_across_retries():
    payload = {
        "seller_id": "seller-1",
        "invoice_date": "2026-04-19",
        "items": [
            {
                "product_id": "p1",
                "quantity": "2.000",
                "pricing_mode": "PRE_TAX",
                "unit_price": "100.00",
                "gst_rate": "18.00",
                "discount_percent": "0.00",
            }
        ],
    }
    same_payload_different_key_order = {
        "invoice_date": "2026-04-19",
        "items": [
            {
                "discount_percent": "0.00",
                "gst_rate": "18.00",
                "pricing_mode": "PRE_TAX",
                "product_id": "p1",
                "quantity": "2.000",
                "unit_price": "100.00",
            }
        ],
        "seller_id": "seller-1",
    }

    assert canonical_request_hash(payload) == canonical_request_hash(same_payload_different_key_order)


def test_invoice_item_order_is_part_of_canonical_request_hash():
    payload = {
        "items": [
            {"product_id": "p1", "quantity": "1.000", "discount_percent": "0.00"},
            {"product_id": "p2", "quantity": "1.000", "discount_percent": "0.00"},
        ]
    }
    reordered = {
        "items": [
            {"product_id": "p2", "quantity": "1.000", "discount_percent": "0.00"},
            {"product_id": "p1", "quantity": "1.000", "discount_percent": "0.00"},
        ]
    }

    assert canonical_request_hash(payload) != canonical_request_hash(reordered)
