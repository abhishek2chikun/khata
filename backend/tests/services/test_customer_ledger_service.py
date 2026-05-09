from datetime import date
from decimal import Decimal
from uuid import uuid4

from app.models.app_user import AppUser
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.models.invoice import Invoice
from app.services.customer_service import build_customer_response, get_customer_ledger


def test_customer_ledger_balance_uses_append_only_rows_not_mutable_customer_state(db_session):
    user = AppUser(username="ledger-owner", password_hash="hash")
    customer = Customer(name="Ledger Customer", address="Market Yard")
    db_session.add_all([user, customer])
    db_session.flush()
    invoice = Invoice(
        request_id=uuid4(),
        request_hash="invoice-hash",
        invoice_number=1001,
        customer_id=customer.id,
        customer_name=customer.name,
        customer_address=customer.address,
        place_of_supply_state_code="27",
        company_name="Company",
        company_address="Company address",
        company_city="Mumbai",
        company_state="Maharashtra",
        company_state_code="27",
        invoice_date=date(2026, 4, 20),
        tax_regime="INTRA_STATE",
        status="ACTIVE",
        payment_mode="CREDIT",
        subtotal=Decimal("200.00"),
        discount_total=Decimal("0.00"),
        taxable_total=Decimal("200.00"),
        gst_total=Decimal("0.00"),
        grand_total=Decimal("200.00"),
        created_by_user_id=user.id,
    )
    db_session.add(invoice)
    db_session.flush()
    db_session.add_all(
        [
            _transaction(customer, user, "OPENING_BALANCE", "100.00", date(2026, 4, 18), request_id=uuid4()),
            _transaction(customer, user, "CREDIT_SALE", "200.00", date(2026, 4, 20), invoice_id=invoice.id),
            _transaction(customer, user, "COLLECTION", "50.00", date(2026, 4, 21), request_id=uuid4()),
            _transaction(customer, user, "BALANCE_INCREASE_ADJUSTMENT", "25.00", date(2026, 4, 22), request_id=uuid4()),
            _transaction(customer, user, "BALANCE_DECREASE_ADJUSTMENT", "10.00", date(2026, 4, 23), request_id=uuid4()),
            _transaction(customer, user, "INVOICE_CANCEL_REVERSAL", "200.00", date(2026, 4, 24), invoice_id=invoice.id),
        ]
    )
    db_session.commit()

    response = build_customer_response(db_session, customer)
    ledger = get_customer_ledger(db_session, customer.id)

    assert response.pending_balance == "65.00"
    assert ledger.customer.pending_balance == "65.00"
    assert [transaction.entry_type for transaction in ledger.transactions] == [
        "OPENING_BALANCE",
        "CREDIT_SALE",
        "COLLECTION",
        "BALANCE_INCREASE_ADJUSTMENT",
        "BALANCE_DECREASE_ADJUSTMENT",
        "INVOICE_CANCEL_REVERSAL",
    ]
    assert all(transaction.created_at is not None for transaction in ledger.transactions)


def _transaction(
    customer: Customer,
    user: AppUser,
    entry_type: str,
    amount: str,
    occurred_on: date,
    *,
    request_id=None,
    invoice_id=None,
) -> CustomerTransaction:
    return CustomerTransaction(
        customer_id=customer.id,
        invoice_id=invoice_id,
        request_id=request_id,
        request_hash="request-hash" if request_id is not None else None,
        opening_balance_customer_id=customer.id if entry_type == "OPENING_BALANCE" else None,
        entry_type=entry_type,
        amount=Decimal(amount),
        occurred_on=occurred_on,
        created_by_user_id=user.id,
    )
