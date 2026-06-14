# Implementation Log

## Workflow Summary

Baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
Current HEAD: `97b100e6a520a87aa33bb786b5cb9a6ed369351a`
Integration target branch: `main`
Feature branch: `codex/khata-invoice-collections-backup-analytics`
Worktree name/ID: `khata_app-upgrade`
Canonical worktree path: `/Users/abhishek/python_venv/khata_app-upgrade`
Merge status: not-started
Assigned tasks: 01-07 (full plan)

## Task Evidence

| Slice | Status | Implementation evidence | Verification evidence | Deviations/blockers |
|---|---|---|---|---|
| Platform feasibility | complete | Task 01 merged at `d12306c` | prior ladder green | none |
| Contracts/migrations/catalog | complete | Task 02 merged at `d12306c` | prior ladder green | none |
| Invoice creation/PDF | complete | searchable `ProductPicker`, Cash/Credit UX, compliant PDFs | 71 focused tests green; `flutter analyze` info-only | PDF text assertions use helper/metadata tests (compressed PDF bytes are not plain-text searchable) |
| Batch collections | complete | atomic grid API/local/UI | 37 focused mobile tests + 55 pure tests | API integration tests require local Postgres on :55432 |
| Drive backup | complete | encrypted Drive orchestration + UI at Task 05 | 69 backup tests green; debug/release APK green | Physical-device OAuth/sign-in unverified (AC10/AC11 blocked) |
| Analytics | complete | owner KPIs, zero-filled trend, redesigned screen | 19 backend pure + 18 mobile analytics tests green | Postgres parity/API tests need :55432 DB |
| Integration/release | pending | pending | pending | Physical-device evidence depends on available configured device/account |

### Task 03 — Invoice creation and PDFs (2026-06-14)

**Search / entry**
- Replaced `SimpleDialog` with searchable modal (`productSearchField`, `ListView.builder`, cached normalized strings).
- Empty query shows first 50 alphabetically sorted products; 1,199-product fixture builds <60 `ListTile` widgets (no eager 1,199 children).
- Match fields: item name, item number, company, HSN (case-insensitive trim).

**Cash / Credit**
- UI: `SegmentedButton` Cash/Credit; optional `amountReceivedField` on Credit only.
- Controller maps Cash → `TOTAL_PAID` + grand-total paid amount after quote; Credit unpaid/partial with validation (negative, equal/over-total rejected).
- Preview/detail/list show `Cash` or `Credit` via `invoiceSettlementLabel`; no raw `TOTAL_PAID` / `PARTIAL_PAID` labels.

**Non-GST / precision**
- GST line fields and bulk apply hidden when `gstFlag` false; switching off clears line GST overrides.
- Unit prices use three-decimal canonical strings; quantities integral on new drafts.
- Discount editing removed from creation/preview; payload always zero discount.

**PDF policy**
- GST table uses `productHsnCode` snapshot; non-GST omits HSN and all GST columns.
- Removed tax regime, status, and per-line discount columns; historical `discount_total > 0` keeps compact totals-row discount.
- Integer quantity display, 3dp unit prices, widened serial column (`FixedColumnWidth(18)`), A5≤15 / A4>15 preserved.

**Focused verification (Task 03)**
```bash
(cd mobile && flutter test test/widgets/product_picker_test.dart test/widgets/create_invoice_screen_test.dart test/state/invoice_draft_controller_test.dart test/services/invoice_pdf_service_test.dart test/widgets/invoice_preview_screen_test.dart test/widgets/invoice_detail_screen_test.dart test/widgets/invoice_list_screen_test.dart)
(cd mobile && flutter analyze)
```
Result: **71 passed**, analyze info/warnings only (no new errors).

### Task 05 — Encrypted Google Drive backup (2026-06-14)

**Packages (from Task 01 lockfile)**
- `google_sign_in` 7.2.0, `googleapis` 16.0.0, `extension_google_sign_in_as_googleapis_auth` 3.0.0, `workmanager` 0.9.0+3, `flutter_secure_storage` 9.2.2
- Drive scope: `https://www.googleapis.com/auth/drive.file` only

**Implementation**
- Injectable gateways: `GoogleSignInAuthGateway`, `GoogleApisDriveGateway`, `FlutterSecureBackupSecretStore`
- Orchestrator: export → SHA-256 → upload to visible `Khata Backups` folder (app property `khata_owner=khata_app`) → verify download/hash → update `last_backup_at` → prune to 30 owned files
- Foreground UI: connect/disconnect Google, secure password set/change/remove, automatic toggle (default 02:00), Back up now, Drive restore list; manual export/import preserved
- WorkManager unique periodic task + startup catch-up via `AppDependencies` / `main.dart`
- Background callback rebuilds DB/auth/Drive deps without UI; missing auth/password returns action-required (recorded, no retry loop)

**External OAuth setup (not committed)**
- Enable Google Drive API; create Android OAuth client for app package + signing SHA-1/SHA-256; configure consent screen/test users
- No `google-services.json` added to repo

**Focused verification (Task 05)**
```bash
(cd mobile && flutter test test/backup)
(cd mobile && flutter test test/app/app_dependencies_test.dart)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --debug --dart-define=DATA_MODE=local)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```
Result: **69 backup tests passed** (includes fake Drive orchestration, secure-store, scheduler, digest round-trip, screen flows); analyze info/warnings only; debug + release APK green.

**Device evidence (blocked)**
- AC10/AC11 remain unproven: physical sign-in, visible Drive folder/file, background catch-up, wrong-password no-change on device, restore/logout/restart persistence require configured OAuth client + test account on hardware.

**Files touched (summary)**
- New: `google_auth_gateway.dart`, `google_drive_gateway.dart`, `secure_backup_secret_store.dart`, `encrypted_drive_backup_orchestrator.dart`, `test/backup/fake_drive_platform.dart`, `test/backup/drive_backup_orchestrator_test.dart`, `test/backup/drive_backup_digest_test.dart`, `test/backup/backup_test_fixtures.dart`
- Updated: `drive_platform.dart`, `drive_backup_service.dart`, `backup_screen.dart`, `backup_background_callback.dart`, `backup_scheduler.dart`, `workmanager_schedule_adapter.dart`, `app_dependencies.dart`, `main.dart`, backup tests, this log

**Files touched (summary)**
- New: `mobile/lib/screens/daily_collections_screen.dart`, `backend/tests/api/test_customers_batch_collections_api.py`, `backend/tests/services/test_customer_batch_collections_service.py`, `mobile/test/local/local_customers_collections_batch_service_test.dart`, `mobile/test/widgets/daily_collections_screen_test.dart`
- Updated: `backend/app/schemas/customer.py`, `backend/app/services/customer_service.py`, `backend/app/routers/customers.py`, `mobile/lib/services/payments_service.dart`, `mobile/lib/local/local_payments_service.dart`, `mobile/lib/screens/customer_list_screen.dart`, test fakes, this log, `STATE.md`

### Task 04 — Atomic daily collection grid (2026-06-14)

**Backend**
- `GET /customers/collection-grid?from_date&to_date` returns active positive-balance customers with existing collection totals (max seven-day inclusive window, no future/older-than-six-days dates).
- `POST /customers/collection-batch` accepts `{request_id, entries[]}`; canonical sorted-entry hash; row locks via `SELECT … FOR UPDATE`; all-or-nothing commit; idempotent retry via batch notes marker `__batch__|{request_id}|{hash}`; per-entry request IDs via UUID5.
- Errors: `VALIDATION_ERROR`, `STALE_BALANCE`, `IDEMPOTENCY_CONFLICT`, `CUSTOMER_ARCHIVED`.

**Mobile**
- `PaymentsService.loadCollectionGrid` / `recordCollectionBatch` on API and local Drift paths.
- `DailyCollectionsScreen`: seven-day grid (today default), search preserving controller state, existing totals + additional inputs, zero omission, confirmation summary, stale-balance reload preserving unsaved values.
- Customers/Khata app bar action opens daily collections.

**Focused verification (Task 04)**
```bash
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
(cd mobile && flutter test test/services/payments_service_test.dart test/local/local_customers_payments_service_test.dart test/local/local_customers_collections_service_test.dart test/local/local_customers_collections_batch_service_test.dart test/widgets/customer_list_screen_test.dart test/widgets/daily_collections_screen_test.dart)
```
Result: **55 pure + 37 mobile passed**. Postgres-backed API/service tests added but not executed here (Docker daemon unavailable).

### Task 06 — Owner analytics dashboard (2026-06-14)

**Backend / local parity**
- Additive dashboard fields: `total_revenue`, `total_profit`, `customer_receivables`, `buyer_payables`, `active_invoice_count`, `average_invoice_value`, `daily_trend[{date,revenue,profit}]`.
- Revenue/profit from active invoice item snapshots only; average uses invoice `grand_total`; receivables/payables sum ledger breakdown lists; trend zero-fills inclusive date range when both bounds provided.
- Shared parity fixture (`backend/tests/fixtures/analytics_owner_parity.py`) covers GST/non-GST lines, cash/credit/partial, canceled invoice exclusion, two invoice dates, receivable/payable ledgers, product/customer rankings.

**Mobile**
- Redesigned `AnalyticsScreen`: responsive KPI grid, `fl_chart` trend with semantic summary, ranked product/customer cards, receivables/payables summary, presets (Today, 7d, 30d default, Month, Custom with from<=to validation).
- `Dashboard.hasData` ignores `low_stock`; low-stock section removed from UI while API/local still populate the field.

**KPI formulas (parity fixture, 2026-04-01..2026-04-03)**
- Total revenue **350.00** (200 + 150 item revenue; canceled invoice excluded)
- Total profit **140.00**; active invoices **2**; average invoice **175.00**
- Customer receivables **150.00** (200 opening − 50 collection); buyer payables **500.00** (700 − 200 payment)
- Daily trend: Apr 1 **0/0**, Apr 2 **200/80**, Apr 3 **150/60**

**Focused verification (Task 06)**
```bash
PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/services/test_analytics_pure.py -q
(cd mobile && flutter test test/local/local_analytics_service_test.dart test/widgets/analytics_screen_test.dart test/models/analytics_test.dart)
```
Result: **19 backend pure passed**, **18 mobile analytics passed**. Postgres-backed parity/API tests require `BILLING_DATABASE_URL=postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test`.

## Acceptance Evidence

| AC | Status | Evidence |
|---|---|---|
| AC5-AC8 (invoice entry/PDF/settlement) | complete | 71 focused tests; helper PDF layout tests; Cash/Credit label coverage |
| AC12 owner analytics | complete | 19 pure + 18 mobile analytics tests; parity fixture documented | Postgres API/parity test pending local DB |
