# Stage 5 Final Review

Cycle: `20260618-hybrid-supabase`

Final integration worktree: `/Users/abhishek/python_venv/khata_app`

Final integration branch: `main`

Stage 5 baseline: `9263520ff18faf7e23fddc137c8a88adc46fa530`

Review mode: `review_and_fix`

## Verdict

`production-code-validated-awaiting-physical-device-smoke`

The Stage 4 code blockers are fixed and merged into `main`. Hybrid production
runtime now uses Supabase as the write authority for official business writes,
Drift as the read/cache layer, and row-level sync for all business tables needed
by invoice create/cancel and ledger visibility.

The main-branch APK is ready for controlled physical-device testing. A real
Supabase two-client run now proves login, full cache sync, RPC create, second
client sync, RPC cancel, and reverse sync using independent Drift databases.
The remaining gap is Android phone/UI evidence, not data-authority evidence.

## Fixes Applied

1. AC9 official write routing

   Hybrid mode now wires official writes through Supabase RPC wrappers:

   - `HybridProductsService`
   - `HybridCustomersService`
   - `HybridBuyersService`
   - `HybridCompanyProfileService`
   - `HybridPaymentsService`
   - `HybridInvoicesService`

   Local services remain as Drift read/cache delegates and reference-test
   implementations, but they are no longer the hybrid write authority.

2. Sync completeness

   `HybridSyncService.syncAll()` now upserts the previously missing business
   tables:

   - `stock_movements`
   - `customer_transactions`
   - `buyer_transactions`

   This closes the Stage 4 split-brain risk where invoice cancel, stock movement,
   customer ledger, and buyer ledger rows could exist in Supabase without being
   reflected in the local Drift cache.

3. RPC coverage

   Added Supabase RPCs for:

   - buyer create/update/archive/reactivate
   - customer ledger entries
   - batch collections
   - buyer ledger entries

   Strengthened existing collection/stock RPCs with current-row validation for
   archived customers/products. Fixed `adjust_stock` to return the updated
   canonical product row after quantity mutation.

4. Idempotency/hash correctness

   Invoice confirm now builds one `invoice_datetime` value and uses it for both
   the RPC payload and `request_hash`. Before this fix, payload and hash could
   be generated from two different `DateTime.now()` calls.

5. Hybrid-only runtime reachability

   `DATA_MODE=api` and `DATA_MODE=local` are rejected by runtime parsing. The
   production app path accepts only empty/default or `DATA_MODE=hybrid`.

6. Documentation

   Updated root/mobile docs and workflow state so reviewers do not follow stale
   API/local runtime commands as production instructions.

7. Write latency

   Official writes now apply canonical RPC response rows directly into Drift and
   return without awaiting a full remote refresh. A debounced background sync,
   app-resume sync, manual sync, and a 10-minute in-app periodic sync reconcile
   other-device changes.

8. Main integration

   Integrated the reviewed feature tree into `main` as clean squash
   `a4a3101a064c1cb4e60af25d6d6e4023e6a5e2c3`, preserving newer main fixes for
   catalog pagination/recovery, authentication, catalog v6, and invoice PDFs.
   The original local merge graph is retained on
   `codex/main-pre-sanitize`; it was not pushed because an old ancestor
   contained a committed `.env`.

9. Final runtime cleanup

   Removed compiled mobile API/local-auth/backup runtime code, Google/Drive and
   WorkManager dependencies, local setup and backup screens, and obsolete tests.
   Drift schema 12 migrates the catalog version out of `backup_settings` and
   removes old session/backup tables.

10. Live Supabase pagination and two-client validation

   A first real run exposed that Supabase capped a requested 2,000-row page at
   1,000 rows. Sync treated that as the final page and cached only 1,000 of 1,530
   active products. The client now uses 1,000-row pages ordered by stable `id`.
   The repeated live run loaded all 1,530 products on both clients and passed
   create invoice, second-client sync, cancel, and reverse sync. Cleanup left no
   temporary product or customer rows.

## Validation Evidence

| Check | Result |
| --- | --- |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| `flutter test test` | pass, 379 current-runtime tests |
| `bash tools/run_remote_two_client_smoke.sh` | pass, father/brother auth plus create/sync/cancel/resync |
| `python3 tools/test_catalog_parity.py` | pass, 30 buyers and 1528 products |
| `bash tools/check_hybrid_runtime_cleanup.sh` | pass |
| `flutter analyze` | pass, no issues |
| `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` | pass, `build/app/outputs/flutter-apk/app-release.apk` 66.4 MB |
| Static scan: `service_role`, client `max(invoice_number)`, `invoice_number + 1` | no hits in `mobile/lib`, `supabase`, `tools` |

## Remaining Manual Evidence

Before family cutover, run this exact-device checklist:

1. Apply migrations to the chosen Supabase project.
2. Seed from `data/source/MASTER CATALOG.xlsx` output.
3. Create father/brother/operator Supabase Auth users.
4. Install the built APK on primary and secondary devices.
5. Login on primary and force initial sync.
6. Verify product count `1528`, buyer count `30`, company profile, customer list,
   and a sample invoice preview.
7. Confirm one invoice on the primary device.
8. Sync on the secondary device and verify invoice header/items, customer ledger,
   stock movement, and product quantity match Supabase.
9. Cancel the invoice on either device.
10. Sync the other device and verify invoice status, stock reversal, and ledger
    reversal match Supabase.

## Residual Risks

- Physical Android install/navigation/share/resume proof remains pending.
- Realtime subscriptions remain intentionally out of scope for V1; sync is
  startup/resume/manual/post-write.
- Offline official writes remain intentionally blocked; offline draft/preview
  reads remain supported from Drift cache.
- The historical FastAPI backend remains in `backend/` as a non-runtime oracle;
  the Flutter package no longer contains API/local-auth/backup runtime adapters.

## Release Guidance

`main` is ready for controlled phone/device validation. If manual device
validation fails, capture the failing step before family cutover and fix it on a
new branch from `main`.
