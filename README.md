# Internal Billing and Khata System

Flutter + FastAPI + PostgreSQL internal billing system.

Implementation is tracked in:

- `docs/superpowers/specs/2026-04-19-internal-billing-khata-design.md`
- `docs/superpowers/plans/2026-04-19-internal-billing-khata-implementation.md`

## PostgreSQL Setup

Start the local PostgreSQL test database container:

```bash
docker run --name khata-postgres \
  -e POSTGRES_USER=khata \
  -e POSTGRES_PASSWORD=khata \
  -e POSTGRES_DB=internal_billing \
  -p 55432:5432 \
  -d postgres:16
```

If the container already exists, start it with:

```bash
docker start khata-postgres
```

Backend commands below assume this database URL:

```bash
export BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing'
```

## Backend Setup

Create and activate a virtual environment, then install backend dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e backend
```

## Alembic Migrations

Run migrations from the backend directory:

```bash
(cd backend && BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' ../.venv/bin/python -m alembic upgrade head)
```

Check the current revision:

```bash
(cd backend && BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' ../.venv/bin/python -m alembic current)
```

## First User Bootstrap

Create the initial backend user before logging in from the app:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m app.commands.bootstrap_user \
  --username owner \
  --password secret123 \
  --display-name Owner
```

## Run The Backend

Start the FastAPI app from the repository root:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m uvicorn app.main:app --app-dir backend --reload
```

## Run The Flutter App

Install Dart and Flutter dependencies from the Flutter project root, then launch the mobile app:

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter run -d <device-id>)
```

## Run Tests

Reset the database schema before a full backend verification run:

```bash
docker exec khata-postgres psql -U khata -d internal_billing -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

Run the full backend suite:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m pytest backend/tests -q
```

Run the targeted end-to-end backend test:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m pytest backend/tests/api/test_end_to_end_flow.py -q
```

Run the mobile test suite:

```bash
(cd mobile && flutter test test)
```
