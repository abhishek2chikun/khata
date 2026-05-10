# Backend — agent.md

Role: FastAPI + PostgreSQL backend for auth, inventory, customers, buyers, khata ledger, invoicing, analytics, and all business-data writes.

## Wholesaler Terminology

- **Buyer**: a supplier/vendor. Products link to buyers. Buyers have a payable ledger.
- **Customer**: a retail customer/shop. Customers have a receivable ledger.
- **Product**: inventory item with V2 fields: `buyer_id`, `company_name`, `buying_price`, `selling_price`.
- **Invoice**: sale document with payment state (`CREDIT`, `PARTIAL_PAID`, `TOTAL_PAID`), stock/ledger side effects.
- **Analytics**: `/analytics/dashboard` endpoint with revenue/profit by buyer/company/customer, top products, low stock, khata balances, buyer payables.

## How to use this system

- Treat the backend as the only writer of business data. Mobile should only call HTTP APIs.
- Run migrations before starting the API. Create a bootstrap user before testing login.
- Use the demo seed command for realistic manual QA data instead of ad-hoc SQL.
- Run backend tests only against a dedicated test database unless you intentionally opt into destructive resets.
- Child backend modules should own their internal details through their own `agent.md` files if those are added later.

## Project overview

This backend serves a mobile-first internal billing and khata workflow. The live API currently includes:

- auth: login, refresh, logout, current user
- products: CRUD-ish management plus manual stock adjustment
- customers: CRUD-ish management, opening balance, collections, balance adjustment, ledger view
- buyers: CRUD-ish management, opening payable, purchase amounts, payments made, payable adjustments, payable ledger view
- company profile: active company profile read/upsert
- invoices: quote, create, list, detail, cancel
- collections: top-level collection creation route backed by customer khata ledger logic
- analytics: dashboard endpoint with revenue/profit breakdowns, top products, low stock, and balance summaries

Important live behavior:

- Business routes require bearer auth.
- Error responses are normalized into an `{error: {code, message}}` envelope.
- Retry-prone writes use `request_id` and canonical request hashing for idempotency.
- Invoice creation and cancellation own stock and ledger side effects transactionally.
- Manual QA data can be seeded via `app.commands.seed_demo_data`.

## Directory structure

```text
backend/
  agent.md
  pyproject.toml
  alembic.ini
  alembic/
    env.py
    versions/
  app/
    __init__.py
    main.py
    auth.py
    config.py
    db.py
    commands/
      bootstrap_user.py
      seed_demo_data.py
    core/
    models/
    routers/
    schemas/
    services/
  tests/
    conftest.py
    api/
    commands/
    services/
    test_app_import.py
```

## Module status

| Module | Status | Location | `agent.md` |
|---|---|---|---|
| API app entry | Done | `backend/app/main.py` | None yet |
| Auth/session flow | Done | `backend/app/auth.py`, `backend/app/services/auth_service.py`, `backend/app/routers/auth.py` | None yet |
| Config and DB | Done | `backend/app/config.py`, `backend/app/db.py` | None yet |
| Core financial helpers | Done | `backend/app/core/` | None yet |
| Persistence models | Done | `backend/app/models/` | None yet |
| Request/response schemas | Done | `backend/app/schemas/` | None yet |
| Products domain | Done | `backend/app/services/product_service.py`, `backend/app/routers/products.py` | None yet |
| Customers + ledger domain | Done | `backend/app/services/customer_service.py`, `backend/app/routers/customers.py` | None yet |
| Buyers + payable ledger domain | Done | `backend/app/services/buyer_service.py`, `backend/app/routers/buyers.py` | None yet |
| Company profile domain | Done | `backend/app/services/company_profile_service.py`, `backend/app/routers/company_profile.py` | None yet |
| Invoice domain | Done | `backend/app/services/invoice_service.py`, `backend/app/routers/invoices.py` | None yet |
| Analytics domain | Done | `backend/app/services/analytics_service.py`, `backend/app/routers/analytics.py` | None yet |
| CLI commands | Done | `backend/app/commands/` | None yet |
| Alembic migrations | Done | `backend/alembic/versions/` | None yet |
| Backend tests | Done — needs dedicated test DB discipline | `backend/tests/` | None yet |

## Conventions

- Import style uses the `app.*` package path.
- Service modules own business rules, idempotency checks, commits, and side effects.
- Routers stay thin and mostly translate HTTP payloads into service calls.
- Schemas mirror the wire contract; Pydantic validation errors are wrapped into the shared error envelope.
- All meaningful backend tests run against PostgreSQL, not SQLite.
- `backend/tests/conftest.py` now refuses to run destructive tests against a non-test database unless `BILLING_ALLOW_TEST_DATABASE_RESET=1` is set.
- Use deterministic seed data for manual QA through `app.commands.seed_demo_data` rather than editing live rows by hand.

## Verification commands

```bash
# Migrate local dev DB
(cd /Users/abhishek/python_venv/khata_app/backend && \
  BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  ../.venv/bin/python -m alembic upgrade head)

# Bootstrap first user
(cd /Users/abhishek/python_venv/khata_app && \
  BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m app.commands.bootstrap_user --username owner --password secret123 --display-name Owner)

# Seed manual QA data
(cd /Users/abhishek/python_venv/khata_app && \
  BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m app.commands.seed_demo_data --username owner)

# Run API on the current dev port
(cd /Users/abhishek/python_venv/khata_app && \
  BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m uvicorn app.main:app --app-dir backend --reload --port 8010)

# Run backend tests on a dedicated test DB
(cd /Users/abhishek/python_venv/khata_app && \
  BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' \
  PYTHONPATH=backend \
  .venv/bin/python -m pytest backend/tests -q)
```

## Local-to-server migration readiness

The mobile local mode (Drift/SQLite) schema is aligned with backend PostgreSQL
tables for future server migration. Every local table has a server equivalent
or is intentionally local-only:

- Migratable tables: local_users → app_users, products, customers, buyers,
  company_profiles, invoices, invoice_items, stock_movements,
  customer_transactions, buyer_transactions.
- Local-only tables (excluded from migration): local_sessions, backup_settings,
  backup_events.
- Key type differences: local uses text IDs, server uses UUID; local stores
  decimals as text strings, server uses Numeric columns.
- Server invoice_items has computed analytics columns (revenue_amount,
  buying_amount, profit_amount) not present in local backup; these are derived
  during migration.

## Progress

- Auth, session rotation, and secure current-user lookup are live.
- Products, customers, buyers, company profile, collections, invoice quote/create/list/detail/cancel, and analytics dashboard are live.
- Demo seed data now exists for realistic manual testing.
- Backend test isolation is safer than before because destructive resets are blocked on non-test DB names by default.
- Wholesaler workflow complete: buyer CRUD and payable ledger, invoice V2 with payment state and snapshot fields, analytics dashboard, customer naming migration.

## Deferred work

- No legacy SQLite import/migration utility is implemented yet for the older Streamlit data source.
- No child `agent.md` files exist yet under `app/`; future deeper work in `services/`, `routers/`, or `models/` would benefit from them.
- Manual QA still depends on bootstrap + seed commands or direct API calls; there is no admin backend UI in this repo.
