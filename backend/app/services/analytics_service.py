from datetime import date, timedelta
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

    customer_khata_balances = _customer_khata_balances(session)
    buyer_pending_payables = _buyer_pending_payables(session)
    total_revenue, total_profit = _totals_from_items(session, active_invoice_ids)
    active_invoice_count, average_invoice_value = _invoice_stats(session, active_invoice_ids)
    daily_trend = _daily_trend(
        session,
        active_invoice_ids,
        from_date=from_date,
        to_date=to_date,
    )

    return {
        "total_revenue": total_revenue,
        "total_profit": total_profit,
        "customer_receivables": _sum_receivables(customer_khata_balances),
        "buyer_payables": _sum_payables(buyer_pending_payables),
        "active_invoice_count": active_invoice_count,
        "average_invoice_value": average_invoice_value,
        "daily_trend": daily_trend,
        "revenue_by_buyer": _revenue_by_buyer(session, active_invoice_ids),
        "profit_by_buyer": _profit_by_buyer(session, active_invoice_ids),
        "revenue_by_company": _revenue_by_company(session, active_invoice_ids),
        "profit_by_company": _profit_by_company(session, active_invoice_ids),
        "revenue_by_customer": _revenue_by_customer(session, active_invoice_ids),
        "customer_khata_balances": customer_khata_balances,
        "buyer_pending_payables": buyer_pending_payables,
        "top_products_by_quantity": _top_products_by_quantity(session, active_invoice_ids),
        "top_products_by_revenue": _top_products_by_revenue(session, active_invoice_ids),
        "top_products_by_profit": _top_products_by_profit(session, active_invoice_ids),
        "low_stock": _low_stock(session),
    }


def _sum_receivables(balances: list[dict]) -> Decimal:
    return sum((entry["balance"] for entry in balances), Decimal("0"))


def _sum_payables(payables: list[dict]) -> Decimal:
    return sum((entry["payable"] for entry in payables), Decimal("0"))


def _totals_from_items(session: Session, active_invoice_ids) -> tuple[Decimal, Decimal]:
    row = session.execute(
        select(
            func.coalesce(func.sum(InvoiceItem.revenue_amount), 0),
            func.coalesce(func.sum(InvoiceItem.profit_amount), 0),
        ).where(InvoiceItem.invoice_id.in_(select(active_invoice_ids.c.id)))
    ).one()
    return Decimal(row[0] or 0), Decimal(row[1] or 0)


def _invoice_stats(session: Session, active_invoice_ids) -> tuple[int, Decimal]:
    row = session.execute(
        select(
            func.count(Invoice.id),
            func.coalesce(func.sum(Invoice.grand_total), 0),
        ).where(Invoice.id.in_(select(active_invoice_ids.c.id)))
    ).one()
    count = int(row[0] or 0)
    grand_total = Decimal(row[1] or 0)
    average = grand_total / count if count else Decimal("0")
    return count, average


def _daily_trend(
    session: Session,
    active_invoice_ids,
    *,
    from_date: date | None,
    to_date: date | None,
) -> list[dict]:
    rows = session.execute(
        select(
            Invoice.invoice_date.label("invoice_date"),
            func.coalesce(func.sum(InvoiceItem.revenue_amount), 0).label("revenue"),
            func.coalesce(func.sum(InvoiceItem.profit_amount), 0).label("profit"),
        )
        .join(InvoiceItem, InvoiceItem.invoice_id == Invoice.id)
        .where(Invoice.id.in_(select(active_invoice_ids.c.id)))
        .group_by(Invoice.invoice_date)
        .order_by(Invoice.invoice_date)
    ).all()

    by_date = {
        row.invoice_date: {
            "revenue": Decimal(row.revenue or 0),
            "profit": Decimal(row.profit or 0),
        }
        for row in rows
    }

    if from_date is not None and to_date is not None:
        trend: list[dict] = []
        current = from_date
        while current <= to_date:
            point = by_date.get(
                current,
                {"revenue": Decimal("0"), "profit": Decimal("0")},
            )
            trend.append(
                {
                    "date": current,
                    "revenue": point["revenue"],
                    "profit": point["profit"],
                }
            )
            current += timedelta(days=1)
        return trend

    return [
        {
            "date": invoice_date,
            "revenue": values["revenue"],
            "profit": values["profit"],
        }
        for invoice_date, values in sorted(by_date.items())
    ]


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
    return [{"name": r.buyer_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


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
    return [{"name": r.buyer_name, "profit": Decimal(r.profit or 0)} for r in rows]


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
    return [{"name": r.company_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


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
    return [{"name": r.company_name, "profit": Decimal(r.profit or 0)} for r in rows]


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
    return [{"name": r.customer_name, "revenue": Decimal(r.revenue or 0)} for r in rows]


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
