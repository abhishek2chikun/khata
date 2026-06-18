# Stage 4 Return Packet For The Original LLM

## Resume Instructions
Return to the same LLM conversation used for Stage 2. If compacted, read:
1. `docs/ai-workflow/cycles/20260618-hybrid-supabase/STATE.md` (worktree copy)
2. `02-llm-review-anchor.md`
3. This return packet
4. Diff `1fe37ee..<stage4-final-head>` on `codex/hybrid-supabase`
Do not restart broad repository discovery unless a contradiction below requires it.

## Identity And Final State
Workflow objective: single hybrid runtime — Supabase Postgres master, Drift cache, RPC-only official writes, backup/local modes removed after parity.

Repository/branch/worktree: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase` / `codex/hybrid-supabase`

Worktree name/ID: `hybrid-supabase`

Canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase`

Integration target branch: `main` @ `1fe37eee8fa8bc689f1c40fa630853fa8f3daf5a`

Feature branch: `codex/hybrid-supabase`

Merge owner/authorization: Stage 5 persistent LLM / required

Merge status: not-started

Planning baseline SHA: `c7fff58` (Stage 2 planning commit on main)

Stage 3 starting/ending SHA: `1fe37ee` → `ec9afd9`

Stage 4 starting/final SHA: `ec9afd9` → `420d7ae`

Dirty/uncommitted state: clean after Stage 4 commit (catalog JSON noise reverted)

Target release/environment: Supabase project `ekwkklcfovwarcvvxtiq` (from user `.env`, not in repo)

## Integration Preflight
Target branch current SHA: `1fe37ee` on planning checkout `main`

Merge base and divergence: `1fe37ee` (main and feature branch share baseline; 5 Stage 3 commits + Stage 4 fix ahead)

Conflict check/result: not run; expect conflicts in `mobile/lib/app/*`, `mobile/pubspec.*`, new `supabase/`, `tools/`, `data/source/`

Feature worktree clean state: clean post-Stage 4 commit

Required post-merge commands:
- `bash supabase/tests/run_migrations_and_tests.sh`
- `python3 tools/test_catalog_parity.py`
- `cd mobile && flutter test test`
- hybrid APK build with Supabase dart-defines
- manual login/sync on device

Merge blockers or authorization gaps: AC9 incomplete (local master-data writes), Task 05 incomplete, weak SQL/hybrid integration proof, APK/manual sync unverified

## Executive Delta
- Supabase schema, RLS, catalog/invoice RPCs land under `supabase/migrations/` and pass remote migration script.
- Master catalog canonicalized at `data/source/MASTER CATALOG.xlsx` with deterministic Drift + Supabase JSON seeds (1528 products, 30 buyers).
- Flutter hybrid mode is default (`DataMode.hybrid`); Supabase auth + invoice create/cancel RPC path implemented.
- Drift schema 11 adds `hybrid_cache_settings`; sync service upserts core tables.
- **Stage 4 fixed** missing sync lifecycle wiring (login/resume/bootstrap).
- **Still blocking**: product/customer/buyer/payment/company writes remain local Drift; Task 05 cleanup deferred; hybrid tests thin; manual multi-device proof absent.
- Verdict: **fix-required** — return incomplete work to Stage 3 or continue implementation before Stage 5 merge review.

## Commit Ledger
| Commit | Stage/task | Intent | Key files/contracts | Validation at commit |
|---|---|---|---|---|
| `b7c3a9f` | Task 01 | worktree + untrack `.env` | `.gitignore` | manual |
| `11255ca` | Task 02 | DB authority | `supabase/migrations/*`, `supabase/tests/*` | SQL script |
| `3bbe89f` | Task 03 | catalog seeds | `tools/build_preinstalled_catalog.py`, seeds | parity test |
| `498ef81` | Task 04 partial | hybrid auth/invoice/sync code | `mobile/lib/hybrid/*`, `app_dependencies.dart` | flutter test (local mode) |
| `ec9afd9` | Task 06 draft | Stage 3 handoff docs | workflow artifacts | claimed, not independently verified |
| `420d7ae` | Stage 4 | sync lifecycle + cache tests | `main.dart`, `app_dependencies.dart`, `hybrid_sync_service_test.dart` | 481 flutter tests |

## Change Manifest
| Path | Symbol/section | Before -> after | Why | Task/AC | Commit | Risk |
|---|---|---|---|---|---|---|
| `supabase/migrations/20260618120000_hybrid_schema.sql` | tables, `invoice_number_seq` | new | Postgres authority | AC4, AC12 | `11255ca` | high |
| `supabase/migrations/20260618120300_hybrid_rpc_invoice.sql` | `create_invoice`, `cancel_invoice` | new | RPC writes | AC11–14 | `11255ca` | high |
| `mobile/lib/hybrid/hybrid_invoices_service.dart` | `createInvoice` | local-only -> RPC + cache refresh | invoice authority | AC11 | `498ef81` | high |
| `mobile/lib/app/app_dependencies.dart` | hybrid branch | n/a -> hybrid deps | runtime wiring | AC6–7 | `498ef81`/`stage4` | high |
| `mobile/lib/app/app_dependencies.dart` | `productsService` in hybrid | should be Hybrid -> still `LocalProductsService` | incomplete Task 04 | AC9 | `498ef81` | **critical gap** |
| `mobile/lib/main.dart` | `_BillingAppState` | no sync hooks -> lifecycle sync | Stage 4 fix | AC7–8 | `stage4` | medium |
| `data/source/MASTER CATALOG.xlsx` | canonical source | untracked -> tracked | AC2 | `3bbe89f` | low |

## Contract And Architecture Delta
- APIs/schemas: new Supabase tables mirror Drift business schema; RPC functions for catalog seed, products, customers, company profile, invoices, collections, stock adjust.
- Persistence: Drift v11 `hybridCacheSettings`; normal sync uses `insertOnConflictUpdate` per row.
- Config: `SUPABASE_URL`, `SUPABASE_ANON_KEY` dart-defines required for hybrid; `.env` holds `DATABASE_URL` for migration script only.
- Security: RLS enabled; `require_authenticated()` in RPCs; no service role in Flutter.
- Runtime: default hybrid; `DATA_MODE=api|local` still parseable for tests — **not final per AC17**.
- Unchanged: invoice preview quote logic (local compute), PDF/share services, analytics read path (local Drift).

## Plan And Acceptance Coverage
| Task/AC | Implementation evidence | Validation evidence | Status |
|---|---|---|---|
| Task 02 schema/RPC | migrations + functions present | `run_migrations_and_tests.sh` pass | pass |
| Task 03 catalog | generator + parity test | `test_catalog_parity.py` pass | pass |
| Task 04 hybrid services | invoice RPC only | code audit + unit tests | **fail partial** |
| Task 04 sync lifecycle | `HybridSyncService` + Stage 4 wiring | cache unit tests; no e2e | partial |
| Task 05 cleanup | backup UI gated | drawer flag only | **fail** |
| AC9 RPC all writes | SQL RPCs exist; mobile not wired | code audit | **fail** |
| AC17 backup unreachable | hidden in hybrid default | no static proof of route removal | partial |
| AC18 handoff | this packet | Stage 4 independent run | partial |

## Deviations And Decisions During Execution
| Planned | Actual | Reason/evidence | Defect source | Approved/safe? |
|---|---|---|---|---|
| Full Task 04 hybrid services | Invoice path only | Stage 3 time/slice stop | implementation | **no** |
| Task 05 delete old runtime | deferred | parity not proven | implementation/plan | yes temporarily |
| Baseline `c7fff58` | started `1fe37ee` | user backup commit on main | discovery | acceptable with log |
| Stage 3 wrote Stage 4 artifacts | draft only | workflow confusion | verification | superseded |

## Fixes Found By Stage 4
| Finding | Root cause | Fix | Regression evidence | Commit |
|---|---|---|---|---|
| Sync never on login/resume | `HybridSyncService` not exposed/triggered | expose on `AppDependencies`; hooks in `main.dart` | 3 new tests + 481 suite pass | `<stage4>` |

## Commands And Evidence Index
| Command/scenario | Final result | What it proves | Raw log/artifact path |
|---|---|---|---|
| `python3 tools/test_catalog_parity.py` | pass | AC3 seed parity | terminal Stage 4 session |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass | schema + smoke SQL | terminal Stage 4 session |
| `flutter test test --dart-define=DATA_MODE=local` | 481 pass | no regressions | terminal Stage 4 session |
| `flutter analyze` | 0 errors | static hygiene | terminal Stage 4 session |
| `rg service_role mobile/` | no hits | no service role leak | grep |

## Runtime/E2E Evidence
None captured in Stage 4. Required before merge: Supabase Auth login, `initializeHybridCacheIfNeeded`, confirm invoice on device A, sync on device B, offline confirm blocked.

## New Repository Facts Since Planning
- Implementation baseline was `1fe37ee` ("backup before hybrid"), not bare `c7fff58`.
- Stage 3 prematurely authored draft `04-*` files; independent Stage 4 superseded them.
- Planning checkout `main` `STATE.md` lags worktree state (still Stage 2).
- Remote `main_backup` remains at `f873c38`, not `1fe37ee`.

## Recommended Project Context Updates
- Hybrid cycle is implemented on `codex/hybrid-supabase` worktree only; `main` at `1fe37ee` has catalog xlsx + `.env` changes not on feature branch.
- Blocking gap: hybrid mode still writes master catalog data locally.

## Known Issues, Unverified Claims, And Residual Risk
- APK build not finished in Stage 4 window.
- `seed_master_catalog` not run against remote for full catalog.
- SQL tests do not prove idempotency or concurrent invoice numbering.
- Stage 3 log claim "478 tests" upgraded to 481 after Stage 4 tests.
- Collections/ledger tables not synced into Drift.

## Defect Attribution
- Implementation: 5 (AC9 local writes, incomplete sync tables, missing hybrid services, Task 05 incomplete, sync wiring — last fixed)
- Verification: 2 (thin SQL/hybrid tests, premature Stage 3 pass artifacts)
- Plan: 0 blocking
- Design: 0
- Discovery: 1 (baseline SHA drift)
- Environment: 1 (APK build time/unverified)

## Stage 5 Review Map
### Read first
1. `mobile/lib/app/app_dependencies.dart` — hybrid service wiring (AC9 gap)
2. `mobile/lib/hybrid/hybrid_invoices_service.dart` — invoice RPC contract
3. `supabase/migrations/20260618120300_hybrid_rpc_invoice.sql` — authority rules
4. `mobile/lib/main.dart` — sync lifecycle (post Stage 4)
5. `supabase/tests/sql_smoke_tests.sql` — test strength gap

### Read on demand
- `tools/build_preinstalled_catalog.py`, `hybrid_sync_service.dart`, task packets 04–05

### Commands to rerun
```bash
cd /Users/abhishek/python_venv/khata_app/.worktrees/hybrid-supabase
python3 tools/test_catalog_parity.py
bash supabase/tests/run_migrations_and_tests.sh
cd mobile && flutter test test --dart-define=DATA_MODE=local
cd mobile && flutter analyze
```

### Review hypotheses
- Invoice RPC succeeds while catalog rows exist only on device (local product create) -> server reject or silent inconsistency.
- Tests pass under `DATA_MODE=local`, masking hybrid wiring gaps.
- Full-table sync may be slow/flaky on device but untested.

### Do not waste context on
- Unchanged PDF widget internals, api mode tests, Drive backup tests (legacy reference).

## Recommended Stage 5 Verdict Question
Given AC9 is failing (local master-data writes in hybrid mode) and Task 05 is incomplete, should Stage 5 **reject merge** and send work back to Stage 3 for `Hybrid*Service` completion, or accept a narrowed merge scope explicitly excluding multi-writer catalog edits? Default recommendation: **reject merge** until AC9 and Task 05 gates pass with fresh evidence.
