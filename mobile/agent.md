# Mobile — agent.md

Role: Flutter client for login, inventory, customer khata ledger, buyer payable ledger, collections, invoice creation, analytics dashboard, and offline-first local mode.

## Wholesaler Terminology

- **Buyer**: a supplier/vendor. Products are associated with buyers via `buyer_id` and `company_name`. Buyers have a payable ledger (opening payables, purchase amounts, payments made, adjustments).
- **Customer**: a retail customer/shop. Customers have a receivable ledger (opening balance, collections, balance adjustments, invoice debits).
- **Product**: inventory item with V2 fields: `buyer_id`, `company_name`, `buying_price`, `selling_price` (GST-inclusive).
- **Invoice**: sale document with multi-line items, payment state (`CREDIT`, `PARTIAL_PAID`, `TOTAL_PAID`), stock/ledger side effects.
- **Analytics**: owner dashboard with KPI totals (revenue, profit, receivables, payables, active invoice count, average invoice value), zero-filled daily trend, ranked products/customers, date presets (Today/7d/30d/Month/Custom). Low-stock remains in API/local payloads for compatibility but is excluded from UI and `hasData`.

## How to use this system

- Default `DATA_MODE=api` uses the FastAPI backend. Start the backend first for API mode.
- `DATA_MODE=local` runs without FastAPI/PostgreSQL by using Drift/SQLite local services.
- Prefer running API mode against `8010` right now. Android emulator support is built around `10.0.2.2` and optional `adb reverse`.
- Keep API request/response field names aligned with backend JSON exactly.
- Keep local Drift tables backend-aligned so future server migration can map local IDs, request IDs, invoice numbers, ledger rows, stock movements, and decimal string fields to the backend/Postgres model.
- Secure storage is for auth session data. Invoice draft state is transient in memory.

### Build Release APK (local mode)

```bash
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```

Requires JDK 17+. If the build fails with `Unable to locate a Java Runtime`, install `openjdk@17` via Homebrew or Android Studio and set `JAVA_HOME`.

### Run In API Mode

```bash
(cd mobile && flutter pub get)
(cd mobile && flutter run -d <device-id> --dart-define=DATA_MODE=api)
```

## Project overview

The app currently supports:

- username/password login
- secure session restore via refresh token
- local first-user setup when `DATA_MODE=local` has no users
- inventory list with add/edit product flow (V2: buyer_id, company_name, buying_price, selling_price)
- customer list and customer khata detail
- buyer list and buyer payable ledger detail
- collection recording, opening balance, and balance adjustment
- invoice create → preview → confirm flow (multi-line, payment state, GST/non-GST mode, date-only invoice date, pre-confirm PDF preview via View PDF)
- invoice list and invoice detail screens with adaptive GST/non-GST PDFs (A5 ≤10 lines, A4 >10) and PDF+caption sharing
- customer balance sharing (individual and daily positive-balance summary)
- analytics dashboard (revenue/profit by buyer/company/customer, top products, low stock, khata balances)
- local Backup/Restore UI and automatic backup scheduler plumbing

Important live behavior:

- API base URL is auto-discovered at startup from common local development targets, or can be forced with `--dart-define=API_BASE_URL=...`.
- App data mode is selected with `--dart-define=DATA_MODE=api` or `--dart-define=DATA_MODE=local`; empty/default is API mode.
- Auth uses `HttpAuthService`, `SecureSessionStore`, and `AuthController`.
- All non-auth API calls go through `ApiClient`, which retries once after token refresh on `401`.
- Customer detail doubles as the current invoice-history surface.
- Local mode composes `LocalAuthService`, Drift-backed local services, `EncryptedDriveBackupService`, and `BackupScheduler` through `AppDependencies`.

## Directory structure

```text
mobile/
  agent.md
  pubspec.yaml
  analysis_options.yaml
  lib/
    main.dart
    auth/
    config/
    models/
    screens/
    services/
    state/
    widgets/
    local/
    backup/
    app/
  test/
    app/
    auth/
    backup/
    config/
    local/
    services/
    state/
    widgets/
    app_shell_test.dart
```

## Module status

| Module | Status | Location | `agent.md` |
|---|---|---|---|
| App composition | Done | `mobile/lib/main.dart` | None yet |
| Auth/session | Done | `mobile/lib/auth/` | None yet |
| API base URL resolution | Done | `mobile/lib/config/api_base_url.dart` | None yet |
| Shared API client | Done | `mobile/lib/services/api_client.dart` | None yet |
| Products flow | Done | `mobile/lib/services/products_service.dart`, `mobile/lib/screens/inventory_list_screen.dart`, `mobile/lib/screens/product_form_screen.dart` | None yet |
| Customers/Khata flow | Done | `mobile/lib/services/customers_service.dart`, `mobile/lib/screens/customer_list_screen.dart`, `mobile/lib/screens/customer_detail_screen.dart` | None yet |
| Buyers/Payable flow | Done | `mobile/lib/services/buyers_service.dart`, `mobile/lib/screens/buyer_list_screen.dart`, `mobile/lib/screens/buyer_detail_screen.dart` | None yet |
| Collections/khata flow | Done | `mobile/lib/services/payments_service.dart`, `mobile/lib/screens/record_payment_screen.dart`, `mobile/lib/screens/opening_balance_screen.dart`, `mobile/lib/screens/balance_adjustment_screen.dart` | None yet |
| Invoice flow | Done | `mobile/lib/services/invoices_service.dart`, `mobile/lib/state/invoice_draft_controller.dart`, `mobile/lib/screens/create_invoice_screen.dart`, `mobile/lib/screens/invoice_preview_screen.dart`, `mobile/lib/screens/invoice_list_screen.dart`, `mobile/lib/screens/invoice_detail_screen.dart` | None yet |
| Analytics dashboard | Done | `mobile/lib/services/analytics_service.dart`, `mobile/lib/screens/analytics_screen.dart`, `mobile/lib/local/local_analytics_service.dart` | None yet |
| Company profile client | Done | `mobile/lib/services/company_profile_service.dart` | None yet |
| Local data mode | Done | `mobile/lib/app/app_mode.dart`, `mobile/lib/app/app_dependencies.dart`, `mobile/lib/local/` | None yet |
| Backup/restore | Done — Drive orchestration; device OAuth external | `mobile/lib/backup/`, `mobile/lib/widgets/app_navigation_drawer.dart` | None yet |
| Widget/test coverage | Done — focused flows covered | `mobile/test/` | None yet |

## Conventions

- Use `ApiClient` for authenticated JSON requests instead of ad-hoc `HttpClient` calls in feature code.
- Keep request/response field names aligned with backend JSON exactly.
- Preserve current state ownership:
  - auth session: `SecureSessionStore`
  - auth flow state: `AuthController`
  - invoice draft state: `InvoiceDraftController`
- The app currently uses `ChangeNotifier` + `AnimatedBuilder`, not a heavier state-management library.
- API URL selection comes from `API_BASE_URL` first, then local dev auto-detection.
- Local backup payloads must keep `schema_version` and `backend_compatibility_version` checks before import.
- Do not commit real Google Drive OAuth credentials, Firebase config, signing secrets, or Drive API tokens.

## Local mode setup

Run without a backend:

```bash
(cd mobile && \
  flutter run -d emulator-5554 --dart-define=DATA_MODE=local)
```

On a fresh local database, the app shows `Set up local user`. Create the first
local username/password there, then log in. Local mode uses the same main flows
as API mode but persists data through Drift/SQLite on the device.

**Preinstalled catalog:** release/local builds bundle ~1,199 products and 29
buyers from `data/source/products.xlsx` (compiled to
`assets/catalog/preinstalled_catalog.json`). `AppDependencies` seeds missing
catalog rows on startup via `LocalProductCatalogSeeder`; seeded inventory is
fully editable. Rebuild with `python3 tools/build_preinstalled_catalog.py`.

The local database schema mirrors backend concepts for future migration:
products, customers, company profiles, invoices, invoice items, stock movements,
customer transactions, users, sessions, backup settings, and backup events. IDs,
request IDs, invoice numbers, ledger entries, and decimal string values should
stay compatible with backend DTOs and Postgres migration scripts.

## Backup and Drive configuration

Local mode exposes `Backup & Restore` in the drawer. The core backup service
(`LocalBackupService`) can export/import encrypted packages containing local
table payloads. The current backup schema version is **10** with backend
compatibility version `local-v2`.

Backup payload includes these tables: local_users, products, customers, buyers,
company_profiles, invoices, invoice_items, stock_movements,
customer_transactions, buyer_transactions, backup_settings, backup_events.
Sessions (local_sessions) are intentionally excluded from backup and cleared on
import.

**Google Drive (encrypted)**
- Connect Google account (`google_sign_in` + Drive file scope only).
- Backup password stored in `flutter_secure_storage` (separate from auth tokens).
- Uploads verified `.khata` packages to visible folder `Khata Backups` with app ownership properties; retains newest 30 app-owned backups.
- Automatic daily backup defaults to **02:00** local time with WorkManager periodic work (best effort) and startup catch-up.
- Foreground UI: connect, password, automatic toggle, Back up now, Drive restore list; manual export/import preserved.
- Background task requires prior foreground sign-in and password; otherwise records action-required without UI prompts.

**External setup required (not in repo)**
- Google Cloud: enable Drive API, Android OAuth client (package + SHA fingerprints), consent screen/test users.
- Physical-device OAuth/sign-in/background evidence still required before production claims.

Automatic backup settings persist in Drift `backup_settings`. `BackupScheduler`
handles due/missed-backup decisions and catch-up on app launch. Platform
scheduling uses `WorkManagerBackupScheduleAdapter` on Android.

### Local-to-server table mapping

| Local Drift table | Server Postgres table | Migration status |
|---|---|---|
| `local_users` | `app_users` | Migratable (text ID → UUID, salt/hash_version local-only) |
| `products` | `products` | Aligned (V2: buyer_id, company_name, buying_price, selling_price) |
| `customers` | `customers` | Aligned |
| `buyers` | `buyers` | Aligned |
| `company_profiles` | `company_profiles` | Aligned |
| `invoices` | `invoices` | Aligned (payment_state, paid_amount, invoice_datetime) |
| `invoice_items` | `invoice_items` | Aligned (V2 snapshot fields; server has extra analytics columns) |
| `stock_movements` | `stock_movements` | Aligned |
| `customer_transactions` | `customer_transactions` | Aligned |
| `buyer_transactions` | `buyer_transactions` | Aligned |
| `local_sessions` | `user_sessions` | Local-only, excluded from backup and migration |
| `backup_settings` | — | Local-only, no server equivalent |
| `backup_events` | — | Local-only, no server equivalent |

Automatic backup settings are stored locally. `BackupScheduler` handles daily
due/missed-backup decisions and catch-up checks on app launch. In current repo
wiring, automatic backup uses encrypted Google Drive upload when account and
password are configured. Platform background execution is via
`WorkManagerBackupScheduleAdapter` on Android.

Google Drive integration includes production orchestration code with injectable
gateways for tests. Real OAuth client configuration, signing fingerprints,
consent screen, and production secrets must be configured outside this repository.

## Verification commands

```bash
# Install dependencies
(cd mobile && flutter pub get)

# Run on Android emulator against the current backend port
(cd mobile && \
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8010/)

# Run local mode without API/backend
(cd mobile && \
  flutter run -d emulator-5554 --dart-define=DATA_MODE=local)

# Run using adb reverse instead
adb reverse tcp:8010 tcp:8010
(cd mobile && \
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://localhost:8010/)

# Run mobile tests (full suite — 458 tests)
(cd mobile && flutter test test)

# Backend pure tests (no Postgres)
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q

# Run full expanded mobile tests
(cd mobile && flutter test test -r expanded)
```

## Progress

- **2026-06-18:** Invoice preview improvements — pre-confirm **View PDF** on quote screen (actual generated PDF via `printing`); non-GST PDFs drop Code column; place of supply auto-resolves customer → company state (optional override on create form, hidden for non-GST).
- **2026-06-15:** Preinstalled catalog v3 — rebuilt from corrected `Invoices (3).xlsx` source (`data/source/products.xlsx`); 1,199 products / 29 buyers; buying prices and HSN fixes; case-insensitive company merge (`Linc` → `linc`); existing local installs upgrade prices/HSN on startup.
- **2026-06-14 (Task 07):** Integration handoff — signed stock-delta fix, 5 cross-slice regression tests, stale fixture refresh; **458** mobile + **55** pure tests green; release APK SHA-256 recorded; Postgres/device gates documented.
- **2026-06-14:** Encrypted Google Drive backup — verified upload orchestration, 30-retention prune, secure password store, WorkManager + catch-up, full backup screen; 69 backup tests green; physical OAuth unverified (AC10/AC11).
- **2026-06-14:** Owner analytics dashboard — backend/local KPI + `daily_trend` fields, `fl_chart` revenue/profit trend, date presets, low-stock removed from UI; parity fixture + 18 focused analytics tests green.
- **2026-06-14:** Drift/backup schema **10**, HSN/precision contracts, searchable invoice picker, Cash/Credit UX, batch collections, compliant PDFs.
- **2026-06-13:** Preinstalled local product catalog — 1,199 products + 30 buyers bundled as JSON asset (catalog v2 with HSN), seeded idempotently on local-mode startup; build script at `tools/build_preinstalled_catalog.py`.
- **2026-06-13:** Stage 3 GST invoicing baseline — seller `gst_flag`, GST/non-GST tax semantics, date-only mobile invoices, adaptive PDFs, PDF+caption share, customer balance sharing.
- **2026-06-12:** `ApiBuyersService.addPaymentMade` now posts to `/payments-made` (was `/collections-made`, 404 against live backend).
- Login is working against the current local backend setup.
- Inventory and customer flows now have realistic dev data available through the backend demo seed command.
- The app can create and confirm invoices, and customer khata detail refreshes can reflect resulting ledger changes.
- Local backend discovery now handles `8010` and emulator-friendly hosts.
- Offline-first local mode is available through `DATA_MODE=local` with first-user setup, Drift-backed services, encrypted backup import/export foundations, and automatic Drive backup scheduler plumbing.
- Wholesaler workflow complete: buyer CRUD and payable ledger, invoice list/detail screens, multi-line invoice creation, product V2 fields, analytics dashboard (both API and local modes).
- 458 mobile tests passing (includes 5 cross-slice integration regressions).

## Deferred work

- There is no dedicated invoice cancel UI outside invoice detail.
- There is no UI for product archive, customer archive, or manual stock adjustment even though backend APIs exist.
- Real Google Drive backup on physical hardware requires external Google Cloud OAuth configuration and device/account evidence (AC10/AC11).
- `mobile/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, but `flutter_lints` is not listed in `pubspec.yaml`, so analyzer/format tooling may warn until that is reconciled.
