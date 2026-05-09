from datetime import date, datetime, UTC
from decimal import Decimal
from uuid import uuid4

from app.models.app_user import AppUser
from app.models.buyer import Buyer
from app.models.buyer_transaction import BuyerTransaction
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.product import Product
from app.services.analytics_service import get_dashboard


def _seed_invoice_with_items(db_session, *, user, customer, invoice_date, invoice_number=1001, payment_state="CREDIT", paid_amount=Decimal("0.00"), grand_total=Decimal("236.00"), items):
    invoice = Invoice(
        request_id=uuid4(),
        request_hash="hash",
        invoice_number=invoice_number,
        customer_id=customer.id,
        customer_name=customer.name,
        customer_address=customer.address,
        place_of_supply_state_code="27",
        company_name="Test Co",
        company_address="Addr",
        company_city="Mumbai",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date=invoice_date,
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_state=payment_state,
        paid_amount=paid_amount,
        subtotal=grand_total,
        discount_total=Decimal("0.00"),
        taxable_total=grand_total,
        gst_total=Decimal("0.00"),
        grand_total=grand_total,
        created_by_user_id=user.id,
    )
    db_session.add(invoice)
    db_session.flush()
    for idx, item_data in enumerate(items, start=1):
        db_session.add(
            InvoiceItem(
                invoice_id=invoice.id,
                product_id=item_data["product_id"],
                line_number=item_data.get("line_number", idx),
                product_item_number=item_data.get("item_number", "ITEM-001"),
                product_item_name=item_data.get("item_name", "Test Item"),
                product_category=item_data.get("category", "General"),
                product_buyer_id=item_data.get("buyer_id"),
                product_company_name=item_data.get("company_name", "TestCo"),
                buying_price=item_data["buying_price"],
                selling_price=item_data["selling_price"],
                unit=item_data.get("unit"),
                product_name=item_data.get("item_name", "Test Item"),
                product_code=item_data.get("item_number", "ITEM-001"),
                company=item_data.get("company_name", "TestCo"),
                category=item_data.get("category", "General"),
                quantity=item_data["quantity"],
                pricing_mode="TAX_INCLUSIVE",
                entered_unit_price=item_data["selling_price"],
                unit_price_excl_tax=item_data["selling_price"],
                unit_price_incl_tax=item_data["selling_price"],
                gst_rate=Decimal("0.00"),
                cgst_rate=Decimal("0.00"),
                sgst_rate=Decimal("0.00"),
                igst_rate=Decimal("0.00"),
                discount_percent=Decimal("0.00"),
                discount_amount=Decimal("0.00"),
                taxable_amount=item_data["taxable_amount"],
                gst_amount=Decimal("0.00"),
                cgst_amount=Decimal("0.00"),
                sgst_amount=Decimal("0.00"),
                igst_amount=Decimal("0.00"),
                line_total=item_data["taxable_amount"],
                revenue_amount=item_data["taxable_amount"],
                buying_amount=item_data["buying_amount"],
                profit_amount=item_data["profit_amount"],
            )
        )
    db_session.flush()
    return invoice


def test_revenue_by_buyer_groups_invoice_items(db_session):
    user = AppUser(username="analytics-rb", password_hash="hash")
    customer = Customer(name="Rev Customer", address="Market")
    buyer_a = Buyer(name="Buyer A")
    buyer_b = Buyer(name="Buyer B")
    db_session.add_all([user, customer, buyer_a, buyer_b])
    db_session.flush()

    product_a = Product(
        item_number="PA-1", item_name="Prod A", category="Cat",
        company_name="TestCo", buying_price=Decimal("50.00"),
        selling_price=Decimal("100.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer_a.id,
    )
    product_b = Product(
        item_number="PB-1", item_name="Prod B", category="Cat",
        company_name="TestCo", buying_price=Decimal("40.00"),
        selling_price=Decimal("80.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer_b.id,
    )
    db_session.add_all([product_a, product_b])
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 20),
        grand_total=Decimal("200.00"),
        items=[
            {"product_id": product_a.id, "buyer_id": buyer_a.id, "company_name": "TestCo",
             "buying_price": Decimal("50.00"), "selling_price": Decimal("100.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("100.00"),
             "buying_amount": Decimal("50.00"), "profit_amount": Decimal("50.00")},
            {"product_id": product_b.id, "buyer_id": buyer_b.id, "company_name": "TestCo",
             "line_number": 2, "buying_price": Decimal("40.00"), "selling_price": Decimal("80.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("100.00"),
             "buying_amount": Decimal("40.00"), "profit_amount": Decimal("60.00")},
        ],
    )
    db_session.commit()

    result = get_dashboard(db_session)

    by_buyer = {b["name"]: b for b in result["revenue_by_buyer"]}
    assert by_buyer["Buyer A"]["revenue"] == Decimal("100.00")
    assert by_buyer["Buyer B"]["revenue"] == Decimal("100.00")


def test_profit_by_buyer_uses_buying_price_snapshot(db_session):
    user = AppUser(username="analytics-pb", password_hash="hash")
    customer = Customer(name="Profit Customer", address="Market")
    buyer = Buyer(name="Profit Buyer")
    db_session.add_all([user, customer, buyer])
    db_session.flush()

    product = Product(
        item_number="PP-1", item_name="Prod P", category="Cat",
        company_name="TestCo", buying_price=Decimal("60.00"),
        selling_price=Decimal("100.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer.id,
    )
    db_session.add(product)
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 20),
        grand_total=Decimal("200.00"),
        items=[
            {"product_id": product.id, "buyer_id": buyer.id, "company_name": "TestCo",
             "buying_price": Decimal("50.00"), "selling_price": Decimal("100.00"),
             "quantity": Decimal("2.000"), "taxable_amount": Decimal("200.00"),
             "buying_amount": Decimal("100.00"), "profit_amount": Decimal("100.00")},
        ],
    )
    db_session.commit()

    result = get_dashboard(db_session)

    by_buyer = {b["name"]: b for b in result["profit_by_buyer"]}
    assert by_buyer["Profit Buyer"]["profit"] == Decimal("100.00")


def test_profit_by_company_aggregates_across_buyers(db_session):
    user = AppUser(username="analytics-pc", password_hash="hash")
    customer = Customer(name="ProfitCo Customer", address="Market")
    buyer_a = Buyer(name="Buyer X")
    db_session.add_all([user, customer, buyer_a])
    db_session.flush()

    product = Product(
        item_number="PC-1", item_name="Prod PC", category="Cat",
        company_name="Acme Corp", buying_price=Decimal("40.00"),
        selling_price=Decimal("80.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer_a.id,
    )
    db_session.add(product)
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 20),
        grand_total=Decimal("80.00"),
        items=[
            {"product_id": product.id, "buyer_id": buyer_a.id, "company_name": "Acme Corp",
             "buying_price": Decimal("40.00"), "selling_price": Decimal("80.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("80.00"),
             "buying_amount": Decimal("40.00"), "profit_amount": Decimal("40.00")},
        ],
    )
    db_session.commit()

    result = get_dashboard(db_session)

    by_company = {c["name"]: c for c in result["profit_by_company"]}
    assert by_company["Acme Corp"]["profit"] == Decimal("40.00")


def test_revenue_by_customer_aggregates_invoice_totals(db_session):
    user = AppUser(username="analytics-rc", password_hash="hash")
    customer_a = Customer(name="Cust A", address="Addr A")
    customer_b = Customer(name="Cust B", address="Addr B")
    db_session.add_all([user, customer_a, customer_b])
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer_a, invoice_date=date(2026, 4, 20),
        grand_total=Decimal("150.00"),
        items=[
            {"product_id": uuid4(), "buying_price": Decimal("50.00"), "selling_price": Decimal("150.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("150.00"),
             "buying_amount": Decimal("50.00"), "profit_amount": Decimal("100.00")},
        ],
    )
    _seed_invoice_with_items(
        db_session, user=user, customer=customer_b, invoice_date=date(2026, 4, 21),
        invoice_number=1002, grand_total=Decimal("300.00"),
        items=[
            {"product_id": uuid4(), "buying_price": Decimal("100.00"), "selling_price": Decimal("300.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("300.00"),
             "buying_amount": Decimal("100.00"), "profit_amount": Decimal("200.00")},
        ],
    )
    db_session.commit()

    result = get_dashboard(db_session)

    by_customer = {c["name"]: c for c in result["revenue_by_customer"]}
    assert by_customer["Cust A"]["revenue"] == Decimal("150.00")
    assert by_customer["Cust B"]["revenue"] == Decimal("300.00")


def test_outstanding_customer_khata_balance(db_session):
    user = AppUser(username="analytics-khata", password_hash="hash")
    customer = Customer(name="Khata Customer", address="Market")
    db_session.add_all([user, customer])
    db_session.flush()

    invoice = Invoice(
        request_id=uuid4(), request_hash="h", invoice_number=2001,
        customer_id=customer.id, customer_name=customer.name,
        customer_address=customer.address, place_of_supply_state_code="27",
        company_name="Co", company_address="A", company_city="M",
        company_state="S", company_state_code="27",
        invoice_date=date(2026, 4, 20), tax_regime="INTRA_STATE",
        status="ACTIVE", payment_state="CREDIT", paid_amount=Decimal("0.00"),
        subtotal=Decimal("500.00"), discount_total=Decimal("0.00"),
        taxable_total=Decimal("500.00"), gst_total=Decimal("0.00"),
        grand_total=Decimal("500.00"), created_by_user_id=user.id,
    )
    db_session.add(invoice)
    db_session.flush()
    db_session.add_all([
        CustomerTransaction(
            customer_id=customer.id, invoice_id=invoice.id,
            entry_type="CREDIT_SALE", amount=Decimal("500.00"),
            occurred_on=date(2026, 4, 20), created_by_user_id=user.id,
        ),
        CustomerTransaction(
            customer_id=customer.id, request_id=uuid4(), request_hash="rh",
            entry_type="COLLECTION", amount=Decimal("200.00"),
            occurred_on=date(2026, 4, 21), created_by_user_id=user.id,
        ),
    ])
    db_session.commit()

    result = get_dashboard(db_session)

    balances = {b["customer_name"]: b for b in result["customer_khata_balances"]}
    assert balances["Khata Customer"]["balance"] == Decimal("300.00")


def test_buyer_pending_payable(db_session):
    user = AppUser(username="analytics-payable", password_hash="hash")
    buyer = Buyer(name="Payable Buyer")
    db_session.add_all([user, buyer])
    db_session.flush()

    db_session.add_all([
        BuyerTransaction(
            buyer_id=buyer.id, request_id=uuid4(), request_hash="h1",
            entry_type="OPENING_PAYABLE", amount=Decimal("1000.00"),
            occurred_at=datetime(2026, 4, 1, tzinfo=UTC),
            created_by_user_id=user.id,
        ),
        BuyerTransaction(
            buyer_id=buyer.id, request_id=uuid4(), request_hash="h2",
            entry_type="PAYMENT_MADE", amount=Decimal("400.00"),
            occurred_at=datetime(2026, 4, 15, tzinfo=UTC),
            created_by_user_id=user.id,
        ),
    ])
    db_session.commit()

    result = get_dashboard(db_session)

    payables = {p["buyer_name"]: p for p in result["buyer_pending_payables"]}
    assert payables["Payable Buyer"]["payable"] == Decimal("600.00")


def test_top_products_by_quantity_and_revenue(db_session):
    user = AppUser(username="analytics-top", password_hash="hash")
    customer = Customer(name="Top Cust", address="Mkt")
    buyer = Buyer(name="Top Buyer")
    db_session.add_all([user, customer, buyer])
    db_session.flush()

    product_x = Product(
        item_number="TX-1", item_name="Product X", category="Cat",
        company_name="TestCo", buying_price=Decimal("20.00"),
        selling_price=Decimal("50.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer.id,
    )
    product_y = Product(
        item_number="TY-1", item_name="Product Y", category="Cat",
        company_name="TestCo", buying_price=Decimal("30.00"),
        selling_price=Decimal("60.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer.id,
    )
    db_session.add_all([product_x, product_y])
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 20),
        grand_total=Decimal("220.00"),
        items=[
            {"product_id": product_x.id, "buyer_id": buyer.id, "item_name": "Product X",
             "buying_price": Decimal("20.00"), "selling_price": Decimal("50.00"),
             "quantity": Decimal("2.000"), "taxable_amount": Decimal("100.00"),
             "buying_amount": Decimal("40.00"), "profit_amount": Decimal("60.00")},
            {"product_id": product_y.id, "buyer_id": buyer.id, "item_name": "Product Y",
             "line_number": 2, "buying_price": Decimal("30.00"), "selling_price": Decimal("60.00"),
             "quantity": Decimal("2.000"), "taxable_amount": Decimal("120.00"),
             "buying_amount": Decimal("60.00"), "profit_amount": Decimal("60.00")},
        ],
    )
    db_session.commit()

    result = get_dashboard(db_session)

    by_qty_names = [p["product_name"] for p in result["top_products_by_quantity"]]
    assert "Product X" in by_qty_names
    assert "Product Y" in by_qty_names

    by_rev = {p["product_name"]: p for p in result["top_products_by_revenue"]}
    assert by_rev["Product X"]["revenue"] == Decimal("100.00")
    assert by_rev["Product Y"]["revenue"] == Decimal("120.00")

    by_profit = {p["product_name"]: p for p in result["top_products_by_profit"]}
    assert by_profit["Product X"]["profit"] == Decimal("60.00")
    assert by_profit["Product Y"]["profit"] == Decimal("60.00")


def test_low_stock_summary(db_session):
    user = AppUser(username="analytics-stock", password_hash="hash")
    db_session.add(user)
    db_session.flush()

    low_product = Product(
        item_number="LS-1", item_name="Low Stock Item", category="Cat",
        company_name="TestCo", buying_price=Decimal("10.00"),
        selling_price=Decimal("20.00"), gst_rate=Decimal("0.00"),
        quantity_on_hand=Decimal("1.000"), low_stock_threshold=Decimal("5.000"),
    )
    ok_product = Product(
        item_number="OK-1", item_name="OK Stock Item", category="Cat",
        company_name="TestCo", buying_price=Decimal("10.00"),
        selling_price=Decimal("20.00"), gst_rate=Decimal("0.00"),
        quantity_on_hand=Decimal("10.000"), low_stock_threshold=Decimal("5.000"),
    )
    db_session.add_all([low_product, ok_product])
    db_session.commit()

    result = get_dashboard(db_session)

    low_names = [p["product_name"] for p in result["low_stock"]]
    assert "Low Stock Item" in low_names
    assert "OK Stock Item" not in low_names


def test_date_range_filtering(db_session):
    user = AppUser(username="analytics-date", password_hash="hash")
    customer = Customer(name="Date Cust", address="Mkt")
    buyer = Buyer(name="Date Buyer")
    db_session.add_all([user, customer, buyer])
    db_session.flush()

    product = Product(
        item_number="DT-1", item_name="Date Prod", category="Cat",
        company_name="TestCo", buying_price=Decimal("10.00"),
        selling_price=Decimal("20.00"), gst_rate=Decimal("0.00"),
        buyer_id=buyer.id,
    )
    db_session.add(product)
    db_session.flush()

    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 10),
        invoice_number=3001, grand_total=Decimal("20.00"),
        items=[
            {"product_id": product.id, "buyer_id": buyer.id,
             "buying_price": Decimal("10.00"), "selling_price": Decimal("20.00"),
             "quantity": Decimal("1.000"), "taxable_amount": Decimal("20.00"),
             "buying_amount": Decimal("10.00"), "profit_amount": Decimal("10.00")},
        ],
    )
    _seed_invoice_with_items(
        db_session, user=user, customer=customer, invoice_date=date(2026, 4, 25),
        invoice_number=3002, grand_total=Decimal("40.00"),
        items=[
            {"product_id": product.id, "buyer_id": buyer.id,
             "buying_price": Decimal("10.00"), "selling_price": Decimal("20.00"),
             "quantity": Decimal("2.000"), "taxable_amount": Decimal("40.00"),
             "buying_amount": Decimal("20.00"), "profit_amount": Decimal("20.00")},
        ],
    )
    db_session.commit()

    result_april_mid = get_dashboard(db_session, from_date=date(2026, 4, 1), to_date=date(2026, 4, 15))

    total_rev = sum(item["revenue"] for item in result_april_mid["revenue_by_buyer"])
    assert total_rev == Decimal("20.00")

    result_full = get_dashboard(db_session)
    total_rev_full = sum(item["revenue"] for item in result_full["revenue_by_buyer"])
    assert total_rev_full == Decimal("60.00")
