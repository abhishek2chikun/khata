# Workflow State

Cycle ID: `20260618-hybrid-supabase`

Current stage: `5-final-review-and-fix`

Stage status: `production-code-validated-awaiting-physical-device-smoke`

Persistent LLM lane: `paused-after-stage-2`

Current owner: `Stage 5 persistent LLM`

Next owner: `Stage 5 persistent LLM`

Current task: Install the final main-branch APK on both family phones and run the physical-device UI smoke

Stage 2 planning baseline SHA: `c7fff583b72b4f1ed2e8eb1` (docs commit on main)

Stage 3 implementation baseline SHA: `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`

Stage 3 final HEAD: `ec9afd9b7dca4e03296f602c8489287d9409dc63`

Stage 4 final HEAD: `d6eb15b2b2e8b11437d121650ff6d30dfd137320` (docs SHA); feature fix at `420d7ae`

Stage 5 fix baseline HEAD: `9263520ff18faf7e23fddc137c8a88adc46fa530`

## Verdict
production-code-validated-awaiting-physical-device-smoke

## Git And Worktree Contract

Integration target branch: `main`

Feature branch: `codex/hybrid-supabase`

Canonical worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Supabase project ref: `ekwkklcfovwarcvvxtiq`

Safety backup branch: `main_backup` @ `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1` (remote verified)

Merge owner: Stage 5 persistent LLM

Merge authorization: required

Merge status: integrated and pushed as clean squash
`a4a3101a064c1cb4e60af25d6d6e4023e6a5e2c3`

Worktree cleanliness: clean after final validation follow-up commit

## Stage 4 Summary

Independent validation reran catalog parity, remote SQL migrations, the full Flutter suite, and analyze. Stage 4 fixed hybrid sync lifecycle wiring and added cache cutover tests.

Stage 5 fixes completed:
- AC9: hybrid mode now wires product/customer/buyer/payment/company/invoice official writes through Supabase RPC wrappers.
- Sync completeness: `HybridSyncService` now syncs stock movements, customer transactions, and buyer transactions.
- Task 05 runtime reachability: `DATA_MODE=api|local` now throws; production runtime accepts only empty/hybrid.
- SQL proof: smoke tests now exercise invoice create/idempotency/conflict, second invoice numbering, cancel stock/ledger reversal, collection, customer ledger, and buyer ledger RPCs.
- Write latency: RPC results are applied directly to Drift, while debounced and 10-minute background syncs reconcile other-device changes without blocking the write UI.
- Integration: the reviewed feature tree was applied as a clean squash onto
  `origin/main`, preserving the newer main catalog, pagination, authentication,
  and PDF fixes without importing an old commit that contained `.env`.
- Final Task 05 cleanup: removed mobile FastAPI adapters, local-only auth/setup,
  Drive/local backup UI and services, WorkManager hooks, backup dependencies,
  and obsolete tests. The historical `backend/` directory remains reference-only.
- Drift v12: replaced misuse of `backup_settings` for catalog metadata with
  `catalog_cache_settings`; the v11 migration preserves the catalog version and
  drops legacy session/backup tables.
- Live pagination correction: real Supabase validation exposed the project
  1,000-row response cap. Sync now requests 1,000-row pages with deterministic
  `id` ordering and loads all 1,530 active remote products.
- Live two-client proof: father and brother test users used independent Supabase
  sessions and independent in-memory Drift caches to create/sync/cancel/resync an
  invoice. Temporary rows were removed with zero test artifacts remaining.

Final validation evidence:
- `bash supabase/tests/run_migrations_and_tests.sh`: pass.
- `flutter test test/hybrid test/app/app_mode_test.dart`: pass.
- `flutter test test`: pass, 379 current-runtime tests.
- `bash tools/run_remote_two_client_smoke.sh`: pass, two authenticated clients.
- `python3 tools/test_catalog_parity.py`: pass, 30 buyers and 1528 products.
- `bash tools/check_hybrid_runtime_cleanup.sh`: pass.
- `flutter analyze`: pass, no issues.
- `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`: pass, `build/app/outputs/flutter-apk/app-release.apk` 66.4 MB.

Remaining evidence required before family production cutover:
- Install and UI smoke on the two physical family phones remains unverified.
- Confirm login, drawer/navigation, PDF/share chooser, resume sync, and acceptable
  foreground latency on the actual Android builds.
- Replace debug signing with a stable, backed-up release keystore before the
  final long-lived family installation (not required for this test APK).

Artifacts:
- `04-validation-report.md`
- `04-return-packet.md`
- `03-implementation-log.md` (Stage 3; partially stale)
- `05-final-review.md`

## Minimum Read Set For Stage 5

1. This file
2. `02-llm-review-anchor.md`
3. `04-return-packet.md`
4. `04-validation-report.md`
5. `05-final-review.md`
6. Diff `1fe37ee..HEAD`

## Exact Next Action

Install the final main-branch APK on both phones and run the physical-device UI checklist in `07-production-readiness-validation.md`. The authority, RPC, two-client cache sync, create, and cancel paths now have real Supabase evidence; only device/UI behavior remains.
