import uuid
from datetime import UTC, datetime, date
from decimal import Decimal

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index, Numeric, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class SellerTransaction(Base):
    __tablename__ = "seller_transactions"
    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_seller_transactions_amount_positive"),
        CheckConstraint(
            "(entry_type IN ('OPENING_BALANCE','PAYMENT','BALANCE_INCREASE_ADJUSTMENT','BALANCE_DECREASE_ADJUSTMENT') AND invoice_id IS NULL AND request_id IS NOT NULL AND request_hash IS NOT NULL) OR "
            "(entry_type IN ('CREDIT_SALE','INVOICE_CANCEL_REVERSAL') AND invoice_id IS NOT NULL AND request_id IS NULL AND request_hash IS NULL)",
            name="ck_seller_transactions_shape",
        ),
        Index("uq_seller_transactions_opening_balance", "seller_id", unique=True, postgresql_where=text("entry_type = 'OPENING_BALANCE'")),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sellers.id"), nullable=False)
    invoice_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("invoices.id"), nullable=True)
    request_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True, unique=True)
    request_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    entry_type: Mapped[str] = mapped_column(String(64), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    occurred_on: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_by_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("app_users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC))
