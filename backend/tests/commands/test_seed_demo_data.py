from sqlalchemy import select

from app.commands.seed_demo_data import main
from app.models.company_profile import CompanyProfile
from app.models.invoice import Invoice
from app.models.product import Product
from app.models.seller import Seller
from app.models.seller_transaction import SellerTransaction
from app.services.auth_service import bootstrap_user


def test_seed_demo_data_creates_reusable_manual_testing_dataset(db_session) -> None:
    bootstrap_user(db_session, username="seed_owner_1", password="secret123", display_name="Owner")

    result = main(["--username", "seed_owner_1"])

    assert result == 0
    assert db_session.scalar(select(CompanyProfile.id)) is not None
    assert len(db_session.scalars(select(Product)).all()) == 4
    assert len(db_session.scalars(select(Seller)).all()) == 3
    assert len(db_session.scalars(select(Invoice)).all()) == 3
    assert len(db_session.scalars(select(SellerTransaction)).all()) == 4


def test_seed_demo_data_is_rerunnable_without_duplicate_financial_data(db_session) -> None:
    bootstrap_user(db_session, username="seed_owner_2", password="secret123", display_name="Owner")

    first = main(["--username", "seed_owner_2"])
    second = main(["--username", "seed_owner_2"])

    assert first == 0
    assert second == 0
    assert len(db_session.scalars(select(Product)).all()) == 4
    assert len(db_session.scalars(select(Seller)).all()) == 3
    assert len(db_session.scalars(select(Invoice)).all()) == 3
    assert len(db_session.scalars(select(SellerTransaction)).all()) == 4
