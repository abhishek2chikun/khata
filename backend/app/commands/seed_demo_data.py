import argparse
from datetime import date
from decimal import Decimal
from uuid import UUID, uuid5

from sqlalchemy import select

from app.db import get_session_factory
from app.models.app_user import AppUser
from app.models.product import Product
from app.models.seller import Seller
from app.schemas.auth import CurrentUserResponse
from app.schemas.company_profile import CompanyProfileUpsertRequest
from app.schemas.invoice import InvoiceCreateRequest, InvoiceLineRequest
from app.schemas.product import ProductCreateRequest
from app.schemas.seller import OpeningBalanceRequest, PaymentRequest, SellerCreateRequest
from app.services import company_profile_service, invoice_service, product_service, seller_service

SEED_NAMESPACE = UUID("c4699823-a153-4a34-8d43-58e2d7d45ec5")


def _seed_uuid(*parts: str) -> UUID:
    return uuid5(SEED_NAMESPACE, ":".join(parts))


def _current_user_from_username(session, username: str) -> CurrentUserResponse:
    user = session.scalar(select(AppUser).where(AppUser.username == username, AppUser.is_active.is_(True)))
    if user is None:
        raise ValueError(f"active user '{username}' not found; run bootstrap_user first")
    return CurrentUserResponse(id=str(user.id), username=user.username, display_name=user.display_name)


def _ensure_company_profile(session) -> None:
    company_profile_service.upsert_company_profile(
        session,
        CompanyProfileUpsertRequest(
            name="Acme Stationers Pvt Ltd",
            address="12 Market Road",
            city="Pune",
            state="Maharashtra",
            state_code="27",
            gstin="27AAAAA0000A1Z5",
            phone="9876543210",
            email="billing@acmestationers.example",
            bank_name="ABC Bank",
            bank_account="1234567890",
            bank_ifsc="ABC0001234",
            bank_branch="Pune Camp",
            jurisdiction="Pune",
        ),
    )


def _ensure_seller(session, payload: SellerCreateRequest) -> Seller:
    existing = session.scalar(select(Seller).where(Seller.name == payload.name, Seller.phone == payload.phone))
    if existing is not None:
        return existing
    return seller_service.create_seller(session, payload)


def _ensure_product(session, payload: ProductCreateRequest, current_user: CurrentUserResponse) -> Product:
    existing = session.scalar(select(Product).where(Product.item_code == payload.item_code))
    if existing is not None:
        return existing
    return product_service.create_product(session, payload, current_user)


def seed_demo_data(*, username: str) -> dict[str, int]:
    session = get_session_factory()()
    try:
        current_user = _current_user_from_username(session, username)
        _ensure_company_profile(session)

        sellers = {
            "abc_stores": _ensure_seller(
                session,
                SellerCreateRequest(
                    name="ABC Stores",
                    address="Market Yard, Pune",
                    phone="9999999999",
                    gstin="27BBBBB0000B1Z5",
                    state="Maharashtra",
                    state_code="27",
                ),
            ),
            "city_books": _ensure_seller(
                session,
                SellerCreateRequest(
                    name="City Books Depot",
                    address="FC Road, Pune",
                    phone="8888888888",
                    gstin="27CCCCC0000C1Z5",
                    state="Maharashtra",
                    state_code="27",
                ),
            ),
            "karnataka_office": _ensure_seller(
                session,
                SellerCreateRequest(
                    name="Karnataka Office Supplies",
                    address="Commercial Street, Bengaluru",
                    phone="7777777777",
                    gstin="29DDDDD0000D1Z5",
                    state="Karnataka",
                    state_code="29",
                ),
            ),
        }

        products = {
            "PEN-001": _ensure_product(
                session,
                ProductCreateRequest(
                    company="Camlin",
                    category="Pens",
                    item_name="Blue Ball Pen",
                    item_code="PEN-001",
                    buying_price_excl_tax=Decimal("8.00"),
                    buying_gst_rate=Decimal("18.00"),
                    default_selling_price_excl_tax=Decimal("12.00"),
                    default_gst_rate=Decimal("18.00"),
                    quantity_on_hand=Decimal("120.000"),
                    low_stock_threshold=Decimal("20.000"),
                ),
                current_user,
            ),
            "NOTE-001": _ensure_product(
                session,
                ProductCreateRequest(
                    company="Navneet",
                    category="Notebooks",
                    item_name="A5 Notebook",
                    item_code="NOTE-001",
                    buying_price_excl_tax=Decimal("38.00"),
                    buying_gst_rate=Decimal("12.00"),
                    default_selling_price_excl_tax=Decimal("55.00"),
                    default_gst_rate=Decimal("12.00"),
                    quantity_on_hand=Decimal("80.000"),
                    low_stock_threshold=Decimal("15.000"),
                ),
                current_user,
            ),
            "MRK-001": _ensure_product(
                session,
                ProductCreateRequest(
                    company="Camlin",
                    category="Markers",
                    item_name="Permanent Marker Black",
                    item_code="MRK-001",
                    buying_price_excl_tax=Decimal("24.00"),
                    buying_gst_rate=Decimal("18.00"),
                    default_selling_price_excl_tax=Decimal("35.00"),
                    default_gst_rate=Decimal("18.00"),
                    quantity_on_hand=Decimal("18.000"),
                    low_stock_threshold=Decimal("12.000"),
                ),
                current_user,
            ),
            "FILE-001": _ensure_product(
                session,
                ProductCreateRequest(
                    company="Solo",
                    category="Files",
                    item_name="Plastic Document File",
                    item_code="FILE-001",
                    buying_price_excl_tax=Decimal("15.00"),
                    buying_gst_rate=Decimal("18.00"),
                    default_selling_price_excl_tax=Decimal("22.00"),
                    default_gst_rate=Decimal("18.00"),
                    quantity_on_hand=Decimal("45.000"),
                    low_stock_threshold=Decimal("10.000"),
                ),
                current_user,
            ),
        }

        seller_service.create_opening_balance(
            session,
            str(sellers["abc_stores"].id),
            OpeningBalanceRequest(
                request_id=_seed_uuid("opening-balance", "abc-stores"),
                amount=Decimal("1500.00"),
                occurred_on=date(2026, 4, 1),
            ),
            current_user,
        )
        seller_service.create_payment(
            session,
            PaymentRequest(
                request_id=_seed_uuid("payment", "abc-stores", "2026-04-05"),
                seller_id=sellers["abc_stores"].id,
                amount=Decimal("400.00"),
                occurred_on=date(2026, 4, 5),
                notes="Opening cycle payment collection",
            ),
            current_user,
        )

        invoice_service.create_invoice(
            session,
            InvoiceCreateRequest(
                request_id=_seed_uuid("invoice", "abc-stores", "credit-1"),
                seller_id=sellers["abc_stores"].id,
                invoice_date=date(2026, 4, 19),
                payment_mode="CREDIT",
                items=[
                    InvoiceLineRequest(
                        product_id=products["PEN-001"].id,
                        quantity=Decimal("10.000"),
                        pricing_mode="PRE_TAX",
                        unit_price=Decimal("12.00"),
                        gst_rate=Decimal("18.00"),
                        discount_percent=Decimal("0.00"),
                    ),
                    InvoiceLineRequest(
                        product_id=products["NOTE-001"].id,
                        quantity=Decimal("5.000"),
                        pricing_mode="PRE_TAX",
                        unit_price=Decimal("55.00"),
                        gst_rate=Decimal("12.00"),
                        discount_percent=Decimal("5.00"),
                    ),
                ],
                place_of_supply_state_code="27",
                notes="Demo credit sale inside Maharashtra",
            ),
            current_user,
        )

        invoice_service.create_invoice(
            session,
            InvoiceCreateRequest(
                request_id=_seed_uuid("invoice", "city-books", "paid-1"),
                seller_id=sellers["city_books"].id,
                invoice_date=date(2026, 4, 21),
                payment_mode="PAID",
                items=[
                    InvoiceLineRequest(
                        product_id=products["FILE-001"].id,
                        quantity=Decimal("12.000"),
                        pricing_mode="PRE_TAX",
                        unit_price=Decimal("22.00"),
                        gst_rate=Decimal("18.00"),
                        discount_percent=Decimal("0.00"),
                    ),
                ],
                place_of_supply_state_code="27",
                notes="Demo paid invoice",
            ),
            current_user,
        )

        invoice_service.create_invoice(
            session,
            InvoiceCreateRequest(
                request_id=_seed_uuid("invoice", "karnataka-office", "credit-1"),
                seller_id=sellers["karnataka_office"].id,
                invoice_date=date(2026, 4, 22),
                payment_mode="CREDIT",
                items=[
                    InvoiceLineRequest(
                        product_id=products["MRK-001"].id,
                        quantity=Decimal("8.000"),
                        pricing_mode="PRE_TAX",
                        unit_price=Decimal("35.00"),
                        gst_rate=Decimal("18.00"),
                        discount_percent=Decimal("0.00"),
                    ),
                ],
                place_of_supply_state_code="29",
                notes="Demo interstate credit invoice",
            ),
            current_user,
        )

        return {
            "sellers": len(sellers),
            "products": len(products),
            "invoices": 3,
        }
    finally:
        session.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--username", default="owner")
    args = parser.parse_args(argv)

    try:
        counts = seed_demo_data(username=args.username)
    except ValueError as exc:
        print(str(exc))
        return 1

    print(
        "seeded demo data "
        f"(sellers={counts['sellers']}, products={counts['products']}, invoices={counts['invoices']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
