# Mobile — agent.md

Role: Flutter client for login, inventory, seller ledger, payments, invoice creation, and offline-first local mode.

## How to use this system

- Default `DATA_MODE=api` uses the FastAPI backend. Start the backend first for API mode.
- `DATA_MODE=local` runs without FastAPI/PostgreSQL by using Drift/SQLite local services.
- Prefer running API mode against `8010` right now. Android emulator support is built around `10.0.2.2` and optional `adb reverse`.
- Keep API request/response field names aligned with backend JSON exactly.
- Keep local Drift tables backend-aligned so future server migration can map local IDs, request IDs, invoice numbers, ledger rows, stock movements, and decimal string fields to the backend/Postgres model.
- Secure storage is for auth session data. Invoice draft state is transient in memory.

## Project overview

The app currently supports:

- username/password login
- secure session restore via refresh token
- local first-user setup when `DATA_MODE=local` has no users
- inventory list with add/edit product flow
- seller list and seller detail
- payment recording, opening balance, and balance adjustment
- invoice create → preview → confirm flow
- local Backup/Restore UI and automatic backup scheduler plumbing

Important live behavior:

- API base URL is auto-discovered at startup from common local development targets, or can be forced with `--dart-define=API_BASE_URL=...`.
- App data mode is selected with `--dart-define=DATA_MODE=api` or `--dart-define=DATA_MODE=local`; empty/default is API mode.
- Auth uses `HttpAuthService`, `SecureSessionStore`, and `AuthController`.
- All non-auth API calls go through `ApiClient`, which retries once after token refresh on `401`.
- Seller detail doubles as the current invoice-history surface.
- Local mode composes `LocalAuthService`, Drift-backed local services, `LocalDriveBackupService`, and `BackupScheduler` through `AppDependencies`.

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
  test/
    auth/
    config/
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
| Sellers + ledger flow | Done | `mobile/lib/services/sellers_service.dart`, `mobile/lib/screens/seller_list_screen.dart`, `mobile/lib/screens/seller_detail_screen.dart` | None yet |
| Payments flow | Done | `mobile/lib/services/payments_service.dart`, `mobile/lib/screens/record_payment_screen.dart`, `mobile/lib/screens/opening_balance_screen.dart`, `mobile/lib/screens/balance_adjustment_screen.dart` | None yet |
| Invoice flow | Done — needs UX expansion | `mobile/lib/services/invoices_service.dart`, `mobile/lib/state/invoice_draft_controller.dart`, `mobile/lib/screens/create_invoice_screen.dart`, `mobile/lib/screens/invoice_preview_screen.dart` | None yet |
| Company profile client | In Progress | `mobile/lib/services/company_profile_service.dart` | None yet |
| Local data mode | Done | `mobile/lib/app/app_mode.dart`, `mobile/lib/app/app_dependencies.dart`, `mobile/lib/local/` | None yet |
| Backup/restore | Done — Drive production config external | `mobile/lib/backup/`, `mobile/lib/widgets/app_navigation_drawer.dart` | None yet |
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
(cd /Users/abhishek/python_venv/khata_app/mobile && \
  flutter run -d emulator-5554 --dart-define=DATA_MODE=local)
```

On a fresh local database, the app shows `Set up local user`. Create the first
local username/password there, then log in. Local mode uses the same main flows
as API mode but persists data through Drift/SQLite on the device.

The local database schema mirrors backend concepts for future migration:
products, sellers, company profiles, invoices, invoice items, stock movements,
seller transactions, users, sessions, backup settings, and backup events. IDs,
request IDs, invoice numbers, ledger entries, and decimal string values should
stay compatible with backend DTOs and Postgres migration scripts.

## Backup and Drive configuration

Local mode exposes `Backup & Restore` in the drawer. The core backup service
(`LocalBackupService`) can export/import encrypted packages containing local
table payloads. The current UI is wired to the Drive backup interface; until a
configured Drive/file implementation is supplied, export/import actions show a
configuration-required message. Import rejects unsupported schema or backend
compatibility versions and missing required tables.

Automatic backup settings are stored locally. `BackupScheduler` handles daily
due/missed-backup decisions and catch-up checks on app launch. In current repo
wiring, automatic backup attempts call the Drive backup skeleton and record a
configuration-required failure until a real Drive/file export implementation is
provided. Platform background execution is behind `BackupScheduleAdapter`; real
background tasks require Android/iOS scheduling setup outside the current
skeleton.

Google Drive integration is currently plumbing only: `DriveBackupService`, local
settings persistence, scheduler wiring, UI actions, and a Google Drive service
skeleton. Real Google Drive OAuth, file picker/selection, upload/download,
Firebase or Google Cloud app configuration, signing fingerprints, consent screen,
and production secrets must be configured outside this repository.

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

# Run mobile tests
(cd mobile && flutter test test)

# Run full expanded mobile tests
(cd mobile && flutter test test -r expanded)
```

## Progress

- Login is working against the current local backend setup.
- Inventory and seller flows now have realistic dev data available through the backend demo seed command.
- The app can create and confirm invoices, and seller detail refreshes can reflect resulting ledger changes.
- Local backend discovery now handles `8010` and emulator-friendly hosts.
- Offline-first local mode is available through `DATA_MODE=local` with first-user setup, Drift-backed services, encrypted backup import/export foundations, and automatic Drive backup scheduler plumbing.

## Deferred work

- There is no dedicated invoice list/detail/cancel UI outside seller detail history and the create flow.
- There is no UI for product archive, seller archive, or manual stock adjustment even though backend APIs exist.
- The invoice screen currently exposes a single line-item form; multi-line invoice authoring is not surfaced yet.
- Real Google Drive backup upload/download requires external Google Cloud/Firebase/app configuration; the repository currently provides interfaces, scheduler plumbing, and UI skeleton behavior.
- `mobile/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, but `flutter_lints` is not listed in `pubspec.yaml`, so analyzer/format tooling may warn until that is reconciled.
