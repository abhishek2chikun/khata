from datetime import datetime, timezone
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException
from sqlalchemy import select

from app.models.buyer import Buyer
from app.models.company_profile import CompanyProfile
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.product import Product
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.schemas.invoice import InvoiceCancelRequest, InvoiceCreateRequest, InvoiceQuoteRequest
from app.services import invoice_service

from app.core.idempotency import canonical_request_hash


def _seed_invoice_v2_graph(db_session):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name=f"ABC Stores {uuid4()}", address="Market Yard", state="Maharashtra", state_code="27")
    buyer = Buyer(name=f"Camlin Supplier {uuid4()}", address="Supplier Lane")
    product = Product(
        company_name="Camlin",
        category="Pens",
        item_name=f"Blue Pen {uuid4()}",
        item_number=f"PEN-{uuid4()}",
        buyer_id=buyer.id,
        buying_price=Decimal("70.00"),
        selling_price=Decimal("118.00"),
        unit="box",
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, buyer, product])
    db_session.commit()
    return customer, buyer, product


def _v2_line(product, **overrides):
    line = {
        "product_id": product.id,
        "quantity": Decimal("2.000"),
        "discount_percent": Decimal("0.00"),
    }
    line.update(overrides)
    return line


def _v2_create_payload(customer, product, **overrides):
    payload = {
        "request_id": uuid4(),
        "customer_id": customer.id,
        "invoice_datetime": datetime(2026, 4, 19, 15, 30, tzinfo=timezone.utc),
        "payment_state": "CREDIT",
        "paid_amount": Decimal("0.00"),
        "place_of_supply_state_code": "27",
        "items": [_v2_line(product)],
    }
    payload.update(overrides)
    return InvoiceCreateRequest(**payload)


def _ledger_entries(db_session, invoice_id):
    return list(
        db_session.scalars(
            select(CustomerTransaction).where(CustomerTransaction.invoice_id == invoice_id).order_by(CustomerTransaction.created_at, CustomerTransaction.id)
        ).all()
    )


def test_invoice_request_hash_changes_when_item_order_changes():
    payload = {
        "customer_id": "customer-1",
        "invoice_date": "2026-04-19",
        "payment_mode": "CREDIT",
        "items": [
            {"product_id": "p1", "quantity": "1.000", "pricing_mode": "PRE_TAX", "unit_price": "100.00", "gst_rate": "18.00", "discount_percent": "0.00"},
            {"product_id": "p2", "quantity": "2.000", "pricing_mode": "PRE_TAX", "unit_price": "50.00", "gst_rate": "18.00", "discount_percent": "0.00"},
        ],
    }
    reordered = {
        **payload,
        "items": list(reversed(payload["items"])),
    }

    assert canonical_request_hash(payload) != canonical_request_hash(reordered)


def test_build_quote_returns_expected_totals(db_session):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company_name="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_number="PEN-001",
        buying_price=Decimal("80.00"),
        selling_price=Decimal("118.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, product])
    db_session.commit()

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product.id,
                    "quantity": "2.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                }
            ],
        ),
    )

    assert quote.totals.grand_total == Decimal("236.00")
    assert quote.place_of_supply_state == "Maharashtra"


def test_quote_defaults_to_product_selling_price_inclusive_of_gst(db_session):
    customer, _, product = _seed_invoice_v2_graph(db_session)

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            customer_id=customer.id,
            payment_state="CREDIT",
            place_of_supply_state_code="27",
            items=[_v2_line(product)],
        ),
    )

    assert quote.items[0].pricing_mode == "TAX_INCLUSIVE"
    assert quote.items[0].entered_unit_price == Decimal("118.00")
    assert quote.items[0].unit_price_excl_tax == Decimal("100.00")
    assert quote.totals.grand_total == Decimal("236.00")


def test_quote_can_override_line_selling_price(db_session):
    customer, _, product = _seed_invoice_v2_graph(db_session)

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            customer_id=customer.id,
            payment_state="CREDIT",
            place_of_supply_state_code="27",
            items=[_v2_line(product, unit_price=Decimal("236.00"))],
        ),
    )

    assert quote.items[0].entered_unit_price == Decimal("236.00")
    assert quote.items[0].unit_price_excl_tax == Decimal("200.00")
    assert quote.totals.grand_total == Decimal("472.00")


def test_quote_can_override_line_gst_rate(db_session):
    customer, _, product = _seed_invoice_v2_graph(db_session)

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            customer_id=customer.id,
            payment_state="CREDIT",
            place_of_supply_state_code="27",
            items=[_v2_line(product, gst_rate=Decimal("12.00"))],
        ),
    )

    assert quote.items[0].gst_rate == Decimal("12.00")
    assert quote.items[0].cgst_rate == Decimal("6.00")
    assert quote.items[0].sgst_rate == Decimal("6.00")


def test_quote_snapshots_product_details_and_profit_inputs(db_session):
    customer, buyer, product = _seed_invoice_v2_graph(db_session)

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            customer_id=customer.id,
            payment_state="CREDIT",
            place_of_supply_state_code="27",
            items=[_v2_line(product)],
        ),
    )

    item = quote.items[0]
    assert item.product_item_number == product.item_number
    assert item.product_item_name == product.item_name
    assert item.product_category == "Pens"
    assert item.product_buyer_id == buyer.id
    assert item.product_company_name == "Camlin"
    assert item.buying_price == Decimal("70.00")
    assert item.selling_price == Decimal("118.00")
    assert item.gst_rate == Decimal("18.00")
    assert item.unit == "box"
    assert item.revenue_amount == Decimal("200.00")
    assert item.buying_amount == Decimal("140.00")
    assert item.profit_amount == Decimal("60.00")


def test_create_credit_invoice_debits_full_amount_and_reduces_stock_and_stores_datetime(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)
    invoice_datetime = datetime(2026, 4, 19, 15, 30, tzinfo=timezone.utc)

    created = invoice_service.create_invoice(db_session, _v2_create_payload(customer, product, invoice_datetime=invoice_datetime), seeded_user)

    assert created.invoice.payment_state == "CREDIT"
    assert created.invoice.paid_amount == Decimal("0.00")
    assert created.invoice.invoice_datetime == invoice_datetime
    db_session.refresh(product)
    assert product.quantity_on_hand == Decimal("3.000")
    entries = _ledger_entries(db_session, created.invoice.id)
    assert [(entry.entry_type, entry.amount) for entry in entries] == [("CREDIT_SALE", Decimal("236.00"))]


def test_create_total_paid_invoice_debits_full_amount_and_creates_full_collection(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)

    created = invoice_service.create_invoice(db_session, _v2_create_payload(customer, product, payment_state="TOTAL_PAID", paid_amount=Decimal("236.00")), seeded_user)

    entries = _ledger_entries(db_session, created.invoice.id)
    assert [(entry.entry_type, entry.amount) for entry in entries] == [("CREDIT_SALE", Decimal("236.00")), ("COLLECTION", Decimal("236.00"))]


def test_create_partial_paid_invoice_debits_full_amount_and_creates_partial_collection(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)

    created = invoice_service.create_invoice(db_session, _v2_create_payload(customer, product, payment_state="PARTIAL_PAID", paid_amount=Decimal("100.00")), seeded_user)

    entries = _ledger_entries(db_session, created.invoice.id)
    assert [(entry.entry_type, entry.amount) for entry in entries] == [("CREDIT_SALE", Decimal("236.00")), ("COLLECTION", Decimal("100.00"))]


def test_cancel_restores_stock_reverses_customer_khata_and_is_idempotent(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)
    created = invoice_service.create_invoice(db_session, _v2_create_payload(customer, product, payment_state="PARTIAL_PAID", paid_amount=Decimal("100.00")), seeded_user)
    payload = InvoiceCancelRequest(request_id=uuid4(), cancel_reason="Wrong quantity")

    first = invoice_service.cancel_invoice(db_session, created.invoice.id, payload, seeded_user)
    second = invoice_service.cancel_invoice(db_session, created.invoice.id, payload, seeded_user)

    assert first.invoice.id == second.invoice.id
    assert second.invoice.status == "CANCELED"
    db_session.refresh(product)
    assert product.quantity_on_hand == Decimal("5.000")
    entries = _ledger_entries(db_session, created.invoice.id)
    assert [(entry.entry_type, entry.amount) for entry in entries] == [
        ("CREDIT_SALE", Decimal("236.00")),
        ("COLLECTION", Decimal("100.00")),
        ("INVOICE_CANCEL_REVERSAL", Decimal("236.00")),
        ("COLLECTION_REVERSAL", Decimal("100.00")),
    ]


def test_create_invoice_persists_invoice_items_and_credit_ledger(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company_name="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_number="PEN-001",
        buying_price=Decimal("80.00"),
        selling_price=Decimal("118.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, product])
    db_session.commit()

    created = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id="f0e3e6a2-b7d1-47b3-86e6-b1289fdf11ee",
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product.id,
                    "quantity": "2.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                }
            ],
        ),
        seeded_user,
    )

    assert created.invoice.grand_total == Decimal("236.00")
    assert len(created.invoice.items) == 1
    assert created.invoice.items[0].line_number == 1

    detail = invoice_service.get_invoice_detail(db_session, created.invoice.id)
    assert detail.items[0].product_code == "PEN-001"

    ledger = invoice_service.list_invoices(db_session)
    assert len(ledger.invoices) == 1


def test_create_invoice_retry_succeeds_after_customer_is_archived(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company_name="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_number="PEN-001",
        buying_price=Decimal("80.00"),
        selling_price=Decimal("118.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, product])
    db_session.commit()

    payload = InvoiceCreateRequest(
        request_id="318628a9-3858-4900-b83a-a6e3c7304dcb",
        customer_id=customer.id,
        invoice_date="2026-04-19",
        payment_mode="CREDIT",
        place_of_supply_state_code="27",
        items=[
            {
                "product_id": product.id,
                "quantity": "2.000",
                "pricing_mode": "PRE_TAX",
                "unit_price": "100.00",
                "gst_rate": "18.00",
                "discount_percent": "0.00",
            }
        ],
    )

    first = invoice_service.create_invoice(db_session, payload, seeded_user)
    customer.is_active = False
    db_session.commit()
    second = invoice_service.create_invoice(db_session, payload, seeded_user)

    assert first.invoice.id == second.invoice.id


def test_create_invoice_hash_normalizes_equivalent_decimal_payloads(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company_name="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_number="PEN-001",
        buying_price=Decimal("80.00"),
        selling_price=Decimal("118.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, product])
    db_session.commit()

    request_id = "d2bd51c6-c8e0-4ae1-bc7c-6d62b69943ae"
    first = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product.id,
                    "quantity": "2.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                }
            ],
        ),
        seeded_user,
    )
    second = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product.id,
                    "quantity": "2",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100",
                    "gst_rate": "18",
                    "discount_percent": "0",
                }
            ],
        ),
        seeded_user,
    )

    assert first.invoice.id == second.invoice.id


def test_invoice_number_sequence_allocates_incrementing_values(db_session, seeded_user):
    customer = Customer(name="ABC Stores", address="Market Yard")
    db_session.add(customer)
    db_session.commit()

    first = Invoice(
        request_id="6cc69935-6d8b-46b7-a6cf-fcb0a1d9a3c6",
        request_hash="hash-1",
        customer_id=customer.id,
        customer_name="ABC Stores",
        customer_address="Market Yard",
        place_of_supply_state_code="27",
        company_name="Acme Traders",
        company_address="Main Road",
        company_city="Pune",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date="2026-04-19",
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_state="CREDIT",
        paid_amount="0.00",
        subtotal="100.00",
        discount_total="0.00",
        taxable_total="100.00",
        gst_total="18.00",
        grand_total="118.00",
        created_by_user_id=seeded_user.id,
    )
    second = Invoice(
        request_id="15c9ce79-a944-4ce9-ba55-c6f8ef86937e",
        request_hash="hash-2",
        customer_id=customer.id,
        customer_name="XYZ Stores",
        customer_address="Another Yard",
        place_of_supply_state_code="27",
        company_name="Acme Traders",
        company_address="Main Road",
        company_city="Pune",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date="2026-04-20",
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_state="CREDIT",
        paid_amount="0.00",
        subtotal="100.00",
        discount_total="0.00",
        taxable_total="100.00",
        gst_total="18.00",
        grand_total="118.00",
        created_by_user_id=seeded_user.id,
    )
    db_session.add_all([first, second])
    db_session.commit()

    assert second.invoice_number == first.invoice_number + 1


def test_create_with_overlapping_products_is_idempotent_across_item_order(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
        gstin="27AAAAA0000A1Z5",
        gst_flag=True,
    )
    customer = Customer(name=f"ABC Stores {uuid4()}", address="Market Yard", state="Maharashtra", state_code="27")
    product_a = Product(
        company_name="Camlin",
        category="Pens",
        item_name=f"Blue Pen {uuid4()}",
        item_number=f"PEN-{uuid4()}",
        buying_price=Decimal("80.00"),
        selling_price=Decimal("118.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("10.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    product_b = Product(
        company_name="Camlin",
        category="Pens",
        item_name=f"Black Pen {uuid4()}",
        item_number=f"PEN-{uuid4()}",
        buying_price=Decimal("40.00"),
        selling_price=Decimal("59.00"),
        gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("10.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, customer, product_a, product_b])
    db_session.commit()

    request_id = "ffdb23a7-3192-457d-8f05-7d2e7680de77"
    first = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product_a.id,
                    "quantity": "1.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                },
                {
                    "product_id": product_b.id,
                    "quantity": "1.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "50.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                },
            ],
        ),
        seeded_user,
    )
    second = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            customer_id=customer.id,
            invoice_date="2026-04-19",
            payment_mode="CREDIT",
            place_of_supply_state_code="27",
            items=[
                {
                    "product_id": product_a.id,
                    "quantity": "1.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "100.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                },
                {
                    "product_id": product_b.id,
                    "quantity": "1.000",
                    "pricing_mode": "PRE_TAX",
                    "unit_price": "50.00",
                    "gst_rate": "18.00",
                    "discount_percent": "0.00",
                },
            ],
        ),
        seeded_user,
    )

    assert first.invoice.id == second.invoice.id


def test_non_gst_seller_forces_zero_tax_without_reducing_final_price(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)
    company = db_session.scalar(select(CompanyProfile).where(CompanyProfile.is_active.is_(True)))
    company.gst_flag = False
    company.gstin = None
    db_session.commit()

    response = invoice_service.create_invoice(
        db_session,
        _v2_create_payload(
            customer,
            product,
            gst_flag=False,
            items=[_v2_line(product, quantity=Decimal("2.000"), unit_price=Decimal("118.00"), pricing_mode="TAX_INCLUSIVE")],
        ),
        seeded_user,
    )
    assert response.invoice.gst_total == Decimal("0.00")
    assert response.invoice.grand_total == Decimal("236.00")
    assert response.invoice.gst_flag is False


def test_gst_seller_rejects_non_gst_taxable_lines_at_quote(db_session):
    customer, _, product = _seed_invoice_v2_graph(db_session)
    with pytest.raises(HTTPException) as exc:
        invoice_service.build_quote(
            db_session,
            InvoiceQuoteRequest(
                customer_id=customer.id,
                invoice_date="2026-04-19",
                payment_state="CREDIT",
                place_of_supply_state_code="27",
                gst_flag=False,
                items=[_v2_line(product)],
            ),
        )
    assert exc.value.detail["error"]["code"] == "NON_GST_TAXABLE_LINES"


def test_idempotency_hash_includes_gst_flag(db_session, seeded_user):
    customer, _, product = _seed_invoice_v2_graph(db_session)
    request_id = uuid4()
    first = invoice_service.create_invoice(
        db_session,
        _v2_create_payload(customer, product, request_id=request_id, gst_flag=True),
        seeded_user,
    )
    second = invoice_service.create_invoice(
        db_session,
        _v2_create_payload(customer, product, request_id=request_id, gst_flag=True),
        seeded_user,
    )
    assert first.invoice.id == second.invoice.id

    with pytest.raises(HTTPException) as exc:
        invoice_service.create_invoice(
            db_session,
            _v2_create_payload(customer, product, request_id=request_id, gst_flag=False),
            seeded_user,
        )
    assert exc.value.status_code == 409
    assert exc.value.detail["error"]["code"] == "IDEMPOTENCY_CONFLICT"
