# Internal Billing and Khata System

Flutter + FastAPI + PostgreSQL internal billing system with an optional
offline-first Flutter local mode backed by Drift/SQLite.

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

## Seed Demo Data

Once the bootstrap user exists, seed a realistic manual-testing dataset:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m app.commands.seed_demo_data \
  --username owner
```

This is safe to re-run. It upserts the active company profile, creates sample customers/products if missing, and creates the same demo ledger/invoice events idempotently.

## Run The API

The Flutter app now auto-detects a local FastAPI backend by checking these common development URLs in order:

- Android emulator: `http://10.0.2.2:8010/`, `http://10.0.2.2:8000/`
- Other targets / adb reverse: `http://localhost:8010/`, `http://localhost:8000/`

You can also override this explicitly at launch time with `--dart-define=API_BASE_URL=...`.

Start the FastAPI app from the repository root in a separate terminal:

```bash
docker start khata-postgres

export BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing'

# Optional if this is the first time on a fresh database
PYTHONPATH=backend .venv/bin/python -m app.commands.bootstrap_user \
  --username owner \
  --password secret123 \
  --display-name Owner

BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' \
  PYTHONPATH=backend \
  .venv/bin/python -m uvicorn app.main:app --app-dir backend --reload --port 8010
```

Quick API smoke tests:

```bash
curl http://localhost:8010/health

curl -X POST http://localhost:8010/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"owner","password":"secret123"}'
```

If login fails, make sure you already created the bootstrap user with the command in the section above.

If you get `{"detail":"Not Found"}` from `/auth/login`, you are hitting the wrong server. Verify the process with `lsof -iTCP:8010 -sTCP:LISTEN -n -P` and restart the FastAPI app from this repo.

## Run In API Mode

API mode is the default Flutter data mode. It uses the FastAPI backend for auth,
products, customers, collections, company profile, invoices, and ledger data.

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter run -d <device-id>)
```

You can also make the mode explicit:

```bash
(cd mobile && flutter run -d <device-id> --dart-define=DATA_MODE=api)
```

Pin a specific backend URL when auto-detection is not enough:

```bash
(cd mobile && flutter run -d <device-id> \
  --dart-define=DATA_MODE=api \
  --dart-define=API_BASE_URL=http://10.0.2.2:8010/)
```

For a USB-connected Android device using `adb reverse`, use:

```bash
adb reverse tcp:8010 tcp:8010
(cd mobile && flutter run -d <device-id> \
  --dart-define=DATA_MODE=api \
  --dart-define=API_BASE_URL=http://localhost:8010/)
```

## Run In Local Mode

Local mode runs without the FastAPI backend or PostgreSQL. It stores business
data in the device-local Drift/SQLite database and uses the same screen/service
boundaries as API mode.

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter run -d <device-id> --dart-define=DATA_MODE=local)
```

On a fresh local database, the app shows `Set up local user` before login.
Create the first local account there, then log in with that username and
password. After login, local mode exposes the same core flows for products,
customers, collections, company profile, invoices, and ledger history without a
backend process.

The local schema is intentionally backend-aligned for future server migration:
local tables keep stable IDs, request IDs/request hashes, invoice numbers,
ledger transactions, stock movements, user references, and decimal values as
string payloads so exported data can be mapped to the Postgres/API model later.

## Run The Flutter App

Install Dart and Flutter dependencies from the Flutter project root, then launch the mobile app:

For a full Android emulator and physical Pixel testing guide, see `docs/android-testing-guide.md`.

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter run -d <device-id>)
```

If you want to pin a specific backend URL instead of relying on auto-detection:

```bash
(cd mobile && flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8010/)
```

For a USB-connected Android device using `adb reverse`, use:

```bash
adb reverse tcp:8010 tcp:8010
(cd mobile && flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8010/)
```

## Local Backup, Restore, And Drive Plumbing

Local mode adds a `Backup & Restore` drawer destination. The backup package is
an encrypted JSON envelope using AES-256-GCM and PBKDF2-HMAC-SHA256. The
decrypted payload contains `schema_version`, `backend_compatibility_version`,
`exported_at`, and table payloads for local users, products, customers, company
profiles, invoices, invoice items, stock movements, customer transactions, backup
settings, and backup events.

Backup/restore behavior:

- The backup core (`LocalBackupService`) can export and import encrypted backup
  packages for local table data.
- The current `Backup & Restore` UI is wired to the Drive backup interface. Until
  a configured Drive/file implementation is supplied, its export/import actions
  show a configuration-required message instead of writing or reading files.
- Restore validates backup schema version, backend compatibility version, and
  required tables before replacing local data in a transaction.

Automatic backup behavior:

- Local mode stores backup settings in `backup_settings`.
- Automatic backups are off by default and default to `00:00` when enabled.
- `BackupScheduler` can detect a missed scheduled backup on app launch and records
  failures to `backup_events`.
- In the current repository wiring, automatic backup attempts call the Drive
  backup skeleton and fail with a configuration-required event until a real
  Drive/file export implementation is provided.
- Platform background scheduling is represented by `BackupScheduleAdapter` and
  currently requires platform task configuration before it can run outside app
  launch.

Google Drive backup note: the repository currently provides the
`DriveBackupService` interface, local settings persistence, scheduler plumbing,
Backup/Restore UI, and a Google Drive service skeleton. Real Google Drive OAuth,
Drive file selection, and upload/download require external Google Cloud,
Firebase, app signing, consent screen, and runtime configuration that must not be
committed to this repository.

## Run Tests

Reset the database schema before a full backend verification run:

```bash
docker exec khata-postgres psql -U khata -d internal_billing -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

Backend tests are destructive. Prefer a separate PostgreSQL database for tests, such as `internal_billing_test`.

Run the full backend suite:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' \
  PYTHONPATH=backend \
  .venv/bin/python -m pytest backend/tests -q
```

Run the targeted end-to-end backend test:

```bash
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' \
  PYTHONPATH=backend \
  .venv/bin/python -m pytest backend/tests/api/test_end_to_end_flow.py -q
```

If you intentionally want to run destructive tests against a non-test database, add `BILLING_ALLOW_TEST_DATABASE_RESET=1`.

Run the mobile test suite:

```bash
(cd mobile && flutter test test)
```

For the full expanded mobile suite used by the offline-first local mode plan:

```bash
(cd mobile && flutter test test -r expanded)
```
