# Design: Khata Invoice, Collections, Backup, And Analytics Upgrade

## Verdict

proceed-with-gates

## Objective And User Outcome

The wholesaler must be able to find products quickly in a 1,199-item catalog, issue compliant GST/non-GST invoices, enter daily customer collections in one grid, recover local business data from encrypted Google Drive backups, and understand the business from a useful owner dashboard.

## Neutral Discovery Evidence

- Baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6` on `main`.
- The root workbook and `data/source/products.xlsx` have the same SHA-256 and contain 1,199 products.
- HSN is a separate source column: 109 distinct non-empty codes, 67 repeated codes, and 125 missing values.
- Product IDs and item numbers are already referenced by inventory, invoices, backups, and catalog seeding.
- The invoice product picker builds a `SimpleDialog` option for every product and has no search.
- Product/invoice unit-price persistence is two-decimal; source data includes values such as `3.0075`.
- Quantity persistence permits three decimals in products, invoice lines, and stock movements.
- Discounts remain in invoice contracts and PDF columns.
- Customer collections already use append-only `COLLECTION` ledger rows with `occurred_on`, request-id hashing, and positive two-decimal amounts.
- Backup encryption and manual import/export exist. Drive OAuth/upload and platform scheduling are placeholders.
- Analytics currently renders text lists and includes low stock.

## User Idea And Approved Interpretation

- Add nullable, non-unique product HSN and immutable invoice-line HSN snapshots.
- Keep item numbers stable; do not derive identity from HSN.
- Block a new GST invoice when any selected product lacks HSN; allow that product on non-GST invoices.
- Enforce whole numbers for all new invoice quantities and stock adjustments without rewriting historical fractional values.
- Store unit prices to three decimals and monetary totals to two decimals using decimal half-up rules.
- Disable discounts on new invoices while preserving historical discounted invoices.
- Search products inside invoice creation only.
- Hide all GST fields when non-GST is selected.
- Present Cash and Credit to users while retaining internal payment-state compatibility.
- Add a seven-day atomic batch collection grid under Customers/Khata.
- Implement encrypted Drive backup near 02:00 with catch-up and 30-file retention.
- Replace the analytics list page with an owner KPI/trend/ranking dashboard and remove low stock from that page only.

## Scope

- FastAPI schemas/models/services/routers and Alembic migration.
- Flutter DTOs/services/controllers/screens, Drift migration, catalog build/seeding, backup payload, Android background wiring, and tests.
- PDF generation and rendered artifact review.
- Workflow evidence and handoff.

## Non-Goals

- Invoice-list search.
- Regenerating item numbers, product UUIDs, or invoice identities.
- Guessing the 125 missing HSN values.
- Converting or rounding historical fractional quantities.
- Deleting legacy discount columns or rewriting historical invoice totals.
- Negative customer balances or advance-payment accounting.
- Exact-alarm execution at precisely 02:00.
- Committing OAuth client secrets, signing keys, access tokens, or user backup passwords.
- Fixing the existing example Android application ID or release signing in this cycle.

## Canonical Glossary

- **Customer**: retail shop/receivable ledger owner. The user called these sellers in the batch-entry request.
- **Buyer**: supplier/payable ledger owner.
- **Cash invoice**: invoice fully paid at creation; internal state `TOTAL_PAID`.
- **Credit invoice**: invoice unpaid or partially paid; internal state `CREDIT` or `PARTIAL_PAID` derived from amount received.
- **Existing collection**: immutable sum of collection entries already recorded for a customer/date.
- **Additional collection**: new amount entered in the batch grid; creates a new ledger row.

## Options Considered

1. **UI/PDF-only changes**: rejected because HSN snapshots, precision, quantities, discounts, and payment truth are domain contracts.
2. **Local-only implementation**: rejected because the repository explicitly maintains API/local parity and future migration compatibility.
3. **Contract-first vertical slices**: approved. Migrations and invariants land first, then UX/PDF, collections, Drive, analytics, and integration.

## Architecture And Responsibility Boundaries

- Backend and local services independently enforce identical business rules; UI validation is only an early error surface.
- Invoice creation remains the owner of transactional stock and customer-ledger side effects.
- Product HSN is mutable master data; invoice HSN is an immutable snapshot.
- Batch collection services own validation, idempotency, and one-transaction commit. The screen never loops over the existing single-row API.
- `LocalBackupService` remains the encryption/import authority. Drive code handles authentication, file transport, retention, and scheduling only.
- Analytics services calculate canonical values; widgets only format and visualize returned models.

## Contracts, Types, State, And Data Flow

### Product And Catalog

- Add `hsn_code: str | null` / `String?` to product create, update, response, local table, model, forms, catalog JSON, and seeder records.
- Keep `item_number` unique and unchanged.
- Catalog version becomes 2. The builder reads the existing `hsn_code` source column and writes `null` for blank cells.
- Seeder update policy for an existing catalog row: match by stable item number, populate HSN and revised three-decimal prices, preserve user-owned stock quantity and active state. Do not duplicate or reset inventory.

### Precision And Quantity

- Backend product prices and invoice unit-price snapshots become `Numeric(14,3)`; local values remain canonical decimal strings but are normalized to three places at write boundaries.
- Buying price participates in profit calculation at three decimals; revenue/tax/profit/totals remain quantized to two decimals.
- New invoice quantities must satisfy `value > 0 && value == value.to_integral_value()`.
- New stock adjustment deltas must be non-zero integral values; opening catalog quantities and product creation quantities must be non-negative integral values.
- Historical rows remain in existing decimal-capable columns and continue to render/read.

### Invoice HSN, Discount, And Payment

- Add nullable `product_hsn_code` to quote/detail line responses and invoice-item persistence.
- GST quote/create resolves every product and fails with `MISSING_PRODUCT_HSN` before totals or side effects when HSN is blank.
- Non-GST quote/create permits missing HSN and emits no GST/HSN document fields.
- New requests reject non-zero `discount_percent` with `DISCOUNTS_DISABLED`; default remains zero for wire compatibility.
- User-facing `payment_mode` is `CASH` or `CREDIT`. The create payload may retain `payment_state` for compatibility, but the mobile controller derives it:
  - Cash: `TOTAL_PAID`, paid amount resolved to grand total after quote.
  - Credit + zero received: `CREDIT`, paid amount zero.
  - Credit + received amount between zero and total: `PARTIAL_PAID`.
  - Credit amount equal to/exceeding total is rejected with guidance to select Cash.
- Existing API clients using valid legacy `payment_state` continue to work.

### Batch Collections

- Add a read endpoint/service method for active positive-balance customers and existing `COLLECTION` sums in an inclusive seven-day range.
- Add an atomic batch write contract:

```text
request_id: UUID
entries: [{customer_id: UUID, occurred_on: date, amount: Decimal(14,2)}]
```

- Omit zero/blank UI cells from `entries`; the API rejects transmitted zero/negative amounts.
- Dates must be distinct per customer/date pair and within today through today-minus-six-days, evaluated in the app/business local date.
- Validate customer existence/activity, date window, duplicate cells, amount precision, and per-customer aggregate against a locked/current balance before insert.
- Hash the canonical sorted entry list. A repeated request ID with the same hash returns the prior result; a different hash returns `IDEMPOTENCY_CONFLICT`.
- Commit every collection row or none. Return entry count, total amount, affected customers, and refreshed balances.

### Google Drive Backup

- Packages: `google_sign_in`, `googleapis` Drive v3, `extension_google_sign_in_as_googleapis_auth`, and `workmanager`; choose latest versions compatible with the current SDK and commit `pubspec.lock`.
- Request only the Drive file scope needed to create/read app-created files in the visible `Khata Backups` folder.
- Store the user-created backup password through a dedicated secure-storage key, separate from auth tokens.
- Upload the existing encrypted `.khata` package with app properties identifying schema, compatibility version, created timestamp, and content SHA-256.
- Verify uploaded metadata and downloaded/hashable content identity before success.
- Prune only app-owned successful backup files after a verified upload, retaining newest 30.
- WorkManager uses unique periodic work, network-connected constraint, initial delay to the next local 02:00, retry/backoff, and app-launch catch-up. Scheduling is best effort.
- Background execution must recreate local dependencies without relying on widget state.
- Restore lists newest first, downloads to memory/temp storage, validates/decrypts fully, then uses existing transactional replacement and logout behavior.

### Analytics

- Add KPI fields: revenue, profit, receivables, payables, active invoice count, average invoice value.
- Add daily revenue/profit trend points for the selected inclusive date range.
- Reuse/add ranked product and customer series by revenue/profit as required by the UI.
- Keep `low_stock` in backend/local models for compatibility but do not use it to determine analytics empty state or render it on the screen.
- Presets: Today, Last 7 days, Last 30 days, This month, Custom. Custom rejects from-date after to-date.

## Persistence, Migration, And Compatibility

- Alembic `0010` adds product/invoice-item HSN and widens price columns to scale 3 without changing values, identifiers, quantities, ledgers, totals, or invoice status.
- Drift schema 10 adds the same fields. Migration uses additive columns and table recreation only where SQLite constraints require it; copy every existing column explicitly.
- Backup schema 10 includes both new HSN fields and keeps `backend_compatibility_version = local-v2` unless the existing compatibility contract requires a bump. Version 9 restore policy: accept and migrate by injecting null HSN; version 10 is canonical. Older unsupported versions remain rejected.
- Historical GST invoices with null HSN remain readable and render a blank HSN cell; only new GST writes are blocked.
- Historical discounted invoices continue to show enough totals to reconcile. New invoices have no discount column/row.

## Failure, Recovery, And Fallback Behavior

- Every validation error occurs before stock, invoice, or ledger writes.
- Batch conflict/stale balance returns one error and writes nothing; UI reloads the grid while preserving unsaved values for user comparison.
- Google sign-in cancellation leaves automatic backup disabled.
- Token/consent failure records a configuration/auth event and requires foreground reauthentication; background work must not open UI.
- Upload failure never prunes old backups and never advances `last_backup_at`.
- Restore failure leaves the active database untouched and records a redacted failure event.
- Analytics load failure keeps Retry and does not display stale values as current unless explicitly labeled.

## Observability, Rollout, And Rollback

- Backup events distinguish sign-in, schedule, upload, verify, prune, download, restore, catch-up, and failure without recording secrets or payload data.
- Batch collection result and errors expose request ID and counts, not sensitive notes.
- Roll out migrations before API clients. Local APK migration runs once on app start.
- Keep the previous APK and a verified encrypted backup before device rollout.
- Rollback to a build that understands schema 10 is permitted; older builds are not a safe rollback target after migration.

## Scenario Matrix

| Scenario | Expected behavior | Evidence | Launch blocking? |
|---|---|---|---|
| GST item has HSN | Snapshot HSN and create normally | API/local tests | yes |
| GST item missing HSN | Reject before side effects | API/local tests | yes |
| Non-GST item missing HSN | Create with no GST/HSN output | tests + PDF artifact | yes |
| Fractional new quantity | Reject in invoice/product adjustment | contract tests | yes |
| Historical fractional quantity | Read/render unchanged | migration fixture | yes |
| New non-zero discount | Reject | contract tests | yes |
| Historical discounted invoice | Reconciles truthfully | fixture PDF | yes |
| Batch contains blank/zero cells | Omit cells; commit other valid entries | service/widget tests | yes |
| Batch overpays one customer | Reject entire batch | transaction test | yes |
| Same batch retried | Return same result, no duplicates | idempotency test | yes |
| Drive upload verifies | Mark success, then prune to 30 | adapter test + device | yes |
| Drive upload fails | Keep prior backups; retry/catch up | adapter test | yes |
| Wrong restore password | No data changes | digest test | yes |
| Analytics has no low stock but has invoices | Dashboard still shows data | widget/service test | yes |

## Acceptance Criteria

| ID | Required outcome | Proof | Blocking? |
|---|---|---|---|
| AC1 | Catalog imports HSN and preserves identity | builder/seeder tests + identity diff | yes |
| AC2 | GST rejects missing HSN; non-GST accepts | backend/local domain tests | yes |
| AC3 | New quantities integral; history preserved | validators + migration fixture | yes |
| AC4 | Three-decimal unit prices, two-decimal totals | paired pricing fixtures | yes |
| AC5 | Search picker handles 1,199 products | widget performance/behavior + device | yes |
| AC6 | Non-GST exposes no GST UI/PDF fields | widget + PDF text tests | yes |
| AC7 | Cash/Credit matches ledger truth | controller/service/E2E tests | yes |
| AC8 | Four aligned PDF variants | page/text tests + rendered review | yes |
| AC9 | Batch collections atomic/idempotent/zero-safe | API/local transaction tests | yes |
| AC10 | Drive upload verifies/retries/catches up/retains 30 | adapter + configured device | yes |
| AC11 | Restore reproduces canonical data digest | seeded round-trip test | yes |
| AC12 | KPI/charts match canonical calculations | API/local parity + widgets | yes |
| AC13 | Existing backups/invoices remain readable | v9 restore + historical fixtures | yes |
| AC14 | Full regression, analysis, migrations, APK pass | recorded commands/hashes | yes |

## Deferred Work

- App ID, production signing, iOS backup scheduling, multilingual PDF fonts, invoice-list search, and advance-customer-credit accounting.
