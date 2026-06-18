# Workflow State

Cycle ID: `20260618-hybrid-supabase`

Current stage: `5-final-review-and-fix`

Stage status: `accept-with-manual-cutover-validation`

Persistent LLM lane: `paused-after-stage-2`

Current owner: `Stage 5 persistent LLM`

Next owner: `Stage 5 persistent LLM`

Current task: Run manual Supabase login/initial-sync/two-device cutover validation before merge

Stage 2 planning baseline SHA: `c7fff583b72b4f1ed2e8eb1` (docs commit on main)

Stage 3 implementation baseline SHA: `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`

Stage 3 final HEAD: `ec9afd9b7dca4e03296f602c8489287d9409dc63`

Stage 4 final HEAD: `d6eb15b2b2e8b11437d121650ff6d30dfd137320` (docs SHA); feature fix at `420d7ae`

Stage 5 fix baseline HEAD: `9263520ff18faf7e23fddc137c8a88adc46fa530`

## Verdict
accept-with-manual-cutover-validation

## Git And Worktree Contract

Integration target branch: `main` @ `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`

Feature branch: `codex/hybrid-supabase`

Canonical worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Supabase project ref: `ekwkklcfovwarcvvxtiq`

Safety backup branch: `main_backup` @ `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1` (remote verified)

Merge owner: Stage 5 persistent LLM

Merge authorization: required

Merge status: not-started

Worktree cleanliness: dirty with Stage 5 review-and-fix changes and final review artifact

## Stage 4 Summary

Independent validation reran catalog parity, remote SQL migrations, full Flutter suite (481 pass), and analyze (0 errors). Stage 4 fixed hybrid sync lifecycle wiring and added cache cutover tests.

Stage 5 fixes completed:
- AC9: hybrid mode now wires product/customer/buyer/payment/company/invoice official writes through Supabase RPC wrappers.
- Sync completeness: `HybridSyncService` now syncs stock movements, customer transactions, and buyer transactions.
- Task 05 runtime reachability: `DATA_MODE=api|local` now throws; production runtime accepts only empty/hybrid.
- SQL proof: smoke tests now exercise invoice create/idempotency/conflict, second invoice numbering, cancel stock/ledger reversal, collection, customer ledger, and buyer ledger RPCs.

Final validation evidence:
- `bash supabase/tests/run_migrations_and_tests.sh`: pass.
- `flutter test test/hybrid test/app/app_mode_test.dart`: pass, 17 tests.
- `flutter test test`: pass, 485 tests.
- `python3 tools/test_catalog_parity.py`: pass, 30 buyers and 1528 products.
- `flutter analyze`: no errors; existing 44 warnings/info remain.
- `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`: pass, `build/app/outputs/flutter-apk/app-release.apk` 68.7 MB.

Remaining evidence required before production merge/release:
- Manual Supabase login/seed/two-device scenario remains unverified.
- Confirm invoice on one device, sync second device, cancel invoice, sync back, and verify invoice/stock/customer-ledger rows match Supabase.

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

Run the manual Supabase login/initial-sync/two-device checklist using the built release APK. Do not merge as production release until that checklist passes or the merge owner explicitly accepts the manual-validation gap.
