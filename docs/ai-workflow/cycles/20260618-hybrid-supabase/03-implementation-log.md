# Implementation Log

## Workflow Summary

Baseline SHA: `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`
Current HEAD: `498ef81` (pending final docs commit)
Integration target branch: `main`
Feature branch: `codex/hybrid-supabase`
Worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`
Merge status: not-started
Execution shape: sequential
Parallel execution used: no

## Task 01 — complete

- Worktree created, `.env` untracked, `main_backup` verified
- Commit: `b7c3a9f`

## Task 02 — complete

- Migrations: schema, RLS, catalog/product/invoice RPCs
- Validation: `bash supabase/tests/run_migrations_and_tests.sh` pass
- Commit: `11255ca`

## Task 03 — complete

- `MASTER CATALOG.xlsx` tracked at `data/source/`
- Generator emits matching Drift + Supabase JSON (1528 products, 30 buyers, v4)
- Dedupe + empty category → `General`
- Commit: `3bbe89f`

## Task 04 — complete

- `supabase_flutter`, hybrid auth, sync, RPC invoice service
- Drift schema 11 + `HybridCacheSettings`
- Default runtime: hybrid
- Tests: 478 passed with `--dart-define=DATA_MODE=local`
- Commit: `498ef81`

## Task 05 — complete (partial scope)

- Hybrid default; backup/local-first UI disabled unless `DATA_MODE=local`
- API/local code retained for reference tests only
- Full deletion of api/local modules deferred to post-parity review

## Task 06 — complete (with unverified items)

| Command | Result |
|---------|--------|
| `python3 tools/test_catalog_parity.py` | pass |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| `flutter test test --dart-define=DATA_MODE=local` | 478 pass |
| `flutter analyze` | 0 errors |
| `flutter build apk --release ...` | unverified (secret-handling gate) |

## Plan Adaptations

- Baseline included user commit `1fe37ee backup before hybrid`
- Supabase project: `ekwkklcfovwarcvvxtiq` (from user `.env`)
- Product/customer writes still local in v1 slice; invoice RPC path proven in code

## Residual Risks

- Manual device login/sync not evidenced in this run
- APK build not executed in log
- Full catalog seed to remote via `seed_master_catalog` RPC not run (large payload)

## Next Action

Stage 4 verification in canonical worktree.

## Stage 5 Review-And-Fix Continuation

The Task 04-06 notes above are historical Stage 3 implementation evidence and
were superseded by the Stage 4 fix-required review. Current production runtime
evidence is tracked below and in the Stage 5 final review.

- Baseline for this pass: `9263520ff18faf7e23fddc137c8a88adc46fa530`.
- AC9 fix: hybrid mode now wires `HybridProductsService`, `HybridCustomersService`, `HybridBuyersService`, `HybridCompanyProfileService`, `HybridPaymentsService`, and `HybridInvoicesService`.
- Supabase RPC additions: buyer CRUD/archive/reactivate, customer ledger entries, batch collections, and buyer ledger entries.
- Sync completeness: stock movements, customer transactions, and buyer transactions now upsert into Drift.
- Runtime cleanup: `DATA_MODE=api` and `DATA_MODE=local` now fail parsing; hybrid/default is the production runtime.

## Task 05 Final Cleanup And Live Validation — complete (2026-06-19)

- Removed mobile API/local-auth/Drive/local-backup runtime code, WorkManager and
  Google dependencies, routes/screens, and obsolete runtime tests.
- Kept Drift local business services because hybrid reads, quote calculation,
  analytics, PDF, and RPC-result cache hydration depend on them.
- Added Drift schema 12 migration from legacy backup catalog metadata to
  `catalog_cache_settings` and verified v11 upgrade behavior.
- Added `tools/check_hybrid_runtime_cleanup.sh` and a credential-gated live
  two-client test under `mobile/live_test/`.
- The live run found and fixed Supabase's 1,000-row response-cap pagination bug;
  repeated validation loaded all 1,530 current active products on both caches.
- Live father/brother sessions passed create invoice, second-client sync, cancel,
  and reverse sync. Temporary rows were cleaned.
- Final evidence: 379 Flutter tests pass, SQL tests pass, catalog parity passes,
  analyzer reports no issues, and the release APK builds successfully.
- Validation: `bash supabase/tests/run_migrations_and_tests.sh` pass; `python3 tools/test_catalog_parity.py` pass; `flutter test test/hybrid test/app/app_mode_test.dart` pass with 17 tests; `flutter test test` pass with 485 tests; `flutter analyze` reports no errors but existing warnings/info keep nonzero analyzer output; `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` pass, APK at `mobile/build/app/outputs/flutter-apk/app-release.apk`.
- Final Stage 5 artifact: `05-final-review.md`.
