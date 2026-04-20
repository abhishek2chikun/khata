from decimal import Decimal
from uuid import uuid4

from app.models.company_profile import CompanyProfile
from app.models.invoice import Invoice
from app.models.product import Product
from app.models.seller import Seller
from app.schemas.invoice import InvoiceCreateRequest, InvoiceQuoteRequest
from app.services import invoice_service

from app.core.idempotency import canonical_request_hash


def test_invoice_request_hash_changes_when_item_order_changes():
    payload = {
        "seller_id": "seller-1",
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
    )
    seller = Seller(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_code="PEN-001",
        default_selling_price_excl_tax=Decimal("100.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, seller, product])
    db_session.commit()

    quote = invoice_service.build_quote(
        db_session,
        InvoiceQuoteRequest(
            seller_id=seller.id,
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


def test_create_invoice_persists_invoice_items_and_credit_ledger(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
    )
    seller = Seller(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_code="PEN-001",
        default_selling_price_excl_tax=Decimal("100.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, seller, product])
    db_session.commit()

    created = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id="f0e3e6a2-b7d1-47b3-86e6-b1289fdf11ee",
            seller_id=seller.id,
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


def test_create_invoice_retry_succeeds_after_seller_is_archived(db_session, seeded_user):
    company = CompanyProfile(
        name="Acme Traders",
        address="Main Road",
        city="Pune",
        state="Maharashtra",
        state_code="27",
    )
    seller = Seller(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_code="PEN-001",
        default_selling_price_excl_tax=Decimal("100.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, seller, product])
    db_session.commit()

    payload = InvoiceCreateRequest(
        request_id="318628a9-3858-4900-b83a-a6e3c7304dcb",
        seller_id=seller.id,
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
    seller.is_active = False
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
    )
    seller = Seller(name="ABC Stores", address="Market Yard", state="Maharashtra", state_code="27")
    product = Product(
        company="Camlin",
        category="Pens",
        item_name="Blue Pen",
        item_code="PEN-001",
        default_selling_price_excl_tax=Decimal("100.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("5.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, seller, product])
    db_session.commit()

    request_id = "d2bd51c6-c8e0-4ae1-bc7c-6d62b69943ae"
    first = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            seller_id=seller.id,
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
            seller_id=seller.id,
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
    seller = Seller(name="ABC Stores", address="Market Yard")
    db_session.add(seller)
    db_session.commit()

    first = Invoice(
        request_id="6cc69935-6d8b-46b7-a6cf-fcb0a1d9a3c6",
        request_hash="hash-1",
        seller_id=seller.id,
        seller_name="ABC Stores",
        seller_address="Market Yard",
        place_of_supply_state_code="27",
        company_name="Acme Traders",
        company_address="Main Road",
        company_city="Pune",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date="2026-04-19",
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_mode="CREDIT",
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
        seller_id=seller.id,
        seller_name="XYZ Stores",
        seller_address="Another Yard",
        place_of_supply_state_code="27",
        company_name="Acme Traders",
        company_address="Main Road",
        company_city="Pune",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date="2026-04-20",
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_mode="CREDIT",
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
    )
    seller = Seller(name=f"ABC Stores {uuid4()}", address="Market Yard", state="Maharashtra", state_code="27")
    product_a = Product(
        company="Camlin",
        category="Pens",
        item_name=f"Blue Pen {uuid4()}",
        item_code=f"PEN-{uuid4()}",
        default_selling_price_excl_tax=Decimal("100.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("10.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    product_b = Product(
        company="Camlin",
        category="Pens",
        item_name=f"Black Pen {uuid4()}",
        item_code=f"PEN-{uuid4()}",
        default_selling_price_excl_tax=Decimal("50.00"),
        default_gst_rate=Decimal("18.00"),
        quantity_on_hand=Decimal("10.000"),
        low_stock_threshold=Decimal("2.000"),
    )
    db_session.add_all([company, seller, product_a, product_b])
    db_session.commit()

    request_id = "ffdb23a7-3192-457d-8f05-7d2e7680de77"
    first = invoice_service.create_invoice(
        db_session,
        InvoiceCreateRequest(
            request_id=request_id,
            seller_id=seller.id,
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
            seller_id=seller.id,
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
