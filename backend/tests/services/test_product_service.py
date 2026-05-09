from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.models.product import Product
from app.schemas.auth import CurrentUserResponse
from app.schemas.product import ProductCreateRequest, ProductUpdateRequest
from app.services import product_service


def _current_user(seeded_user) -> CurrentUserResponse:
    return CurrentUserResponse(id=seeded_user.id, username=seeded_user.username, display_name=seeded_user.display_name)


def _product_payload(**overrides) -> ProductCreateRequest:
    data = {
        "item_number": "PEN-001",
        "item_name": "Blue Pen",
        "category": "Pens",
        "company_name": "Camlin",
        "buying_price": Decimal("8.00"),
        "selling_price": Decimal("12.00"),
        "gst_rate": Decimal("18.00"),
        "unit": None,
        "quantity_on_hand": Decimal("5.000"),
        "low_stock_threshold": Decimal("2.000"),
    }
    data.update(overrides)
    return ProductCreateRequest(**data)


@pytest.mark.parametrize("field", ["item_number", "item_name", "category", "company_name", "buying_price", "selling_price", "gst_rate"])
def test_create_product_requires_canonical_fields(field):
    data = _product_payload().model_dump()
    data.pop(field)

    with pytest.raises(ValueError):
        ProductCreateRequest(**data)


def test_create_product_allows_null_unit(db_session, seeded_user):
    product = product_service.create_product(db_session, _product_payload(unit=None), _current_user(seeded_user))

    assert product.unit is None
    assert product.item_number == "PEN-001"


def test_create_product_rejects_duplicate_item_number(db_session, seeded_user):
    product_service.create_product(db_session, _product_payload(), _current_user(seeded_user))

    with pytest.raises(HTTPException) as exc_info:
        product_service.create_product(db_session, _product_payload(item_name="Black Marker", category="Markers"), _current_user(seeded_user))

    assert exc_info.value.status_code == 409
    assert exc_info.value.detail["error"]["code"] == "DUPLICATE_PRODUCT"


def test_create_product_rejects_duplicate_identity_across_archived_rows(db_session, seeded_user):
    existing = product_service.create_product(db_session, _product_payload(), _current_user(seeded_user))
    product_service.archive_product(db_session, existing.id)

    with pytest.raises(HTTPException) as exc_info:
        product_service.create_product(db_session, _product_payload(item_number="PEN-002"), _current_user(seeded_user))

    assert exc_info.value.status_code == 409
    assert exc_info.value.detail["error"]["code"] == "DUPLICATE_PRODUCT"


def test_update_product_changes_editable_fields_without_changing_quantity(db_session, seeded_user):
    product = product_service.create_product(db_session, _product_payload(quantity_on_hand=Decimal("5.000")), _current_user(seeded_user))

    updated = product_service.update_product(
        db_session,
        product.id,
        ProductUpdateRequest(
            item_name="Blue Gel Pen",
            company_name="Navneet",
            category="Gel Pens",
            item_number="GEL-001",
            buying_price=Decimal("9.00"),
            selling_price=Decimal("14.00"),
            unit="pcs",
            gst_rate=Decimal("12.00"),
            low_stock_threshold=Decimal("3.000"),
        ),
    )

    assert updated.item_name == "Blue Gel Pen"
    assert updated.company_name == "Navneet"
    assert updated.item_number == "GEL-001"
    assert updated.buying_price == Decimal("9.00")
    assert updated.selling_price == Decimal("14.00")
    assert updated.unit == "pcs"
    assert updated.gst_rate == Decimal("12.00")
    assert updated.quantity_on_hand == Decimal("5.000")


def test_update_product_rejects_direct_quantity_change(db_session, seeded_user):
    product = product_service.create_product(db_session, _product_payload(quantity_on_hand=Decimal("5.000")), _current_user(seeded_user))

    with pytest.raises(HTTPException) as exc_info:
        product_service.update_product(db_session, product.id, ProductUpdateRequest(quantity_on_hand=Decimal("99.000")))

    assert exc_info.value.status_code == 400


def test_archive_product_marks_product_inactive(db_session, seeded_user):
    product = product_service.create_product(db_session, _product_payload(), _current_user(seeded_user))

    archived = product_service.archive_product(db_session, product.id)

    assert archived.is_active is False
    assert db_session.get(Product, product.id).is_active is False
