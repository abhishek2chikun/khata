# Internal Billing and Khata System

Flutter + FastAPI + PostgreSQL internal billing system with an optional
offline-first Flutter local mode backed by Drift/SQLite.

Implementation is tracked in:

- `docs/superpowers/specs/2026-04-19-internal-billing-khata-design.md`
- `docs/superpowers/plans/2026-04-19-internal-billing-khata-implementation.md`

## Wholesaler Workflow Terminology

The app models a wholesaler (distributor) business. Key entity names:

- **Buyer**: a supplier/vendor from whom the wholesaler purchases goods. Each product is associated with a buyer. Buyers have their own payable ledger (opening payables, purchase amounts, payments made, adjustments).
- **Customer**: a retail customer/shop that buys goods from the wholesaler. Customers have their own receivable ledger (opening balance, collections, balance adjustments, invoice debits).
- **Product**: an inventory item with `item_number`, `item_name`, `category`, `buyer_id`, `company_name`, `buying_price` (purchase cost from buyer), and `selling_price` (sale price to customer). Prices are GST-inclusive.
- **Invoice**: a sale document to a customer with line items, tax computation, payment state (`CREDIT`, `PARTIAL_PAID`, `TOTAL_PAID`), and stock/ledger side effects.
- **Analytics**: owner dashboard with KPI totals (revenue, profit, receivables, payables, active invoice count, average invoice value), zero-filled daily trend, ranked products/customers, and date presets. Low-stock remains in API/local payloads for compatibility but is excluded from the analytics UI.

### Product, HSN, and invoice precision (Stage 3 upgrade)

- Products carry nullable, non-unique `hsn_code`; invoice lines snapshot `product_hsn_code`.
- GST invoice creation rejects products missing HSN; non-GST invoices allow missing HSN.
- New invoice and stock-adjustment quantities must be whole numbers; historical fractional values remain readable.
- Unit prices use three-decimal precision (`12.008`); monetary totals remain two-decimal currency values.
- New invoice writes require zero discount; historical discounted invoices remain readable in PDFs.

### GST invoicing (Stage 3 baseline + upgrade)

- Seller profile and each invoice snapshot persist `gst_flag` (GST vs non-GST).
- Non-GST invoices force zero tax; GST sellers may issue non-GST only when all line GST rates are zero.
- Mobile invoice creation sends date-only `invoice_date`; PDFs adapt A5 (≤10 lines) / A4 (>10) with GST or non-GST layouts.
- Invoice PDF sharing uses the OS chooser with attachment plus a safe caption; customer pending balances can be shared individually or as a daily positive-only summary.

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

### Preinstalled product catalog (local mode)

Fresh local installs ship with **1,199 products** and **30 buyers** bundled in
the APK. On first launch, `LocalProductCatalogSeeder` loads
`mobile/assets/catalog/preinstalled_catalog.json` and inserts any missing buyers
and products into the local Drift database. Seeded rows behave like manually
added inventory: they support edit, archive, stock adjustment, and invoice use.

Source spreadsheet: `data/source/products.xlsx`. Rebuild the bundled JSON after
updating the spreadsheet:

```bash
python3 tools/build_preinstalled_catalog.py
```

Column mapping: Company → buyer + `company_name`; Category → `category`; Item
Name → `item_name`; HSN → nullable `hsn_code` (125 source rows intentionally
blank); Buying Price (MRP) → GST-inclusive `buying_price`; Selling Price (DP) →
GST-inclusive `selling_price`; Unit `1.0` → `pcs`; GST Rate →
`gst_rate`; Quantity on Hand → `quantity_on_hand`; generated
`item_number` per company (e.g. `DOMS-0001`); default `low_stock_threshold`
`0`. Re-seeding is idempotent and never overwrites existing rows.

The local schema is intentionally backend-aligned for future server migration:
local tables keep stable IDs, request IDs/request hashes, invoice numbers,
ledger transactions, stock movements, user references, and decimal values as
string payloads so exported data can be mapped to the Postgres/API model later.

### Local/Server Schema Alignment

Both local (Drift/SQLite) and server (PostgreSQL) schemas share the same table
and column naming. Local mode stores all monetary values as canonical decimal
strings (e.g. `"123.45"`) to preserve precision; the server uses `Numeric`
columns. Key alignment expectations:

- Local `products` V2 columns (`buyer_id`, `company_name`, `buying_price`,
  `selling_price`) match server `products` columns exactly.
- Local `invoice_items` snapshot columns (`product_item_number`,
  `product_buyer_id`, `product_company_name`, `buying_price`, `selling_price`)
  match server columns. The server additionally computes `revenue_amount`,
  `buying_amount`, and `profit_amount` during migration.
- Local `invoices.payment_state` (`CREDIT`, `PARTIAL_PAID`, `TOTAL_PAID`) and
  `invoices.paid_amount` match server semantics.
- Local `buyer_transactions` and `customer_transactions` have full column
  alignment with server counterparts.
- Local text IDs map to server UUIDs during migration; `salt` and
  `password_hash_version` are local-only.

Backup schema version: **10**. Backend compatibility version: **`local-v2`**.
Includes `hsn_code` on products, `product_hsn_code` on invoice items,
three-decimal unit prices, and `gst_flag` on company profiles and invoices
(Drift v10 / Alembic 0010). Version 9 backups import with null HSN fields.

### Backup and Migration Compatibility

Backups are encrypted (AES-256-GCM, PBKDF2-HMAC-SHA256) JSON envelopes
containing `schema_version`, `backend_compatibility_version`, `exported_at`,
and per-table payloads. Import validates both version fields and required
tables before replacing local data in a transaction. A backup from one device
can restore on another device running the same schema version. Future schema
changes must bump `schema_version` and/or `backend_compatibility_version` to
prevent cross-version restore corruption.

### Drive backup and scheduling

Local mode supports encrypted Google Drive backup via `google_sign_in` (Drive file
scope), upload to visible folder `Khata Backups`, secure password storage
(`flutter_secure_storage`), WorkManager periodic scheduling (default **02:00**
local time) with startup catch-up, verified upload (SHA-256), and 30-backup
retention. Manual export/import remains available.

**External setup required:** Google Cloud Drive API, Android OAuth client
(package + signing SHA fingerprints), consent screen/test users. No secrets in
repo. Physical-device OAuth/background evidence required before production
claims.

### Drive/Background limitations (legacy note)

## Build Release APK

Build a local-mode release APK:

```bash
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```

The APK is output at `mobile/build/app/outputs/flutter-apk/app-release.apk`.

### APK Build Blocker: Java Runtime

The `flutter build apk` command requires a JDK (Gradle needs `java`). If the
build fails with `Unable to locate a Java Runtime`, install JDK 17+:

```bash
brew install openjdk@17
```

Then set `JAVA_HOME` before building:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```

Alternatively, install Android Studio which bundles a JDK.

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
`exported_at`, and table payloads for local users, products, customers, buyers,
company profiles, invoices, invoice items, stock movements, customer
transactions, buyer transactions, backup settings, and backup events.

### Local-to-server table mapping

Every local Drift/SQLite table maps to a backend PostgreSQL table or is
intentionally local-only:

| Local Drift table | Server Postgres table | Notes |
|---|---|---|
| `local_users` | `app_users` | Local IDs are text strings; server uses UUID. Salt and password_hash_version columns are local-only. |
| `products` | `products` | Aligned since product V2 schema (buyer_id, company_name, buying_price, selling_price). |
| `customers` | `customers` | Full column alignment. |
| `buyers` | `buyers` | Full column alignment. |
| `company_profiles` | `company_profiles` | Full column alignment. |
| `invoices` | `invoices` | Aligned including payment_state, paid_amount, invoice_datetime. Local payment_mode maps to server payment_state. |
| `invoice_items` | `invoice_items` | Aligned with V2 snapshot fields (product_item_number, product_buyer_id, product_company_name, buying_price, selling_price). Server also has computed analytics columns (revenue_amount, buying_amount, profit_amount). |
| `stock_movements` | `stock_movements` | Full column alignment. |
| `customer_transactions` | `customer_transactions` | Full column alignment. |
| `buyer_transactions` | `buyer_transactions` | Full column alignment. |
| `local_sessions` | `user_sessions` | **Local-only.** Not exported in backup. Cleared on import. Server manages sessions independently. |
| `backup_settings` | — | **Local-only.** No server equivalent. |
| `backup_events` | — | **Local-only.** No server equivalent. |

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
