import uuid
from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (
        UniqueConstraint("company", "category", "item_name", name="uq_products_company_category_item_name"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(255), nullable=False)
    item_name: Mapped[str] = mapped_column(String(255), nullable=False)
    item_code: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    buying_price_excl_tax: Mapped[Decimal | None] = mapped_column(Numeric(14, 2), nullable=True)
    buying_gst_rate: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    default_selling_price_excl_tax: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    default_gst_rate: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    quantity_on_hand: Mapped[Decimal] = mapped_column(Numeric(14, 3), nullable=False, default=Decimal("0"))
    low_stock_threshold: Mapped[Decimal] = mapped_column(Numeric(14, 3), nullable=False, default=Decimal("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))
