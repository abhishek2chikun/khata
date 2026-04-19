from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Internal Billing and Khata API"
    environment: str = "development"
    secret_key: str = Field(default="dev-secret-key-change-me-at-least-32chars")
    access_token_expire_minutes: int = 30
    algorithm: str = "HS256"
    database_url: str = "postgresql+psycopg://localhost/internal_billing"

    model_config = SettingsConfigDict(env_prefix="BILLING_", extra="ignore")

    @model_validator(mode="after")
    def validate_secret_key(self) -> "Settings":
        if self.environment != "development" and self.secret_key == "dev-secret-key-change-me-at-least-32chars":
            raise ValueError("BILLING_SECRET_KEY must be set outside development")
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
