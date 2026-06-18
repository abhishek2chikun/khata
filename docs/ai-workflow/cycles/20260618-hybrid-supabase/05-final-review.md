# Stage 5 Final Review

Cycle: `20260618-hybrid-supabase`

Worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Branch: `codex/hybrid-supabase`

Stage 5 baseline: `9263520ff18faf7e23fddc137c8a88adc46fa530`

Review mode: `review_and_fix`

## Verdict

`accept-with-manual-cutover-validation`

The Stage 4 code blockers are fixed in the feature branch. Hybrid production
runtime now uses Supabase as the write authority for official business writes,
Drift as the read/cache layer, and row-level sync for all business tables needed
by invoice create/cancel and ledger visibility.

Do not merge to `main` as a production release until the manual Supabase
login/initial sync/two-device scenario is run against the exact built APK. The
remaining gap is operational evidence, not an automated code-test failure found
in this pass.

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

## Validation Evidence

| Check | Result |
| --- | --- |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| `flutter test test/hybrid test/app/app_mode_test.dart` | pass, 17 tests |
| `flutter test test` | pass, 485 tests |
| `python3 tools/test_catalog_parity.py` | pass, 30 buyers and 1528 products |
| `flutter analyze` | no errors; existing 44 warnings/info remain |
| `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` | pass, `build/app/outputs/flutter-apk/app-release.apk` 68.7 MB |
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

- Manual Supabase Auth/device session proof was not run in this automated pass.
- Realtime subscriptions remain intentionally out of scope for V1; sync is
  startup/resume/manual/post-write.
- Offline official writes remain intentionally blocked; offline draft/preview
  reads remain supported from Drift cache.
- API/local/backup implementation files still exist for historical tests and
  reference, but production runtime parsing and hybrid dependency wiring make
  them unreachable from the default app path.

## Merge Guidance

This branch is ready for controlled phone/device validation. After the manual
two-device checklist passes, the Stage 5 owner may merge with an
`accept-with-followups` verdict. If manual device validation fails, do not merge;
capture the failing step and return to Stage 3 implementation.
