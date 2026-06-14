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
    DailyTrendEntry,
)


def _empty_dashboard_kwargs(**overrides):
    base = {
        "total_revenue": Decimal("0"),
        "total_profit": Decimal("0"),
        "customer_receivables": Decimal("0"),
        "buyer_payables": Decimal("0"),
        "active_invoice_count": 0,
        "average_invoice_value": Decimal("0"),
        "daily_trend": [],
        "revenue_by_buyer": [],
        "profit_by_buyer": [],
        "revenue_by_company": [],
        "profit_by_company": [],
        "revenue_by_customer": [],
        "customer_khata_balances": [],
        "buyer_pending_payables": [],
        "top_products_by_quantity": [],
        "top_products_by_revenue": [],
        "top_products_by_profit": [],
        "low_stock": [],
    }
    base.update(overrides)
    return base


def _empty_dashboard_execute_side_effect(*args, **kwargs):
    from unittest.mock import MagicMock

    result = MagicMock()
    result.all.return_value = []
    result.one.return_value = (Decimal("0"), Decimal("0"))
    return result


@pytest.mark.no_db
class TestAnalyticsSchemas:
    def test_dashboard_response_allows_empty_lists(self):
        resp = DashboardResponse(**_empty_dashboard_kwargs())
        assert resp.revenue_by_buyer == []
        assert resp.low_stock == []
        assert resp.total_revenue == Decimal("0")
        assert resp.daily_trend == []

    def test_dashboard_response_accepts_populated_data(self):
        resp = DashboardResponse(
            **_empty_dashboard_kwargs(
                total_revenue=Decimal("500.00"),
                total_profit=Decimal("250.00"),
                customer_receivables=Decimal("150.00"),
                buyer_payables=Decimal("300.00"),
                active_invoice_count=2,
                average_invoice_value=Decimal("250.00"),
                daily_trend=[
                    DailyTrendEntry(
                        date=date(2026, 4, 1),
                        revenue=Decimal("500.00"),
                        profit=Decimal("250.00"),
                    )
                ],
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
        )
        assert resp.revenue_by_buyer[0].name == "Buyer A"
        assert resp.revenue_by_buyer[0].revenue == Decimal("100.00")
        assert resp.customer_khata_balances[0].balance == Decimal("150.00")
        assert resp.buyer_pending_payables[0].payable == Decimal("300.00")
        assert resp.top_products_by_quantity[0].quantity == Decimal("5.000")
        assert resp.low_stock[0].quantity_on_hand == Decimal("1.000")

    def test_dashboard_response_serializes_to_json(self):
        resp = DashboardResponse(**_empty_dashboard_kwargs())
        data = resp.model_dump()
        assert data["revenue_by_buyer"] == []
        assert data["low_stock"] == []
        assert data["total_revenue"] == Decimal("0")
        assert data["daily_trend"] == []

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
        mock_session.execute.side_effect = _empty_dashboard_execute_side_effect

        result = get_dashboard(mock_session)

        expected_keys = [
            "total_revenue", "total_profit", "customer_receivables", "buyer_payables",
            "active_invoice_count", "average_invoice_value", "daily_trend",
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
        mock_session.execute.side_effect = _empty_dashboard_execute_side_effect

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
        from unittest.mock import MagicMock
        from app.services.analytics_service import get_dashboard

        mock_session = MagicMock()
        mock_session.execute.side_effect = _empty_dashboard_execute_side_effect

        result = get_dashboard(
            mock_session,
            from_date=date(2026, 4, 1),
            to_date=date(2026, 4, 30),
        )
        assert result["revenue_by_buyer"] == []


@pytest.mark.no_db
class TestServiceSchemaKeyAlignment:
    def test_populated_service_output_constructs_valid_dashboard_response(self):
        from unittest.mock import MagicMock
        from app.services.analytics_service import get_dashboard

        buyer_row = MagicMock()
        buyer_row.buyer_name = "Buyer A"
        buyer_row.revenue = Decimal("100.00")
        buyer_row.profit = Decimal("50.00")

        company_row = MagicMock()
        company_row.company_name = "Acme Corp"
        company_row.revenue = Decimal("200.00")
        company_row.profit = Decimal("80.00")

        customer_rev_row = MagicMock()
        customer_rev_row.customer_name = "Customer X"
        customer_rev_row.revenue = Decimal("300.00")

        customer_khata_row = MagicMock()
        customer_khata_row.customer_name = "Customer X"
        customer_khata_row.balance = Decimal("150.00")

        buyer_payable_row = MagicMock()
        buyer_payable_row.buyer_name = "Buyer A"
        buyer_payable_row.payable = Decimal("400.00")

        product_qty_row = MagicMock()
        product_qty_row.product_name = "Widget"
        product_qty_row.quantity = Decimal("5.000")

        product_rev_row = MagicMock()
        product_rev_row.product_name = "Widget"
        product_rev_row.revenue = Decimal("250.00")

        product_profit_row = MagicMock()
        product_profit_row.product_name = "Widget"
        product_profit_row.profit = Decimal("100.00")

        low_stock_row = MagicMock()
        low_stock_row.Product = MagicMock()
        low_stock_row.Product.item_name = "Widget"
        low_stock_row.Product.quantity_on_hand = Decimal("1.000")
        low_stock_row.Product.low_stock_threshold = Decimal("5.000")

        row_sequences = [
            [customer_khata_row],
            [buyer_payable_row],
            (Decimal("100.00"), Decimal("50.00")),
            (1, Decimal("100.00")),
            [],
            [buyer_row],
            [buyer_row],
            [company_row],
            [company_row],
            [customer_rev_row],
            [product_qty_row],
            [product_rev_row],
            [product_profit_row],
            [low_stock_row],
        ]

        mock_session = MagicMock()
        call_count = 0

        def mock_execute(*args, **kwargs):
            nonlocal call_count
            seq = row_sequences[call_count] if call_count < len(row_sequences) else []
            call_count += 1
            result = MagicMock()
            if isinstance(seq, tuple):
                result.one.return_value = seq
            else:
                result.all.return_value = seq
            return result

        mock_session.execute = mock_execute

        result = get_dashboard(mock_session)
        resp = DashboardResponse(**result)

        assert resp.revenue_by_buyer[0].name == "Buyer A"
        assert resp.revenue_by_buyer[0].revenue == Decimal("100.00")
        assert resp.profit_by_buyer[0].name == "Buyer A"
        assert resp.revenue_by_company[0].name == "Acme Corp"
        assert resp.profit_by_company[0].name == "Acme Corp"
        assert resp.revenue_by_customer[0].name == "Customer X"
        assert resp.customer_khata_balances[0].customer_name == "Customer X"
        assert resp.customer_khata_balances[0].balance == Decimal("150.00")
        assert resp.buyer_pending_payables[0].buyer_name == "Buyer A"
        assert resp.buyer_pending_payables[0].payable == Decimal("400.00")
        assert resp.top_products_by_quantity[0].product_name == "Widget"
        assert resp.top_products_by_revenue[0].revenue == Decimal("250.00")
        assert resp.top_products_by_profit[0].profit == Decimal("100.00")
        assert resp.low_stock[0].quantity_on_hand == Decimal("1.000")
        assert resp.total_revenue == Decimal("100.00")
        assert resp.active_invoice_count == 1

    def test_revenue_by_buyer_dicts_use_name_key(self):
        self._assert_section_key("revenue_by_buyer", "name", "revenue", "Buyer A", Decimal("99.00"))

    def test_profit_by_buyer_dicts_use_name_key(self):
        self._assert_section_key("profit_by_buyer", "name", "profit", "Buyer A", Decimal("40.00"))

    def test_revenue_by_company_dicts_use_name_key(self):
        self._assert_section_key("revenue_by_company", "name", "revenue", "Acme", Decimal("50.00"))

    def test_profit_by_company_dicts_use_name_key(self):
        self._assert_section_key("profit_by_company", "name", "profit", "Acme", Decimal("20.00"))

    def test_revenue_by_customer_dicts_use_name_key(self):
        self._assert_section_key("revenue_by_customer", "name", "revenue", "Cust A", Decimal("77.00"))

    @staticmethod
    def _assert_section_key(section, name_key, value_key, name_val, value_val):
        from app.schemas.analytics import DashboardResponse
        entry = {name_key: name_val, value_key: str(value_val)}
        resp = DashboardResponse(**_empty_dashboard_kwargs(**{section: [entry]}))
        items = getattr(resp, section)
        assert len(items) == 1
        assert items[0].model_dump()[name_key] == name_val
        assert items[0].model_dump()[value_key] == value_val


@pytest.mark.no_db
class TestSnapshotIndependence:
    def test_invoice_item_model_stores_buying_price_snapshot_not_product_reference(self):
        from app.models.invoice_item import InvoiceItem
        import inspect
        source = inspect.getsource(InvoiceItem)
        assert "buying_price" in source
        assert "buying_amount" in source
        assert "profit_amount" in source
        assert "revenue_amount" in source

    def test_analytics_queries_reference_invoice_item_not_product_for_revenue(self):
        import inspect
        from app.services import analytics_service
        source = inspect.getsource(analytics_service)
        for func_name in ["_revenue_by_buyer", "_profit_by_buyer", "_revenue_by_company", "_profit_by_company", "_top_products_by_revenue", "_top_products_by_profit"]:
            assert func_name in source
        assert "InvoiceItem.revenue_amount" in source
        assert "InvoiceItem.profit_amount" in source
        assert "Product.buying_price" not in source
        assert "Product.selling_price" not in source


@pytest.mark.no_db
class TestAnalyticsRouter:
    def test_analytics_router_has_dashboard_endpoint(self):
        from app.routers.analytics import router
        routes = [(r.path, r.methods) for r in router.routes]
        assert any("/dashboard" in path for path, _ in routes)

    def test_analytics_router_prefix(self):
        from app.routers.analytics import router
        assert router.prefix == "/analytics"
