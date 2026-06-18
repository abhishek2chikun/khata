# Task 04: Implement Mobile Supabase Auth, Sync, Drift Cache, And Hybrid Services

## Outcome

Replace reachable API/local runtime behavior with one hybrid mobile path: Supabase Auth, Supabase RPC writes, Drift cache reads, row-level sync, and visible sync/offline status.

## Why This Task Exists

Users need multi-device correctness without running a custom server. Mobile must stop acting as authority while preserving fast local reads, invoice preview, PDF/share, collections, and analytics.

## Dependencies

- Task 02 stable schema/RPC contracts.
- Task 03 seed outputs and catalog IDs.

## Repository Evidence

Read current analogs before editing:

- `mobile/lib/main.dart`
- `mobile/lib/app_dependencies.dart` or equivalent dependency wiring
- `mobile/lib/api/`
- `mobile/lib/local/`
- `mobile/lib/screens/login_screen.dart`
- `mobile/lib/screens/create_invoice_screen.dart`
- `mobile/lib/screens/invoice_preview_screen.dart`
- `mobile/lib/screens/invoice_pdf_preview_screen.dart`
- `mobile/lib/backup/`
- `mobile/test/`

## Read Before Editing

1. `01-supabase-schema-rpc.md`
2. `02-catalog-seeding.md`
3. `../02-design.md` data flow and failure semantics
4. Current service interfaces and Drift DAOs

## Scope

### Change

- Add `supabase_flutter` and initialize using `--dart-define=SUPABASE_URL` and `--dart-define=SUPABASE_ANON_KEY`.
- Replace API/local auth internals with Supabase email/password auth.
- Add cache metadata for hybrid initialization and sync cursors/status.
- Add `HybridSyncService`.
- Add hybrid implementations behind existing service interfaces.
- Update invoice confirm/cancel and write flows to call RPC.
- Add sync status UI and offline official-write errors.

### Preserve

- Current login UX concept where practical.
- Existing screens and workflows.
- Cached invoice PDF/share rendering.
- Draft/preview behavior before official confirmation.
- GST/non-GST, HSN, precision, collections, analytics.

### Explicitly out of scope

- Realtime subscriptions.
- Offline official write queue.
- Google Drive/local backup repair.
- Play Store signing.

## Contracts And Invariants

- `Preview invoice` writes nothing official.
- `Confirm invoice` calls `create_invoice` exactly once per stable `request_id` submission attempt.
- `request_id` remains stable across retry until the draft changes.
- Post-confirm UI uses canonical Supabase result upserted into Drift.
- Official writes are blocked offline or without valid Supabase session.
- Reads come from Drift cache; sync refreshes cache by row upsert.
- Normal sync must never whole-DB replace Drift.
- First hybrid init may clear/rebuild business cache only after Supabase auth/setup check.
- Supabase service role key is never present in Flutter.

## Implementation Guidance

Configuration:

- Add `supabase_flutter`.
- Initialize early with dart defines.
- Missing config shows a setup error before business screens.

Auth:

- Email/password sign in through Supabase Auth.
- Session restore uses Supabase session.
- Logout signs out Supabase and clears local secure session.
- Remove local first-user setup from reachable runtime in Task 05 after parity.

Drift cache metadata:

- hybrid cache initialized flag
- last successful sync timestamp
- per-table cursor or table watermark
- last sync error summary
- no Supabase secrets

`HybridSyncService`:

- `initializeAfterLogin()`
- `syncAll(reason)`
- `syncTable(tableName, since)`
- `markHybridInitialized()`
- `resetBusinessCacheFromSupabase()`
- `lastSyncState`

Sync triggers:

- after login/session restore
- app startup
- app resume
- manual refresh
- after each successful RPC write

Sync order:

1. buyers
2. customers
3. company_profiles
4. products
5. invoices
6. invoice_items
7. stock_movements
8. customer_transactions
9. buyer_transactions

Hybrid services:

- `HybridProductsService`
- `HybridCustomersService`
- `HybridBuyersService`
- `HybridCompanyProfileService`
- `HybridPaymentsService`
- `HybridInvoicesService`
- `HybridAnalyticsService`

Write path:

1. Local input validation.
2. Connectivity/session check.
3. RPC call.
4. Upsert canonical rows into Drift.
5. Trigger related post-write sync.

## Test-First Specification

Add tests that fail before implementation:

- Supabase auth adapter restores and signs out session.
- Missing Supabase config blocks business shell with setup error.
- First hybrid init clears old business rows and rebuilds from fake Supabase rows.
- Startup/resume/manual/post-write sync calls row upsert and preserves unrelated cached rows.
- Offline official writes are blocked.
- Product/customer/buyer/company/collection writes call RPC and upsert returned rows.
- Invoice preview does not call `create_invoice`.
- Confirm invoice calls `create_invoice` once with stable `request_id`.
- Cancel invoice calls `cancel_invoice` and upserts canonical status/reversal rows.
- Existing invoice PDF/share reads from cached canonical rows.
- App starts without `DATA_MODE` runtime selection.

## Validation Ladder

Focused:

```bash
(cd mobile && flutter test test/<focused hybrid/auth/sync tests>)
```

Broader:

```bash
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
rg -n "DATA_MODE|max\\(invoice|invoice_number\\s*\\+\\s*1|service_role|Google Drive|Backup" mobile/lib mobile/test
```

Expected evidence:

- Hybrid tests pass.
- No official write path bypasses RPC.
- No client-side official invoice numbering remains reachable.

## Review Checklist

- Offline writes fail clearly.
- Cached reads still work when sync fails.
- Sync status has synced/syncing/failed/stale states.
- Post-write Drift upsert handles partial local cache failure by surfacing retry/refresh state.
- Invoice PDF/share uses canonical confirmed invoice rows.

## Allowed Adaptation

If existing service interfaces are too local/API-specific, add narrow hybrid interfaces but keep screen changes minimal and documented.

## Stop And Escalate If

- Existing screens require direct Drift writes for official records.
- RPC return payloads lack enough canonical rows to update cache.
- Sync needs full replace during normal operation.
- Auth/session behavior would require storing private Supabase credentials locally.

## Commit Checkpoint

Commit after focused mobile hybrid tests pass. Suggested message: `feat(hybrid): wire supabase auth sync and services`.

## Done When

The app can login, sync, read cached data, preview invoices locally, confirm/cancel through RPC, and update Drift from canonical Supabase results.

## Handoff Update

Add to `03-implementation-log.md`: changed service classes, sync metadata, tests, offline behavior evidence, known limitations, and next task.

Update `STATE.md`: Task 04 status, mobile validation evidence, and current task `Task 05`.
