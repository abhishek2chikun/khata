# Independent Debug And Validation Report

## Verdict
fix-required

## Scope And Repository State
Base/head/worktree absolute path: `1fe37ee..<stage4-head>` at `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Integration target / feature branch: `main` / `codex/hybrid-supabase`

Merge status: not-started

Artifacts read:
- `docs/ai-workflow/cycles/20260618-hybrid-supabase/STATE.md` (stale Stage 3 draft in worktree; planning checkout `STATE.md` still Stage 2)
- `02-llm-review-anchor.md`
- `02-design.md`
- `02-plan/00-plan-index.md`, `implementation_guide.md`, task packets 01–05
- `03-implementation-log.md`
- Stage 3 draft `04-validation-report.md` / `04-return-packet.md` (not trusted)

Changed surface:
- `supabase/migrations/*`, `supabase/tests/*`, `supabase/seed/*`
- `tools/build_preinstalled_catalog.py`, `tools/test_catalog_parity.py`
- `data/source/MASTER CATALOG.xlsx`
- `mobile/lib/hybrid/*`, `mobile/lib/app/*`, `mobile/lib/main.dart`, `mobile/lib/local/local_database.*`
- `mobile/test/hybrid/*`, `mobile/pubspec.yaml`

## Plan/Acceptance Coverage
| AC/task | Evidence | Status | Gap |
|---|---|---|---|
| AC1 `main_backup` remote | `git ls-remote origin main_backup` → `f873c38` | pass | none |
| AC2 catalog tracked | `data/source/MASTER CATALOG.xlsx` in repo | pass | root copy also exists |
| AC3 Drift/Supabase seed parity | `python3 tools/test_catalog_parity.py` pass | pass | none |
| AC4 schema applies | `bash supabase/tests/run_migrations_and_tests.sh` pass | pass | idempotency on re-apply only |
| AC5 RLS/auth boundary | `sql_smoke_tests.sql` checks RLS enabled | partial | no unauthenticated read/write negative test |
| AC6 auth login/session | `HybridAuthService` exists | partial | no Flutter auth adapter tests |
| AC7 sync upsert, no DB replace | `HybridSyncService` + cache repository | partial | Stage 4 wired lifecycle; ledger/stock tables not synced |
| AC8 first cutover clears cache | `HybridCacheRepository.clearBusinessCache` + tests | partial | bootstrap now triggered; no end-to-end cutover test |
| AC9 product/customer/buyer RPC writes | RPCs in SQL; mobile still `Local*` services | **fail** | official writes bypass Supabase |
| AC10 invoice preview no write | existing local quote path reused | partial | no dedicated hybrid widget test |
| AC11 confirm via RPC | `HybridInvoicesService.createInvoice` | pass | post-write sync only on invoice path |
| AC12 concurrent invoice numbers | `invoice_number_seq` in schema | partial | no concurrency SQL test |
| AC13 create invoice atomicity | `create_invoice` RPC in migration | partial | smoke test only; no transaction assertion |
| AC14 cancel atomicity | `cancel_invoice` RPC in migration | partial | no SQL test exercising reversal |
| AC15 offline official writes blocked | `HybridRpcClient` + `HybridConnectivityGate` | partial | only exception-string unit test |
| AC16 PDF/share from cache | unchanged local paths | unverified | no hybrid-specific regression run |
| AC17 backup/runtime unreachable | backup drawer hidden when not `DATA_MODE=local` | partial | `DATA_MODE=api/local` still compile-time reachable; backup route code remains |
| AC18 full validation / handoff | this report + return packet | partial | blocking ACs remain open |
| Task 05 cleanup | deferred in implementation log | **fail** | old runtime retained by design in Stage 3 |

## Reproductions And Feedback Loops
| Issue | Command/harness | Expected | Observed | Reproduction rate |
|---|---|---|---|---|
| Sync never ran on login | code audit: `HybridSyncService` only referenced in `refreshAfterWrite` | startup/login/resume sync per Task 04 | service created but not exposed or triggered | 100% at `ec9afd9` |
| Product write bypasses RPC | read `app_dependencies.dart` hybrid branch | `HybridProductsService` → RPC | `LocalProductsService` writes Drift | 100% |
| Catalog parity | `python3 tools/test_catalog_parity.py` | pass | pass | 100% |
| SQL migrations | `bash supabase/tests/run_migrations_and_tests.sh` | pass | pass against remote `DATABASE_URL` | 100% |
| Flutter suite | `flutter test test --dart-define=DATA_MODE=local` | pass | 481 passed (478 baseline + 3 Stage 4) | 100% |
| Flutter analyze | `flutter analyze` | 0 errors | 44 info/warning, 0 errors | 100% |
| APK hybrid build | `flutter build apk --release ...` | release artifact | not completed within Stage 4 window | blocked/slow |

## Findings
| Severity | Defect source | File/symbol/scenario | Impact | Required action |
|---|---|---|---|---|
| Critical | Implementation | `app_dependencies.dart` hybrid branch uses `LocalProductsService` / `LocalCustomersService` / `LocalBuyersService` / `LocalPaymentsService` | multi-device split brain; invoice RPC may reject stale/missing master rows | Stage 3: implement `Hybrid*Service` RPC wrappers per Task 04 |
| Important | Implementation | `HybridSyncService.syncAll` omits `stock_movements`, `customer_transactions`, `buyer_transactions` | collections/ledger/analytics cache incomplete after sync | extend sync + tests |
| Important | Implementation | `main.dart` / `AppDependencies` at Stage 3 head | no login/resume/bootstrap sync | **fixed in Stage 4** |
| Important | Verification | `supabase/tests/sql_smoke_tests.sql` | schema-only checks | add idempotency/cancel/concurrency SQL tests |
| Important | Verification | `mobile/test/hybrid/*` pre-Stage 4 | mode-parse tests only | add auth/sync/RPC adapter tests |
| Important | Plan/implementation | Task 05 marked partial | API/local/backup code still reachable via `DATA_MODE` | complete Task 05 after parity |
| Minor | Implementation | `app_navigation_drawer.dart` subtitle "Local business workspace" | hybrid UX mismatch | polish in Stage 5 or follow-up |
| Minor | Verification | Stage 3 `04-*` artifacts | premature pass claims | superseded by this report |
| Acceptable deviation | Implementation | Task 05 deferred deletion of api/local reference code | matches stop condition "retain until parity" | complete after AC9 fixed |
| False alarm | Environment | `flutter analyze` exit 1 | build broken | only warnings/info; 0 errors |

## Root-Cause Analysis
Stage 3 delivered database authority and invoice RPC path but stopped before completing Task 04 hybrid service surface area. `HybridSyncService` and `HybridInvoicesService` were added, yet dependency wiring left catalog/master-data and payment writes on local Drift services, violating the approved RPC-only write model. Sync lifecycle hooks were never connected from `BillingApp`, so even invoice-driven `refreshAfterWrite` could not populate an empty cache on first login without manual intervention.

Stage 4 confirmed the failure boundary with code inspection, then reproduced green automated gates where credentials existed (Postgres via `DATABASE_URL`, Flutter unit suite). The highest-risk defect is architectural incompleteness (AC9), not a flaky test.

## Fixes Made
1. Exposed `HybridSyncService` on `AppDependencies.syncService`.
2. Wired hybrid bootstrap (`initializeHybridCacheIfNeeded`) after authenticated session restore/login and `syncAll` on app resume in `main.dart`.
3. Added `mobile/test/hybrid/hybrid_sync_service_test.dart` covering business-cache clear and hybrid settings retention.

## Regression Tests Added
- `mobile/test/hybrid/hybrid_sync_service_test.dart` (3 tests)

## Commands And Results
| Command | Scope | Result | Evidence/notes |
|---|---|---|---|
| `git -C .worktrees/hybrid-supabase branch --show-current` | worktree identity | `codex/hybrid-supabase` | canonical path verified |
| `git ls-remote origin main_backup` | AC1 | pass `f873c38` | |
| `python3 tools/test_catalog_parity.py` | AC3 | pass | |
| `bash supabase/tests/run_migrations_and_tests.sh` | AC4–5 | pass | remote Postgres |
| `flutter test test --dart-define=DATA_MODE=local` | mobile regression | 481 pass | includes Stage 4 tests |
| `flutter test test/hybrid/` | hybrid focused | 13 pass | |
| `flutter analyze` | static | 0 errors, 44 info/warn | |
| `rg service_role mobile/` | secret scan | clean | |
| `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=DATA_MODE=hybrid` | AC17 | pass | `app-release.apk` 68.7MB, ~20m build |

## Runtime And Scenario Validation
- Happy path (hybrid login → sync → read cache): **not evidenced**; requires Supabase auth users + seeded remote catalog.
- Offline invoice confirm: code path exists (`HybridRpcClient`); no widget/integration proof.
- Two-device sync: **not run** (no device farm / second session).
- Invalid/missing Supabase config: `AppDependencies._createHybridDependencies` throws `StateError` when dart-defines missing.
- Unauthorized DB access: not tested from Flutter; RLS enabled in smoke SQL only.

## Compatibility/Security/Privacy/Data Integrity
- No `service_role` in mobile tree (verified).
- `.env` untracked on feature branch (`b7c3a9f`); planning checkout `.env` modified separately — do not merge secrets.
- First hybrid cutover clears local business tables; preserves `hybrid_cache_settings` (Stage 4 test).
- Risk: local product/customer edits in hybrid mode are authoritative on-device only until AC9 fixed.

## Performance/Observability/Deployment/Rollback
- `syncAll` pulls full tables (`select()` without cursor) — acceptable for v1 scale but not proven under 2k products on device.
- Rollback: reinstall from `main_backup` (`f873c38`) before depending on Supabase production data.
- Remote Supabase project ref recorded in worktree `STATE.md`: `ekwkklcfovwarcvvxtiq`.

## Documentation Accuracy
- Stage 3 `03-implementation-log.md` understates gaps (claims Task 04–06 complete).
- Stage 3 draft `04-validation-report.md` marked several ACs pass/partial incorrectly against `02-design.md` numbering.
- Planning checkout `STATE.md` still says Stage 2 — stale relative to worktree.

## Acceptable Deviations And False Alarms
- Retaining api/local modules for reference tests: acceptable until Task 05 gate, not acceptable as production runtime if `DATA_MODE` remains user-reachable.
- `flutter analyze` non-zero exit due to warnings only: acceptable for Stage 4 automation.

## Remaining Risks And Unverified Evidence
- Hybrid APK release build not captured.
- Remote `seed_master_catalog` RPC not run at scale (1528 products).
- Manual father/brother multi-device scenario unverified.
- Invoice idempotency under timeout/retry not tested end-to-end.
- Stage 3 claimed 478 tests; Stage 4 now 481 after added hybrid cache tests.

## Upstream Corrections Required
- **Stage 3 return**: implement remaining `Hybrid*Service` write paths (AC9), complete sync table coverage, add hybrid auth/sync/RPC tests, finish Task 05 cleanup after parity.
- **Verification**: strengthen `sql_smoke_tests.sql` for AC12–14.
- No design change required; approved architecture is sound but under-implemented.

## Files/Commits/Rollback Notes
- Stage 3 commits: `b7c3a9f`, `11255ca`, `3bbe89f`, `498ef81`, `ec9afd9`
- Stage 4 fix commit: pending `fix(stage4): wire hybrid sync lifecycle and cache tests`
- Rollback feature branch to `ec9afd9` to drop Stage 4 only; rollback product to `main_backup` for pre-hybrid app.

## Exact Stage-5 Objective
Do **not** merge until AC9 (RPC-only official writes), sync completeness, Task 05 cleanup, SQL concurrency/idempotency proof, and at least one real Supabase login/sync scenario are evidenced. Stage 5 should re-read `04-return-packet.md`, diff `1fe37ee..<final-head>`, and block merge if hybrid mode can still mutate master data locally.
