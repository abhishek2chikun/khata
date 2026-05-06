# Backend — agent.md

Role: FastAPI + PostgreSQL backend for auth, inventory, sellers, khata ledger, invoicing, and all business-data writes.

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
- sellers: CRUD-ish management, opening balance, payments, balance adjustment, ledger view
- company profile: active company profile read/upsert
- invoices: quote, create, list, detail, cancel
- payments: top-level payment creation route backed by seller ledger logic

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
| Sellers + ledger domain | Done | `backend/app/services/seller_service.py`, `backend/app/routers/sellers.py` | None yet |
| Company profile domain | Done | `backend/app/services/company_profile_service.py`, `backend/app/routers/company_profile.py` | None yet |
| Invoice domain | Done | `backend/app/services/invoice_service.py`, `backend/app/routers/invoices.py` | None yet |
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

## Progress

- Auth, session rotation, and secure current-user lookup are live.
- Products, sellers, company profile, payments, and invoice quote/create/list/detail/cancel are live.
- Demo seed data now exists for realistic manual testing.
- Backend test isolation is safer than before because destructive resets are blocked on non-test DB names by default.

## Deferred work

- No legacy SQLite import/migration utility is implemented yet for the older Streamlit data source.
- No child `agent.md` files exist yet under `app/`; future deeper work in `services/`, `routers/`, or `models/` would benefit from them.
- Manual QA still depends on bootstrap + seed commands or direct API calls; there is no admin backend UI in this repo.
