import pytest
from datetime import date
from decimal import Decimal

from app.schemas.analytics import (
    DashboardResponse,
    RevenueByEntry,
    ProfitByEntry,
    CustomerKhataBalance,
    BuyerPayable,
    TopProduct,
    TopProductRevenue,
    TopProductProfit,
    LowStockEntry,
)


@pytest.mark.no_db
class TestAnalyticsSchemas:
    def test_dashboard_response_allows_empty_lists(self):
        resp = DashboardResponse(
            revenue_by_buyer=[],
            profit_by_buyer=[],
            revenue_by_company=[],
            profit_by_company=[],
            revenue_by_customer=[],
            customer_khata_balances=[],
            buyer_pending_payables=[],
            top_products_by_quantity=[],
            top_products_by_revenue=[],
            top_products_by_profit=[],
            low_stock=[],
        )
        assert resp.revenue_by_buyer == []
        assert resp.low_stock == []

    def test_dashboard_response_accepts_populated_data(self):
        resp = DashboardResponse(
            revenue_by_buyer=[RevenueByEntry(name="Buyer A", revenue=Decimal("100.00"))],
            profit_by_buyer=[ProfitByEntry(name="Buyer A", profit=Decimal("50.00"))],
            revenue_by_company=[RevenueByEntry(name="Acme Corp", revenue=Decimal("100.00"))],
            profit_by_company=[ProfitByEntry(name="Acme Corp", profit=Decimal("50.00"))],
            revenue_by_customer=[RevenueByEntry(name="Customer A", revenue=Decimal("200.00"))],
            customer_khata_balances=[CustomerKhataBalance(customer_name="Customer A", balance=Decimal("150.00"))],
            buyer_pending_payables=[BuyerPayable(buyer_name="Buyer A", payable=Decimal("300.00"))],
            top_products_by_quantity=[TopProduct(product_name="Prod X", quantity=Decimal("5.000"))],
            top_products_by_revenue=[TopProductRevenue(product_name="Prod X", revenue=Decimal("500.00"))],
            top_products_by_profit=[TopProductProfit(product_name="Prod X", profit=Decimal("250.00"))],
            low_stock=[LowStockEntry(product_name="Prod X", quantity_on_hand=Decimal("1.000"), low_stock_threshold=Decimal("5.000"))],
        )
        assert resp.revenue_by_buyer[0].name == "Buyer A"
        assert resp.revenue_by_buyer[0].revenue == Decimal("100.00")
        assert resp.customer_khata_balances[0].balance == Decimal("150.00")
        assert resp.buyer_pending_payables[0].payable == Decimal("300.00")
        assert resp.top_products_by_quantity[0].quantity == Decimal("5.000")
        assert resp.low_stock[0].quantity_on_hand == Decimal("1.000")

    def test_dashboard_response_serializes_to_json(self):
        resp = DashboardResponse(
            revenue_by_buyer=[],
            profit_by_buyer=[],
            revenue_by_company=[],
            profit_by_company=[],
            revenue_by_customer=[],
            customer_khata_balances=[],
            buyer_pending_payables=[],
            top_products_by_quantity=[],
            top_products_by_revenue=[],
            top_products_by_profit=[],
            low_stock=[],
        )
        data = resp.model_dump()
        assert data["revenue_by_buyer"] == []
        assert data["low_stock"] == []

    def test_revenue_by_entry_preserves_decimal_precision(self):
        entry = RevenueByEntry(name="Buyer A", revenue=Decimal("12345.67"))
        assert entry.revenue == Decimal("12345.67")

    def test_low_stock_entry_fields(self):
        entry = LowStockEntry(
            product_name="Widget",
            quantity_on_hand=Decimal("2.500"),
            low_stock_threshold=Decimal("10.000"),
        )
        assert entry.product_name == "Widget"
        assert entry.quantity_on_hand == Decimal("2.500")
        assert entry.low_stock_threshold == Decimal("10.000")


@pytest.mark.no_db
class TestAnalyticsServiceFunctionSignature:
    def test_get_dashboard_exists_and_has_correct_signature(self):
        from app.services.analytics_service import get_dashboard
        import inspect
        sig = inspect.signature(get_dashboard)
        params = list(sig.parameters.keys())
        assert "session" in params
        assert "from_date" in params
        assert "to_date" in params

    def test_get_dashboard_returns_dict_with_all_keys(self):
        from unittest.mock import MagicMock
        from app.services.analytics_service import get_dashboard

        mock_session = MagicMock()
        mock_session.execute.return_value = MagicMock(all=MagicMock(return_value=[]))
        mock_session.scalar.return_value = []

        result = get_dashboard(mock_session)

        expected_keys = [
            "revenue_by_buyer", "profit_by_buyer",
            "revenue_by_company", "profit_by_company",
            "revenue_by_customer", "customer_khata_balances",
            "buyer_pending_payables",
            "top_products_by_quantity", "top_products_by_revenue", "top_products_by_profit",
            "low_stock",
        ]
        for key in expected_keys:
            assert key in result, f"Missing key: {key}"

    def test_get_dashboard_returns_empty_lists_with_mocked_empty_db(self):
        from unittest.mock import MagicMock
        from app.services.analytics_service import get_dashboard

        mock_session = MagicMock()
        mock_session.execute.return_value = MagicMock(all=MagicMock(return_value=[]))

        result = get_dashboard(mock_session)

        assert result["revenue_by_buyer"] == []
        assert result["profit_by_buyer"] == []
        assert result["revenue_by_company"] == []
        assert result["profit_by_company"] == []
        assert result["revenue_by_customer"] == []
        assert result["customer_khata_balances"] == []
        assert result["buyer_pending_payables"] == []
        assert result["top_products_by_quantity"] == []
        assert result["top_products_by_revenue"] == []
        assert result["top_products_by_profit"] == []
        assert result["low_stock"] == []

    def test_get_dashboard_with_date_filters(self):
        from unittest.mock import MagicMock, call
        from app.services.analytics_service import get_dashboard

        mock_session = MagicMock()
        mock_session.execute.return_value = MagicMock(all=MagicMock(return_value=[]))

        result = get_dashboard(
            mock_session,
            from_date=date(2026, 4, 1),
            to_date=date(2026, 4, 30),
        )
        assert result["revenue_by_buyer"] == []


@pytest.mark.no_db
class TestAnalyticsRouter:
    def test_analytics_router_has_dashboard_endpoint(self):
        from app.routers.analytics import router
        routes = [(r.path, r.methods) for r in router.routes]
        assert any("/dashboard" in path for path, _ in routes)

    def test_analytics_router_prefix(self):
        from app.routers.analytics import router
        assert router.prefix == "/analytics"
