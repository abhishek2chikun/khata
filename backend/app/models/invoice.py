import uuid
from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import BigInteger, CheckConstraint, Date, DateTime, ForeignKey, Numeric, Sequence, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, validates

from app.core.tax import resolve_place_of_supply_state
from app.models.base import Base

invoice_number_seq = Sequence("invoice_number_seq")


class Invoice(Base):
    __tablename__ = "invoices"
    __table_args__ = (
        CheckConstraint("tax_regime IN ('INTRA_STATE', 'INTER_STATE')", name="ck_invoices_tax_regime"),
        CheckConstraint("status IN ('ACTIVE', 'CANCELED')", name="ck_invoices_status"),
        CheckConstraint("payment_mode IN ('PAID', 'CREDIT')", name="ck_invoices_payment_mode"),
        CheckConstraint(
            "(status = 'ACTIVE' AND cancel_request_id IS NULL AND cancel_request_hash IS NULL AND canceled_by_user_id IS NULL AND cancel_reason IS NULL AND canceled_at IS NULL) OR "
            "(status = 'CANCELED' AND cancel_request_id IS NOT NULL AND cancel_request_hash IS NOT NULL AND canceled_by_user_id IS NOT NULL AND cancel_reason IS NOT NULL AND canceled_at IS NOT NULL)",
            name="ck_invoices_cancel_fields",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    request_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, unique=True)
    request_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    invoice_number: Mapped[int] = mapped_column(
        BigInteger,
        invoice_number_seq,
        server_default=invoice_number_seq.next_value(),
        nullable=False,
        unique=True,
    )
    seller_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sellers.id"), nullable=False)
    seller_name: Mapped[str] = mapped_column(Text, nullable=False)
    seller_address: Mapped[str] = mapped_column(Text, nullable=False)
    seller_state: Mapped[str | None] = mapped_column(Text, nullable=True)
    seller_state_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    seller_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    seller_gstin: Mapped[str | None] = mapped_column(String(50), nullable=True)
    place_of_supply_state: Mapped[str] = mapped_column(Text, nullable=False)
    place_of_supply_state_code: Mapped[str] = mapped_column(String(50), nullable=False)
    company_name: Mapped[str] = mapped_column(Text, nullable=False)
    company_address: Mapped[str] = mapped_column(Text, nullable=False)
    company_city: Mapped[str] = mapped_column(Text, nullable=False)
    company_state: Mapped[str] = mapped_column(Text, nullable=False)
    company_state_code: Mapped[str] = mapped_column(String(50), nullable=False)
    company_gstin: Mapped[str | None] = mapped_column(String(50), nullable=True)
    company_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    company_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    company_bank_name: Mapped[str | None] = mapped_column(Text, nullable=True)
    company_bank_account: Mapped[str | None] = mapped_column(String(255), nullable=True)
    company_bank_ifsc: Mapped[str | None] = mapped_column(String(100), nullable=True)
    company_bank_branch: Mapped[str | None] = mapped_column(Text, nullable=True)
    company_jurisdiction: Mapped[str | None] = mapped_column(Text, nullable=True)
    invoice_date: Mapped[date] = mapped_column(Date, nullable=False)
    tax_regime: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="ACTIVE")
    payment_mode: Mapped[str] = mapped_column(String(32), nullable=False)
    subtotal: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    discount_total: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    taxable_total: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    gst_total: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    grand_total: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("app_users.id"), nullable=False)
    cancel_request_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True, unique=True)
    cancel_request_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    canceled_by_user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("app_users.id"), nullable=True)
    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    canceled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC))

    @validates("place_of_supply_state_code")
    def derive_place_of_supply_state(self, _: str, value: str) -> str:
        self.place_of_supply_state = resolve_place_of_supply_state(value)
        return value
