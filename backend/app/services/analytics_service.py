from datetime import date
from decimal import Decimal

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.models.buyer import Buyer
from app.models.buyer_transaction import BuyerTransaction
from app.models.customer import Customer
from app.models.customer_transaction import CustomerTransaction
from app.models.invoice import Invoice
from app.models.invoice_item import InvoiceItem
from app.models.product import Product


def get_dashboard(
    session: Session,
    *,
    from_date: date | None = None,
    to_date: date | None = None,
) -> dict:
    invoice_base = select(Invoice.id).where(Invoice.status == "ACTIVE")
    if from_date is not None:
        invoice_base = invoice_base.where(Invoice.invoice_date >= from_date)
    if to_date is not None:
        invoice_base = invoice_base.where(Invoice.invoice_date <= to_date)

    active_invoice_ids = invoice_base.subquery()

    return {
        "revenue_by_buyer": _revenue_by_buyer(session, active_invoice_ids),
        "profit_by_buyer": _profit_by_buyer(session, active_invoice_ids),
        "revenue_by_company": _revenue_by_company(session, active_invoice_ids),
        "profit_by_company": _profit_by_company(session, active_invoice_ids),
        "revenue_by_customer": _revenue_by_customer(session, active_invoice_ids),
        "customer_khata_balances": _customer_khata_balances(session),
        "buyer_pending_payables": _buyer_pending_payables(session),
        "top_products_by_quantity": _top_products_by_quantity(session, active_invoice_ids),
        "top_products_by_revenue": _top_products_by_revenue(session, active_invoice_ids),
        "top_products_by_profit": _top_products_by_profit(session, active_invoice_ids),
        "low_stock": _low_stock(session),
    }


def _revenue_by_buyer(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            Buyer.name.label("buyer_name"),
            func.sum(InvoiceItem.revenue_amount).label("revenue"),
        )
        .join(InvoiceItem, InvoiceItem.product_buyer_id == Buyer.id)
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(Buyer.name)
        .order_by(Buyer.name)
    ).all()
    return [{"buyer_name": r.buyer_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


def _profit_by_buyer(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            Buyer.name.label("buyer_name"),
            func.sum(InvoiceItem.profit_amount).label("profit"),
        )
        .join(InvoiceItem, InvoiceItem.product_buyer_id == Buyer.id)
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(Buyer.name)
        .order_by(Buyer.name)
    ).all()
    return [{"buyer_name": r.buyer_name, "profit": Decimal(r.profit or 0)} for r in rows]


def _revenue_by_company(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            InvoiceItem.product_company_name.label("company_name"),
            func.sum(InvoiceItem.revenue_amount).label("revenue"),
        )
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(InvoiceItem.product_company_name)
        .order_by(InvoiceItem.product_company_name)
    ).all()
    return [{"company_name": r.company_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


def _profit_by_company(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            InvoiceItem.product_company_name.label("company_name"),
            func.sum(InvoiceItem.profit_amount).label("profit"),
        )
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(InvoiceItem.product_company_name)
        .order_by(InvoiceItem.product_company_name)
    ).all()
    return [{"company_name": r.company_name, "profit": Decimal(r.profit or 0)} for r in rows]


def _revenue_by_customer(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            Invoice.customer_name,
            func.sum(Invoice.grand_total).label("revenue"),
        )
        .where(Invoice.id.in_(select(active_invoice_ids.c.id)))
        .group_by(Invoice.customer_name)
        .order_by(Invoice.customer_name)
    ).all()
    return [{"customer_name": r.customer_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


def _customer_khata_balances(session: Session) -> list[dict]:
    credit_types = ["OPENING_BALANCE", "CREDIT_SALE", "BALANCE_INCREASE_ADJUSTMENT", "COLLECTION_REVERSAL"]
    rows = session.execute(
        select(
            Customer.name.label("customer_name"),
            func.coalesce(
                func.sum(
                    case(
                        (CustomerTransaction.entry_type.in_(credit_types), CustomerTransaction.amount),
                        else_=-CustomerTransaction.amount,
                    )
                ),
                0,
            ).label("balance"),
        )
        .join(CustomerTransaction, CustomerTransaction.customer_id == Customer.id)
        .group_by(Customer.name)
        .order_by(Customer.name)
    ).all()
    return [{"customer_name": r.customer_name, "balance": Decimal(r.balance or 0)} for r in rows]


def _buyer_pending_payables(session: Session) -> list[dict]:
    increase_types = ["OPENING_PAYABLE", "PURCHASE_AMOUNT", "PAYABLE_INCREASE_ADJUSTMENT"]
    rows = session.execute(
        select(
            Buyer.name.label("buyer_name"),
            func.coalesce(
                func.sum(
                    case(
                        (BuyerTransaction.entry_type.in_(increase_types), BuyerTransaction.amount),
                        else_=-BuyerTransaction.amount,
                    )
                ),
                0,
            ).label("payable"),
        )
        .join(BuyerTransaction, BuyerTransaction.buyer_id == Buyer.id)
        .group_by(Buyer.name)
        .order_by(Buyer.name)
    ).all()
    return [{"buyer_name": r.buyer_name, "payable": Decimal(r.payable or 0)} for r in rows]


def _top_products_by_quantity(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            InvoiceItem.product_item_name.label("product_name"),
            func.sum(InvoiceItem.quantity).label("quantity"),
        )
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(InvoiceItem.product_item_name)
        .order_by(func.sum(InvoiceItem.quantity).desc())
    ).all()
    return [{"product_name": r.product_name, "quantity": Decimal(r.quantity or 0)} for r in rows]


def _top_products_by_revenue(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            InvoiceItem.product_item_name.label("product_name"),
            func.sum(InvoiceItem.revenue_amount).label("revenue"),
        )
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(InvoiceItem.product_item_name)
        .order_by(func.sum(InvoiceItem.revenue_amount).desc())
    ).all()
    return [{"product_name": r.product_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


def _top_products_by_profit(session: Session, active_invoice_ids) -> list[dict]:
    rows = session.execute(
        select(
            InvoiceItem.product_item_name.label("product_name"),
            func.sum(InvoiceItem.profit_amount).label("profit"),
        )
        .where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
        .group_by(InvoiceItem.product_item_name)
        .order_by(func.sum(InvoiceItem.profit_amount).desc())
    ).all()
    return [{"product_name": r.product_name, "profit": Decimal(r.profit or 0)} for r in rows]


def _low_stock(session: Session) -> list[dict]:
    rows = session.execute(
        select(Product)
        .where(Product.is_active.is_(True), Product.quantity_on_hand <= Product.low_stock_threshold)
        .order_by(Product.item_name)
    ).all()
    return [
        {
            "product_name": row.Product.item_name,
            "quantity_on_hand": Decimal(row.Product.quantity_on_hand),
            "low_stock_threshold": Decimal(row.Product.low_stock_threshold),
        }
        for row in rows
    ]
