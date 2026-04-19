import uuid
from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, Index, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class CompanyProfile(Base):
    __tablename__ = "company_profiles"
    __table_args__ = (
        Index("uq_company_profiles_single_active", "is_active", unique=True, postgresql_where=text("is_active = true")),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    city: Mapped[str] = mapped_column(String(255), nullable=False)
    state: Mapped[str] = mapped_column(String(255), nullable=False)
    state_code: Mapped[str] = mapped_column(String(50), nullable=False)
    gstin: Mapped[str | None] = mapped_column(String(50), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    bank_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    bank_account: Mapped[str | None] = mapped_column(String(255), nullable=True)
    bank_ifsc: Mapped[str | None] = mapped_column(String(100), nullable=True)
    bank_branch: Mapped[str | None] = mapped_column(String(255), nullable=True)
    jurisdiction: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))
