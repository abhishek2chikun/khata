from decimal import Decimal

from app.services.analytics_service import get_dashboard
from tests.fixtures.analytics_owner_parity import (
    EXPECTED_ACTIVE_INVOICE_COUNT,
    EXPECTED_AVERAGE_INVOICE_VALUE,
    EXPECTED_BUYER_PAYABLES,
    EXPECTED_CUSTOMER_RECEIVABLES,
    EXPECTED_DAILY_TREND,
    EXPECTED_TOTAL_PROFIT,
    EXPECTED_TOTAL_REVENUE,
    PARITY_FROM_DATE,
    PARITY_TO_DATE,
    seed_owner_analytics_parity,
)


def test_owner_analytics_parity_kpis_and_trend(db_session):
    seed_owner_analytics_parity(db_session)

    result = get_dashboard(
        db_session,
        from_date=PARITY_FROM_DATE,
        to_date=PARITY_TO_DATE,
    )

    assert result["total_revenue"] == EXPECTED_TOTAL_REVENUE
    assert result["total_profit"] == EXPECTED_TOTAL_PROFIT
    assert result["active_invoice_count"] == EXPECTED_ACTIVE_INVOICE_COUNT
    assert result["average_invoice_value"] == EXPECTED_AVERAGE_INVOICE_VALUE
    assert result["customer_receivables"] == EXPECTED_CUSTOMER_RECEIVABLES
    assert result["buyer_payables"] == EXPECTED_BUYER_PAYABLES

    assert len(result["daily_trend"]) == len(EXPECTED_DAILY_TREND)
    for actual, expected in zip(result["daily_trend"], EXPECTED_DAILY_TREND, strict=True):
        assert actual["date"] == expected["date"]
        assert actual["revenue"] == expected["revenue"]
        assert actual["profit"] == expected["profit"]

    trend_revenue = sum(point["revenue"] for point in result["daily_trend"])
    trend_profit = sum(point["profit"] for point in result["daily_trend"])
    assert trend_revenue == result["total_revenue"]
    assert trend_profit == result["total_profit"]

    top_revenue = result["top_products_by_revenue"]
    assert top_revenue[0]["product_name"] == "Plain Widget"
    assert top_revenue[0]["revenue"] == Decimal("250.00")

    by_customer = {entry["name"]: entry for entry in result["revenue_by_customer"]}
    assert by_customer["Parity Customer"]["revenue"] == Decimal("350.00")

    assert isinstance(result["low_stock"], list)
