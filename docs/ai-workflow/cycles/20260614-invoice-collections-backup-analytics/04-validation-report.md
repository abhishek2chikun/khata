# Stage 3 Integration Validation Report

## Verdict

pass-with-minor-issues

## Scope And Repository State

- Planning baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
- Feature branch: `codex/khata-invoice-collections-backup-analytics`
- Worktree: `/Users/abhishek/python_venv/khata_app-upgrade`
- Stage 3 range: `837ccbc..HEAD` (Tasks 01–07)
- Integration target: `main` (unmerged)

## Plan/Acceptance Coverage

| AC | Evidence | Status | Gap |
|---|---|---|---|
| AC1 Catalog HSN + stable identity | `tools/build_preinstalled_catalog.py`; catalog v2 JSON with `hsn_code`; `local_product_catalog_seeder_test.dart` | pass | Catalog regen only changes `generated_at` timestamp |
| AC2 GST HSN gate / non-GST accept | `local_invoices_service_test.dart`; cross-slice `catalog product missing hsn blocked only in gst mode` | pass | Postgres API parity tests not run |
| AC3 Integral new quantities / history | validators in `decimal_validators.dart` / `decimals.py`; migration tests; Task 07 fix for signed stock deltas | pass | Live Alembic row-value compare blocked (no Postgres) |
| AC4 Three-decimal prices / two-decimal totals | `backend/pure_tests`; PDF helper tests; cross-slice three-decimal restore | pass | — |
| AC5 Searchable invoice picker | `product_picker_test.dart` (1,199 fixture) | pass-with-gaps | Device typing/selection not run |
| AC6 Non-GST UI/PDF omission | widget + `invoice_pdf_service_test.dart` | pass-with-gaps | Manual four-variant PDF visual review not run |
| AC7 Cash/Credit ledger truth | `invoice_draft_controller_test.dart`; cross-slice cash/credit KPI test | pass | — |
| AC8 PDF alignment | PDF helper/dimension tests; cross-slice HSN PDF render | pass-with-gaps | Manual A5/A4 boundary review not run |
| AC9 Batch collections | batch service/API tests; cross-slice receivables KPI | pass-with-gaps | Postgres API batch tests not run |
| AC10 Drive behavior | fake Drive orchestration (69 backup tests); schema-10 upload metadata | unverified | Physical OAuth/sign-in/background/catch-up requires configured device |
| AC11 Restore digest | `drive_backup_digest_test.dart`; cross-slice v9→v10 Drive round-trip | pass-with-gaps | Physical Drive restore not run |
| AC12 Owner analytics | parity fixture (19 pure + 18 mobile); cross-slice backup→analytics | pass-with-gaps | Postgres analytics API tests not run |
| AC13 Compatibility | v9 backup import; historical discount PDF fixture | pass | — |
| AC14 Full gates | This report; 55 pure + 458 mobile pass; APK SHA recorded | pass-with-gaps | Postgres integration suite; device matrix |

## Integration Fixes (Task 07)

1. **Signed integral stock deltas** — `validateNonZeroIntegralQuantity` / `validate_non_zero_integral_quantity` now accept negative whole-number deltas; `LocalProductsService` uses `_normalizeSignedIntegralQuantity` for movements.
2. **Stale test fixtures** — Updated product/invoice tests for integral quantities, default HSN on GST products, Cash settlement mode, and API `payment_mode` serialization.
3. **Cross-slice regressions** — Added `mobile/test/integration/cycle_upgrade_cross_slice_test.dart` (5 tests).

## Commands And Results

| Command | Result | Notes |
|---|---|---|
| `git status --short` | Clean at `c6139e5` | Untracked `.venv`, `02-plan/`, and top-level workflow refresh docs |
| `git diff --check` | pass | No conflict markers |
| `python3 tools/build_preinstalled_catalog.py` | pass | Only `generated_at` churn in catalog JSON |
| `PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q` | **55 passed** | |
| `pg_isready -h localhost -p 55432` | **fail** | Docker daemon unavailable |
| Alembic upgrade/downgrade/compare | **blocked** | No Postgres |
| `pytest backend/tests -q` | **blocked** | No Postgres |
| `dart run build_runner build` | pass | No drift source churn after regen |
| `flutter test test` | **458 passed** | Includes 5 new cross-slice tests |
| `flutter analyze` | 62 info/warning issues | Pre-existing; no new errors |
| `flutter build apk --release --dart-define=DATA_MODE=local` | pass | 66.5 MB (63M on disk) |
| `shasum -a 256 app-release.apk` | `3de1bc6a121f294305f53daccb50c69f00ccfae63507b1f766757139ecfb8542` | Local-mode release; debug signing (re-verified 2026-06-14) |

## Blockers

| Severity | Item | Action |
|---|---|---|
| Important | PostgreSQL `localhost:55432` down | Start `khata-postgres` container; run Alembic upgrade/downgrade + `pytest backend/tests -q` |
| Important | AC10 physical Drive matrix | Configure Google OAuth client + test account on Android hardware |
| Minor | Manual PDF/emulator collection matrix | Stage 4 optional runtime smoke |
| Minor | Example app ID / release signing | Out of cycle scope |

## First Stage 4 Command

```bash
cd /Users/abhishek/python_venv/khata_app-upgrade
pg_isready -h localhost -p 55432
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
(cd mobile && flutter test test)
```
