# Offline-First Local Data Design

## Goal

Build a second mobile data mode that keeps the current API-backed app intact while adding a fully offline local-data version. In local mode, all business data is stored on the device with Drift/SQLite, no backend API calls are required, and users can export/import encrypted backup files for Google Drive or device-to-device transfer.

## Current Version Preservation

The current FastAPI/PostgreSQL backend and API-backed Flutter app remain available.

The Flutter app will support a build/runtime data mode switch:

```bash
flutter run -d emulator-5554 --dart-define=DATA_MODE=api
flutter run -d emulator-5554 --dart-define=DATA_MODE=local
```

`DATA_MODE=api` keeps the current service wiring:

- `HttpAuthService`
- `ApiProductsService`
- `ApiSellersService`
- `ApiPaymentsService`
- `ApiInvoicesService`
- `ApiCompanyProfileService`

`DATA_MODE=local` wires local Drift-backed implementations instead:

- `LocalAuthService`
- `LocalProductsService`
- `LocalSellersService`
- `LocalPaymentsService`
- `LocalInvoicesService`
- `LocalCompanyProfileService`
- `LocalBackupService`

## Local Database

Use Drift as the local persistence layer. Drift gives typed queries, migrations, transaction support, testability, and SQLite portability.

The local schema mirrors the current backend business domain rather than the HTTP transport layer.

Tables:

- `local_users`: username login, password hash, display name, active flag, timestamps
- `products`: inventory catalog, pricing, stock quantity, archive flag, timestamps
- `stock_movements`: opening stock, manual adjustments, invoice stock effects, idempotency metadata
- `sellers`: seller profile, address, tax fields, archive flag, timestamps
- `seller_transactions`: opening balance, payment, adjustment, invoice debit, cancellation reversal
- `company_profiles`: active company identity, tax, contact, bank, and invoice footer details
- `invoices`: invoice header, seller snapshot, company snapshot, totals, status, cancellation fields
- `invoice_items`: invoice line items, product snapshot, quantity, discount, tax, totals
- `local_sessions`: current local auth session data
- `backup_events`: export/import history, file name, status, timestamps, errors

IDs should remain UUID strings so existing models and tests can migrate with minimal friction.

## Local Login

The app keeps the username/password login UX in local mode.

Local mode does not call `/auth/login`, `/auth/me`, `/auth/refresh`, or `/auth/logout`.

Behavior:

- First local launch shows a local setup flow to create the first user.
- Username/password are checked against `local_users`.
- Passwords are stored as strong local hashes, not plain text.
- A successful login writes a local session record.
- Logout clears the local session.
- Session restore reads the local session and user record from Drift.

The existing `AuthController` can stay as the UI-facing controller. It should depend on the `AuthService` interface and receive either `HttpAuthService` or `LocalAuthService` from app composition.

## Business Rules

Local mode must own the same business rules currently owned by the backend services.

Rules to port into Dart local services:

- Product creation enforces duplicate product constraints.
- Product edit does not directly edit stock quantity.
- Stock movements update product quantity transactionally.
- Seller transactions produce a deterministic ledger.
- Payments reduce seller pending balance.
- Opening balance and balance adjustments create ledger rows.
- Invoice quote calculates subtotal, discount, taxable total, GST total, and grand total.
- Invoice creation snapshots product, seller, and company data.
- Invoice creation reduces stock and creates seller ledger effects in one Drift transaction.
- Invoice cancellation reverses stock and ledger effects in one Drift transaction.
- Idempotent writes use `request_id` and request hashing where the current backend does so.

Local mode should not duplicate backend HTTP schemas unnecessarily. Existing mobile models can be reused where they already match UI needs.

## Backup, Export, And Import

Cloud backup is backup-only, not multi-device live sync.

The phone is the source of truth. The cloud copy is used for restore or device transfer.

The implementation must support both file export/import and automatic Google Drive backup.

Export behavior:

- User opens Backup/Restore screen.
- User taps `Export backup`.
- App creates an encrypted backup file containing the local database data and metadata.
- App opens Android share/save sheet.
- User chooses Google Drive, Files, WhatsApp, email, or any other available target.
- App records a `backup_events` row with success/failure and timestamp.

Automatic Google Drive backup behavior:

- User connects a Google account for Drive backup.
- User configures a daily backup time, defaulting to midnight local device time.
- App schedules a background backup around the configured time.
- The backup task creates an encrypted backup file and uploads it to Google Drive automatically.
- If the OS does not run the background task exactly at the configured time, the app performs the missed backup at the next available background execution or next app launch.
- The app keeps only a configurable number of recent Drive backup files, defaulting to the latest 7 backups.
- The app records backup success/failure and the Drive file identifier in `backup_events`.
- The app shows last successful backup time and last failure details in Backup/Restore settings.

Import behavior:

- User opens Backup/Restore screen.
- User taps `Import backup`.
- App opens the file picker.
- User selects a backup file.
- App validates version, checksum, and encryption password.
- App shows a destructive restore confirmation.
- On confirmation, app replaces local data inside a transaction.
- App records an import event and restarts the local session flow if needed.

Backup file requirements:

- Include schema version.
- Include app version.
- Include exported-at timestamp.
- Include database payload.
- Include checksum or authenticated encryption validation.
- Be encrypted with a user-provided backup password.

Automatic Drive upload requires Google Sign-In and Drive API setup. Mobile operating systems do not guarantee exact midnight execution, so configured-time backup is best-effort with catch-up on next app launch.

Manual file export remains available even when Drive backup is not configured.

## Server Migration Compatibility

The local Drift schema must stay aligned with the backend/PostgreSQL domain schema so future migration back to a deployed server API is safe.

Compatibility requirements:

- Local table names should match backend domain concepts and preserve backend field names where practical.
- Local primary keys use UUID strings compatible with backend UUID columns.
- Local timestamps should be stored in UTC-compatible ISO-8601 strings or integer milliseconds with explicit conversion rules.
- Local numeric money, GST, and quantity fields must avoid floating-point corruption in persisted storage. Store decimal values as integer minor units or normalized decimal strings, then expose doubles only at UI boundaries if needed.
- Local invoice numbers must be generated deterministically on device and remain importable into server Postgres without collision for single-device backup/restore flows.
- Local idempotency fields such as `request_id`, `request_hash`, and cancel request metadata must be preserved.
- Local backup files must include `schema_version`, `backend_compatibility_version`, and export metadata.
- Future server import should be able to replay or bulk-load local rows into Postgres without losing stock, ledger, invoice, cancellation, or audit history.

The server migration path is not implemented in the first offline-first build, but the local schema must not paint us into a corner.

## UI Changes

Add local-mode UI only where necessary.

New screens:

- Local first-user setup screen
- Backup/Restore screen

Existing screens should be reused:

- Login screen
- Inventory list and product form
- Seller list and detail
- Payment and balance screens
- Invoice list, create, preview, detail, and cancel flow
- Company profile screen

Navigation:

- Add `Backup / Restore` to the app drawer in local mode.
- Keep API-mode navigation unchanged unless the backup screen is explicitly enabled later.

## App Composition

`mobile/lib/main.dart` should create dependencies based on `DATA_MODE`.

Suggested structure:

- `mobile/lib/app/app_mode.dart`: parses `DATA_MODE`
- `mobile/lib/app/app_dependencies.dart`: dependency container for services
- `mobile/lib/local/local_database.dart`: Drift database
- `mobile/lib/local/local_auth_service.dart`
- `mobile/lib/local/local_products_service.dart`
- `mobile/lib/local/local_sellers_service.dart`
- `mobile/lib/local/local_payments_service.dart`
- `mobile/lib/local/local_invoices_service.dart`
- `mobile/lib/local/local_company_profile_service.dart`
- `mobile/lib/backup/backup_service.dart`
- `mobile/lib/backup/backup_screen.dart`

The screens should keep depending on service interfaces instead of knowing whether data came from HTTP or Drift.

## Error Handling

Local mode should avoid API/network wording.

Examples:

- API mode can still show `Unable to reach the server`.
- Local mode should show `Unable to load local data` for database read failures.
- Backup export errors should show `Backup export failed` with a short detail.
- Import validation errors should show `This backup file cannot be imported`.
- Wrong backup password should show `Backup password is incorrect`.

## Testing Strategy

Add tests before implementation for each local service behavior.

Test groups:

- App mode selects API vs local dependencies.
- Local first-user setup creates a user and allows login.
- Local login rejects wrong password.
- Local products service creates, filters, updates, and rejects duplicates.
- Local sellers service creates sellers and produces ledger data.
- Local payments service writes seller transactions and updates balances.
- Local invoices service quotes, creates, lists, details, and cancels invoices.
- Local invoice creation updates stock and seller ledger transactionally.
- Backup export writes a valid encrypted backup package.
- Backup import restores data into an empty local database.
- Backup import rejects invalid version, corrupt payload, and wrong password.

Existing widget tests should run in API-mode and local-mode variants where feasible.

## Migration From API Mode

No automatic backend-to-local migration is part of the first offline-first version.

If needed later, add an explicit import tool that logs into the backend once, downloads data, and writes it into Drift. That is separate from backup import/export.

## Deferred Work

- Direct Google Drive API integration.
- True multi-device sync.
- Conflict resolution.
- Backend-to-local migration wizard.
- Local-to-server migration importer.
- Encrypted SQLite-at-rest beyond encrypted export files.

## Approval Status

Approved direction:

- Keep current API version.
- Add app flavor/data-mode toggle.
- Use Drift for local offline data.
- Keep username/password login locally.
- Backup-only cloud strategy.
- Use export/import files for Google Drive/device transfer.
- Automatic Google Drive backup at a configured daily time.
- Drift schema alignment with backend/PostgreSQL for future server migration.
