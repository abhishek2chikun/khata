"""Shared owner-analytics parity scenario for backend/local tests."""

from datetime import UTC, date, datetime
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

PARITY_FROM_DATE = date(2026, 4, 1)
PARITY_TO_DATE = date(2026, 4, 3)

EXPECTED_TOTAL_REVENUE = Decimal("350.00")
EXPECTED_TOTAL_PROFIT = Decimal("140.00")
EXPECTED_ACTIVE_INVOICE_COUNT = 2
EXPECTED_AVERAGE_INVOICE_VALUE = Decimal("175.00")
EXPECTED_CUSTOMER_RECEIVABLES = Decimal("150.00")
EXPECTED_BUYER_PAYABLES = Decimal("500.00")

EXPECTED_DAILY_TREND = [
    {"date": date(2026, 4, 1), "revenue": Decimal("0.00"), "profit": Decimal("0.00")},
    {"date": date(2026, 4, 2), "revenue": Decimal("200.00"), "profit": Decimal("80.00")},
    {"date": date(2026, 4, 3), "revenue": Decimal("150.00"), "profit": Decimal("60.00")},
]


def seed_owner_analytics_parity(db_session) -> None:
    user = AppUser(username="parity-owner", password_hash="hash")
    customer = Customer(name="Parity Customer", address="Market")
    buyer = Buyer(name="Parity Buyer")
    db_session.add_all([user, customer, buyer])
    db_session.flush()

    gst_product = Product(
        item_number="GST-1",
        item_name="GST Widget",
        category="Cat",
        company_name="ParityCo",
        buying_price=Decimal("40.000"),
        selling_price=Decimal("100.000"),
        gst_rate=Decimal("18.00"),
        buyer_id=buyer.id,
    )
    non_gst_product = Product(
        item_number="NG-1",
        item_name="Plain Widget",
        category="Cat",
        company_name="ParityCo",
        buying_price=Decimal("30.000"),
        selling_price=Decimal("75.000"),
        gst_rate=Decimal("0.00"),
        buyer_id=buyer.id,
    )
    db_session.add_all([gst_product, non_gst_product])
    db_session.flush()

    _add_invoice(
        db_session,
        user=user,
        customer=customer,
        buyer=buyer,
        invoice_date=date(2026, 4, 2),
        invoice_number=5001,
        payment_state="CREDIT",
        paid_amount=Decimal("0.00"),
        grand_total=Decimal("200.00"),
        status="ACTIVE",
        items=[
            _item(
                product=non_gst_product,
                buyer=buyer,
                quantity=Decimal("1.000"),
                revenue=Decimal("100.00"),
                buying=Decimal("30.00"),
                profit=Decimal("70.00"),
            ),
            _item(
                product=gst_product,
                buyer=buyer,
                line_number=2,
                quantity=Decimal("1.000"),
                revenue=Decimal("100.00"),
                buying=Decimal("40.00"),
                profit=Decimal("10.00"),
            ),
        ],
    )
    _add_invoice(
        db_session,
        user=user,
        customer=customer,
        buyer=buyer,
        invoice_date=date(2026, 4, 3),
        invoice_number=5002,
        payment_state="PARTIAL_PAID",
        paid_amount=Decimal("50.00"),
        grand_total=Decimal("150.00"),
        status="ACTIVE",
        items=[
            _item(
                product=non_gst_product,
                buyer=buyer,
                quantity=Decimal("2.000"),
                revenue=Decimal("150.00"),
                buying=Decimal("60.00"),
                profit=Decimal("60.00"),
            ),
        ],
    )
    _add_invoice(
        db_session,
        user=user,
        customer=customer,
        buyer=buyer,
        invoice_date=date(2026, 4, 2),
        invoice_number=5003,
        payment_state="TOTAL_PAID",
        paid_amount=Decimal("80.00"),
        grand_total=Decimal("80.00"),
        status="CANCELED",
        items=[
            _item(
                product=non_gst_product,
                buyer=buyer,
                quantity=Decimal("1.000"),
                revenue=Decimal("80.00"),
                buying=Decimal("30.00"),
                profit=Decimal("50.00"),
            ),
        ],
    )

    db_session.add_all(
        [
            CustomerTransaction(
                customer_id=customer.id,
                entry_type="OPENING_BALANCE",
                amount=Decimal("200.00"),
                occurred_on=date(2026, 4, 1),
                created_by_user_id=user.id,
            ),
            CustomerTransaction(
                customer_id=customer.id,
                entry_type="COLLECTION",
                amount=Decimal("50.00"),
                occurred_on=date(2026, 4, 2),
                created_by_user_id=user.id,
            ),
            BuyerTransaction(
                buyer_id=buyer.id,
                request_id=uuid4(),
                request_hash="bp-1",
                entry_type="OPENING_PAYABLE",
                amount=Decimal("700.00"),
                occurred_at=datetime(2026, 4, 1, tzinfo=UTC),
                created_by_user_id=user.id,
            ),
            BuyerTransaction(
                buyer_id=buyer.id,
                request_id=uuid4(),
                request_hash="bp-2",
                entry_type="PAYMENT_MADE",
                amount=Decimal("200.00"),
                occurred_at=datetime(2026, 4, 2, tzinfo=UTC),
                created_by_user_id=user.id,
            ),
        ]
    )
    db_session.commit()


def _item(
    *,
    product: Product,
    buyer: Buyer,
    quantity: Decimal,
    revenue: Decimal,
    buying: Decimal,
    profit: Decimal,
    line_number: int = 1,
) -> dict:
    return {
        "product_id": product.id,
        "buyer_id": buyer.id,
        "company_name": product.company_name,
        "item_name": product.item_name,
        "item_number": product.item_number,
        "line_number": line_number,
        "quantity": quantity,
        "buying_price": product.buying_price,
        "selling_price": product.selling_price,
        "taxable_amount": revenue,
        "buying_amount": buying,
        "profit_amount": profit,
    }


def _add_invoice(
    db_session,
    *,
    user,
    customer,
    buyer,
    invoice_date,
    invoice_number,
    payment_state,
    paid_amount,
    grand_total,
    status,
    items,
) -> Invoice:
    invoice = Invoice(
        request_id=uuid4(),
        request_hash=f"hash-{invoice_number}",
        invoice_number=invoice_number,
        customer_id=customer.id,
        customer_name=customer.name,
        customer_address=customer.address,
        place_of_supply_state_code="27",
        company_name="Parity Co",
        company_address="Addr",
        company_city="Mumbai",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date=invoice_date,
        tax_regime="INTRA_STATE",
        status=status,
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
    for item_data in items:
        db_session.add(
            InvoiceItem(
                invoice_id=invoice.id,
                product_id=item_data["product_id"],
                line_number=item_data.get("line_number", 1),
                product_item_number=item_data.get("item_number", "ITEM-001"),
                product_item_name=item_data.get("item_name", "Test Item"),
                product_category=item_data.get("category", "General"),
                product_buyer_id=item_data.get("buyer_id"),
                product_company_name=item_data.get("company_name", "ParityCo"),
                buying_price=item_data["buying_price"],
                selling_price=item_data["selling_price"],
                product_name=item_data.get("item_name", "Test Item"),
                product_code=item_data.get("item_number", "ITEM-001"),
                company=item_data.get("company_name", "ParityCo"),
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
