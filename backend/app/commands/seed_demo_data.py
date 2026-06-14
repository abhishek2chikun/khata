import argparse
import uuid
from datetime import date
from decimal import Decimal
from uuid import UUID, uuid5

from sqlalchemy import select

from app.db import get_session_factory
from app.models.app_user import AppUser
from app.models.invoice import Invoice
from app.models.product import Product
from app.models.customer import Customer
from app.schemas.auth import CurrentUserResponse
from app.schemas.company_profile import CompanyProfileUpsertRequest
from app.schemas.invoice import InvoiceCreateRequest, InvoiceLineRequest
from app.schemas.product import ProductCreateRequest
from app.schemas.customer import OpeningBalanceRequest, CollectionRequest, CustomerCreateRequest
from app.services import company_profile_service, invoice_service, product_service, customer_service

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


def _ensure_customer(session, payload: CustomerCreateRequest) -> Customer:
    existing = session.scalar(select(Customer).where(Customer.name == payload.name, Customer.phone == payload.phone))
    if existing is not None:
        return existing
    return customer_service.create_customer(session, payload)


def _ensure_product(session, payload: ProductCreateRequest, current_user: CurrentUserResponse) -> Product:
    existing = session.scalar(select(Product).where(Product.item_number == payload.item_number))
    if existing is not None:
        _sync_seed_product(existing, payload)
        session.commit()
        session.refresh(existing)
        return existing
    return product_service.create_product(session, payload, current_user)


def _sync_seed_product(product: Product, payload: ProductCreateRequest) -> None:
    product.company_name = payload.company_name
    product.category = payload.category
    product.item_name = payload.item_name
    product.buyer_id = payload.buyer_id
    product.buying_price = payload.buying_price
    product.selling_price = payload.selling_price
    product.unit = payload.unit
    product.gst_rate = payload.gst_rate
    product.hsn_code = payload.hsn_code
    product.low_stock_threshold = payload.low_stock_threshold


def _demo_product_payloads() -> dict[str, ProductCreateRequest]:
    return {
        "PEN-001": ProductCreateRequest(
            company_name="Camlin",
            category="Pens",
            item_name="Blue Ball Pen",
            item_number="PEN-001",
            buying_price=Decimal("9.440"),
            selling_price=Decimal("14.160"),
            gst_rate=Decimal("18.00"),
            hsn_code="960810",
            quantity_on_hand=Decimal("120"),
            low_stock_threshold=Decimal("20"),
        ),
        "NOTE-001": ProductCreateRequest(
            company_name="Navneet",
            category="Notebooks",
            item_name="A5 Notebook",
            item_number="NOTE-001",
            buying_price=Decimal("42.560"),
            selling_price=Decimal("61.600"),
            gst_rate=Decimal("12.00"),
            hsn_code="482020",
            quantity_on_hand=Decimal("80"),
            low_stock_threshold=Decimal("15"),
        ),
        "MRK-001": ProductCreateRequest(
            company_name="Camlin",
            category="Markers",
            item_name="Permanent Marker Black",
            item_number="MRK-001",
            buying_price=Decimal("28.320"),
            selling_price=Decimal("41.300"),
            gst_rate=Decimal("18.00"),
            hsn_code="960820",
            quantity_on_hand=Decimal("18"),
            low_stock_threshold=Decimal("12"),
        ),
        "FILE-001": ProductCreateRequest(
            company_name="Solo",
            category="Files",
            item_name="Plastic Document File",
            item_number="FILE-001",
            buying_price=Decimal("17.700"),
            selling_price=Decimal("25.960"),
            gst_rate=Decimal("18.00"),
            hsn_code="482030",
            quantity_on_hand=Decimal("45"),
            low_stock_threshold=Decimal("10"),
        ),
    }


def _demo_invoice_line_payloads(products: dict[str, ProductCreateRequest | Product]) -> dict[str, InvoiceLineRequest]:
    placeholder_product_id = uuid.UUID("00000000-0000-0000-0000-000000000000")
    return {
        item_number: InvoiceLineRequest(
            product_id=product.id if isinstance(product, Product) else placeholder_product_id,
            quantity=quantity,
            pricing_mode="TAX_INCLUSIVE",
            unit_price=product.selling_price,
            gst_rate=product.gst_rate,
            discount_percent=discount_percent,
        )
        for item_number, product, quantity, discount_percent in [
            ("PEN-001", products["PEN-001"], Decimal("10"), Decimal("0.00")),
            ("NOTE-001", products["NOTE-001"], Decimal("5"), Decimal("0.00")),
            ("FILE-001", products["FILE-001"], Decimal("12"), Decimal("0.00")),
            ("MRK-001", products["MRK-001"], Decimal("8"), Decimal("0.00")),
        ]
    }


def _demo_invoice_request_ids() -> dict[str, UUID]:
    return {
        "abc_stores_credit": _seed_uuid("invoice-v2", "abc-stores", "credit-1"),
        "city_books_paid": _seed_uuid("invoice-v2", "city-books", "paid-1"),
        "karnataka_office_credit": _seed_uuid("invoice-v2", "karnataka-office", "credit-1"),
    }


def _legacy_demo_invoice_request_ids() -> dict[str, UUID]:
    return {
        "abc_stores_credit": _seed_uuid("invoice", "abc-stores", "credit-1"),
        "city_books_paid": _seed_uuid("invoice", "city-books", "paid-1"),
        "karnataka_office_credit": _seed_uuid("invoice", "karnataka-office", "credit-1"),
    }


def _should_create_demo_invoice(invoice_key: str, existing_request_ids: set[UUID]) -> bool:
    return _demo_invoice_request_ids()[invoice_key] not in existing_request_ids and _legacy_demo_invoice_request_ids()[invoice_key] not in existing_request_ids


def seed_demo_data(*, username: str) -> dict[str, int]:
    session = get_session_factory()()
    try:
        current_user = _current_user_from_username(session, username)
        _ensure_company_profile(session)

        customers = {
            "abc_stores": _ensure_customer(
                session,
                CustomerCreateRequest(
                    name="ABC Stores",
                    address="Market Yard, Pune",
                    phone="9999999999",
                    gstin="27BBBBB0000B1Z5",
                    state="Maharashtra",
                    state_code="27",
                ),
            ),
            "city_books": _ensure_customer(
                session,
                CustomerCreateRequest(
                    name="City Books Depot",
                    address="FC Road, Pune",
                    phone="8888888888",
                    gstin="27CCCCC0000C1Z5",
                    state="Maharashtra",
                    state_code="27",
                ),
            ),
            "karnataka_office": _ensure_customer(
                session,
                CustomerCreateRequest(
                    name="Karnataka Office Supplies",
                    address="Commercial Street, Bengaluru",
                    phone="7777777777",
                    gstin="29DDDDD0000D1Z5",
                    state="Karnataka",
                    state_code="29",
                ),
            ),
        }

        products = {item_number: _ensure_product(session, payload, current_user) for item_number, payload in _demo_product_payloads().items()}
        invoice_lines = _demo_invoice_line_payloads(products)
        invoice_request_ids = _demo_invoice_request_ids()
        existing_invoice_request_ids = set(session.scalars(select(Invoice.request_id)).all())

        customer_service.create_opening_balance(
            session,
            str(customers["abc_stores"].id),
            OpeningBalanceRequest(
                request_id=_seed_uuid("opening-balance", "abc-stores"),
                amount=Decimal("1500.00"),
                occurred_on=date(2026, 4, 1),
            ),
            current_user,
        )
        customer_service.create_collection(
            session,
            CollectionRequest(
                request_id=_seed_uuid("payment", "abc-stores", "2026-04-05"),
                customer_id=customers["abc_stores"].id,
                amount=Decimal("400.00"),
                occurred_on=date(2026, 4, 5),
                notes="Opening cycle payment collection",
            ),
            current_user,
        )

        if _should_create_demo_invoice("abc_stores_credit", existing_invoice_request_ids):
            invoice_service.create_invoice(
                session,
                InvoiceCreateRequest(
                    request_id=invoice_request_ids["abc_stores_credit"],
                    customer_id=customers["abc_stores"].id,
                    invoice_date=date(2026, 4, 19),
                    payment_mode="CREDIT",
                    items=[
                        invoice_lines["PEN-001"],
                        invoice_lines["NOTE-001"],
                    ],
                    place_of_supply_state_code="27",
                    notes="Demo credit sale inside Maharashtra",
                ),
                current_user,
            )
            existing_invoice_request_ids.add(invoice_request_ids["abc_stores_credit"])

        if _should_create_demo_invoice("city_books_paid", existing_invoice_request_ids):
            invoice_service.create_invoice(
                session,
                InvoiceCreateRequest(
                    request_id=invoice_request_ids["city_books_paid"],
                    customer_id=customers["city_books"].id,
                    invoice_date=date(2026, 4, 21),
                    payment_mode="PAID",
                    items=[
                        invoice_lines["FILE-001"],
                    ],
                    place_of_supply_state_code="27",
                    notes="Demo paid invoice",
                ),
                current_user,
            )
            existing_invoice_request_ids.add(invoice_request_ids["city_books_paid"])

        if _should_create_demo_invoice("karnataka_office_credit", existing_invoice_request_ids):
            invoice_service.create_invoice(
                session,
                InvoiceCreateRequest(
                    request_id=invoice_request_ids["karnataka_office_credit"],
                    customer_id=customers["karnataka_office"].id,
                    invoice_date=date(2026, 4, 22),
                    payment_mode="CREDIT",
                    items=[
                        invoice_lines["MRK-001"],
                    ],
                    place_of_supply_state_code="29",
                    notes="Demo interstate credit invoice",
                ),
                current_user,
            )
            existing_invoice_request_ids.add(invoice_request_ids["karnataka_office_credit"])

        return {
            "customers": len(customers),
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
        f"(customers={counts['customers']}, products={counts['products']}, invoices={counts['invoices']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
