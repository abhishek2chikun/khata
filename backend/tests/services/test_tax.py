import pytest
from sqlalchemy import text

from app.models.invoice import Invoice
from app.core.tax import derive_tax_regime, resolve_place_of_supply_state


def test_place_of_supply_state_is_resolved_from_state_code():
    assert resolve_place_of_supply_state("27") == "Maharashtra"


def test_tax_regime_is_derived_from_company_and_supply_state_codes():
    assert derive_tax_regime(company_state_code="27", place_of_supply_state_code="27") == "INTRA_STATE"
    assert derive_tax_regime(company_state_code="27", place_of_supply_state_code="29") == "INTER_STATE"


def test_unknown_state_code_is_rejected():
    with pytest.raises(ValueError):
        resolve_place_of_supply_state("98")


def test_invoice_model_derives_place_of_supply_state_from_code():
    invoice = Invoice(
        request_id="5f2045df-5a34-4cb2-83a2-0d2614ef7403",
        request_hash="hash",
        seller_id="9b88ec2f-b8de-43da-87b4-b0fe539801df",
        seller_name="ABC Stores",
        seller_address="Market Yard",
        place_of_supply_state="Wrong Value",
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
        created_by_user_id="4ad8039e-54fd-4917-a11b-f7578f6132f4",
    )

    assert invoice.place_of_supply_state == "Maharashtra"


def test_invoice_number_sequence_restarts_with_schema_reset(db_session):
    before_restart = db_session.execute(text("SELECT nextval('invoice_number_seq')")).scalar_one()
    db_session.execute(text("TRUNCATE TABLE invoice_items, invoices, stock_movements, seller_transactions, company_profiles, sellers, products, user_sessions, app_users RESTART IDENTITY CASCADE"))
    after_restart = db_session.execute(text("SELECT nextval('invoice_number_seq')")).scalar_one()
    db_session.commit()

    assert before_restart == 1
    assert after_restart == 1
