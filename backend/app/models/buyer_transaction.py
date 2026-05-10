import uuid
from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Numeric, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class BuyerTransaction(Base):
    __tablename__ = "buyer_transactions"
    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_buyer_transactions_amount_positive"),
        CheckConstraint(
            "entry_type IN ('OPENING_PAYABLE','PURCHASE_AMOUNT','PAYMENT_MADE','PAYABLE_INCREASE_ADJUSTMENT','PAYABLE_DECREASE_ADJUSTMENT') "
            "AND request_id IS NOT NULL AND request_hash IS NOT NULL",
            name="ck_buyer_transactions_shape",
        ),
        Index("uq_buyer_transactions_opening_payable", "buyer_id", unique=True, postgresql_where=text("entry_type = 'OPENING_PAYABLE'")),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    buyer_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("buyers.id"), nullable=False)
    request_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True, unique=True)
    request_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    entry_type: Mapped[str] = mapped_column(String(64), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_by_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("app_users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC))
