from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class RevenueByEntry(BaseModel):
    name: str
    revenue: Decimal


class ProfitByEntry(BaseModel):
    name: str
    profit: Decimal


class CustomerKhataBalance(BaseModel):
    customer_name: str
    balance: Decimal


class BuyerPayable(BaseModel):
    buyer_name: str
    payable: Decimal


class TopProduct(BaseModel):
    product_name: str
    quantity: Decimal


class TopProductRevenue(BaseModel):
    product_name: str
    revenue: Decimal


class TopProductProfit(BaseModel):
    product_name: str
    profit: Decimal


class LowStockEntry(BaseModel):
    product_name: str
    quantity_on_hand: Decimal
    low_stock_threshold: Decimal


class DashboardResponse(BaseModel):
    revenue_by_buyer: list[RevenueByEntry]
    profit_by_buyer: list[ProfitByEntry]
    revenue_by_company: list[RevenueByEntry]
    profit_by_company: list[ProfitByEntry]
    revenue_by_customer: list[RevenueByEntry]
    customer_khata_balances: list[CustomerKhataBalance]
    buyer_pending_payables: list[BuyerPayable]
    top_products_by_quantity: list[TopProduct]
    top_products_by_revenue: list[TopProductRevenue]
    top_products_by_profit: list[TopProductProfit]
    low_stock: list[LowStockEntry]
