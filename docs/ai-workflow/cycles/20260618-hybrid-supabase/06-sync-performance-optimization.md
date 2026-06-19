# Sync Performance Optimization

Cycle: `20260618-hybrid-supabase`

Problem: hybrid writes were correct but slow because every official write awaited
`syncAll(forceFull: true)`. A product/customer/invoice write therefore blocked on
a full Supabase-to-Drift refresh before the UI could continue.

## Options Considered

1. Await full sync after every write

   - Behavior: call RPC, then block on full table sync.
   - Pros: simple mental model and strong eventual local consistency.
   - Cons: terrible UX as catalog/ledger data grows; every write pays for all
     tables even when the RPC already returned canonical rows.
   - Verdict: rejected. This was the current implementation and caused the
     roughly one-minute action latency.

2. Apply RPC result immediately, debounce background full sync

   - Behavior: call RPC, upsert canonical rows returned by that RPC into Drift,
     return to the UI, then schedule a debounced background `syncAll()`.
   - Pros: fast write completion, keeps local cache correct for the just-written
     rows, still catches second-device changes, and stays simple for 2-3 users.
   - Cons: RPCs must return every row needed for immediate cache correctness.
   - Verdict: implemented.

3. Realtime subscriptions or offline write queue

   - Behavior: subscribe to table changes or queue offline writes for replay.
   - Pros: lower staleness across devices and richer offline behavior.
   - Cons: more moving parts, conflict rules, lifecycle complexity, and testing
     burden than this family-scale app needs today.
   - Verdict: deferred. Revisit only if manual refresh/resume/periodic sync is
     not enough in real use.

## Implemented Flow

1. Official write calls Supabase RPC.
2. RPC returns canonical rows.
3. Mobile applies those returned rows into Drift using
   `HybridSyncService.applyRpcResult(...)`.
4. UI returns after the small local upsert, not after a full remote refresh.
5. `HybridSyncService.scheduleBackgroundSync()` debounces a full sync in the
   background.
6. While the app is authenticated and open, a simple 10-minute periodic
   background sync also runs. App resume still triggers sync as before.

## RPC Response Completeness

Invoice create/cancel now return updated `products` alongside invoice, item,
stock movement, and customer transaction rows. This is required so stock changes
are visible in Drift immediately after invoice confirm/cancel without waiting
for a background table scan.

## Validation

| Check | Result |
| --- | --- |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| `flutter test test/hybrid test/app/app_mode_test.dart` | pass, 22 tests |
| `flutter test test` | pass, 493 tests |
| `python3 tools/test_catalog_parity.py` | pass, 30 buyers and 1528 products |
| `flutter analyze` | no errors; 51 warnings/info remain |
| `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` | pass, `build/app/outputs/flutter-apk/app-release.apk` 68.7 MB |

## Manual Check

On device, confirm that add product, add customer, record collection, confirm
invoice, and cancel invoice return after the RPC/local-upsert path instead of
waiting for a full sync. Then leave a second device open and verify it catches
changes via resume/manual/periodic sync.
