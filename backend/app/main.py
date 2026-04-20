from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.routers.company_profile import router as company_profile_router
from app.routers.invoices import router as invoices_router
from app.routers.products import router as products_router
from app.routers.sellers import router as sellers_router
from app.routers.auth import router as auth_router
from fastapi import Depends
from sqlalchemy.orm import Session
from app.auth import get_current_user
from app.db import get_db
from app.schemas.auth import CurrentUserResponse
from app.schemas.seller import PaymentRequest, SellerTransactionResponse
from app.services import seller_service


def create_app() -> FastAPI:
    app = FastAPI(title="Internal Billing and Khata API")

    @app.exception_handler(HTTPException)
    async def http_exception_handler(_: Request, exc: HTTPException) -> JSONResponse:
        if isinstance(exc.detail, dict) and "error" in exc.detail:
            return JSONResponse(status_code=exc.status_code, content=exc.detail)
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": "HTTP_ERROR", "message": str(exc.detail)}},
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(_: Request, __: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=400,
            content={"error": {"code": "VALIDATION_ERROR", "message": "Request validation failed"}},
        )

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.include_router(products_router)
    app.include_router(sellers_router)
    app.include_router(company_profile_router)
    app.include_router(invoices_router)

    @app.post("/payments", response_model=SellerTransactionResponse, status_code=201)
    def create_payment(payload: PaymentRequest, current_user: CurrentUserResponse = Depends(get_current_user), session: Session = Depends(get_db)) -> SellerTransactionResponse:
        transaction = seller_service.create_payment(session, payload, current_user)
        return SellerTransactionResponse.model_validate(transaction)

    return app


app = create_app()
