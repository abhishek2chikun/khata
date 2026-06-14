# Implementation Log

## Workflow Summary

Baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
Current HEAD: `c07b3ef54e78ec6b9587bd7b16c7f0f30c84da2d`
Integration target branch: `main`
Feature branch: `codex/khata-invoice-collections-backup-analytics`
Worktree name/ID: `khata_app-upgrade`
Canonical worktree path: `/Users/abhishek/python_venv/khata_app-upgrade`
Merge status: not-started
Assigned tasks: 01-07 (full plan)

## Task Evidence

| Slice | Status | Implementation evidence | Verification evidence | Deviations/blockers |
|---|---|---|---|---|
| Platform feasibility | complete | Task 01 at `a66aae4` / `d12306c` | dependency lockfile tests | none |
| Contracts/migrations/catalog | complete | Task 02 at `d12306c` | 55 pure tests; Drift v10 | Postgres Alembic compare blocked |
| Invoice creation/PDF | complete | searchable picker, Cash/Credit, PDFs | 71 focused + cross-slice PDF | manual PDF visual review deferred |
| Batch collections | complete | atomic grid API/local/UI | batch tests + cross-slice receivables KPI | Postgres API tests blocked |
| Drive backup | complete | encrypted orchestration + scheduler | 69 backup + digest + cross-slice v9→v10 | AC10/AC11 physical device unverified |
| Analytics | complete | owner KPIs, trend, screen | 19 pure + 18 mobile + cross-slice | Postgres API parity blocked |
| Integration/release | complete | signed delta fix, stale test refresh, cross-slice file | 458 mobile, 55 pure, APK SHA | Postgres + device matrix blocked |

## Acceptance Evidence (AC1–AC14)

| AC | Status | Evidence |
|---|---|---|
| AC1 Catalog HSN + identity | complete | `preinstalled_catalog.json` v2 with `hsn_code`; `build_preinstalled_catalog.py`; seeder test |
| AC2 GST HSN gate | complete | `local_invoices_service_test.dart` MISSING_PRODUCT_HSN; cross-slice GST/non-GST HSN gate |
| AC3 Integral quantities | complete | validators; migration tests; Task 07 signed stock-delta fix in `decimal_validators.dart` / `decimals.py` |
| AC4 Price precision | complete | `backend/pure_tests/test_decimals.py`; PDF 3dp helpers; cross-slice `12.008` restore |
| AC5 Product search | complete | `product_picker_test.dart` 1,199 fixture | device smoke not run |
| AC6 Non-GST omission | complete | create-invoice + PDF widget/helper tests |
| AC7 Cash/Credit truth | complete | `invoice_draft_controller_test.dart`; cross-slice receivables cash vs credit |
| AC8 PDF alignment | complete | `invoice_pdf_service_test.dart` helpers/dimensions | manual 4-variant review not run |
| AC9 Batch collections | complete | batch service/API/local tests; cross-slice receivables KPI drop |
| AC10 Drive behavior | **unverified** | fake Drive orchestration (upload verify, retention, scheduler) | physical OAuth/background not run |
| AC11 Restore digest | pass-with-gaps | `drive_backup_digest_test.dart`; cross-slice Drive v9 migrate→upload→restore | physical Drive restore not run |
| AC12 Owner analytics | complete | parity fixture; 19 pure + 18 mobile; cross-slice backup→analytics revenue |
| AC13 Compatibility | complete | v9 backup import; historical discount PDF fixture |
| AC14 Full gates | pass-with-gaps | 458 mobile + 55 pure + analyze (info/warn only) + release APK SHA-256 | Postgres `backend/tests` blocked |

### Task 07 — Integration and handoff (2026-06-14)

**Integration fixes**
- Fixed negative integral stock adjustment validation (mobile + backend parity).
- Refreshed stale tests for integral quantities, HSN on GST products, Cash settlement mode, API payment_mode serialization.

**Cross-slice regressions** (`mobile/test/integration/cycle_upgrade_cross_slice_test.dart`)
- schema-10 backup with HSN/3dp → restore → PDF headers + analytics revenue
- batch collection → immediate receivables KPI reduction
- Cash vs Credit invoices → receivables KPI divergence
- missing HSN blocked in GST only
- v9 restore → Drive upload schema-10 → restorable digest

**Validation ladder**
```bash
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q          # 55 passed
(cd mobile && flutter test test)                                              # 458 passed
(cd mobile && flutter analyze)                                                # 62 info/warn, no errors
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)     # 66.5 MB APK
shasum -a 256 mobile/build/app/outputs/flutter-apk/app-release.apk
# SHA-256: 3de1bc6a121f294305f53daccb50c69f00ccfae63507b1f766757139ecfb8542
```

**Blocked gates**
- `pg_isready localhost:55432` — Docker daemon unavailable
- Physical Android Drive OAuth matrix (AC10)
- Manual PDF/emulator collection smoke (optional Stage 4)

### Task 03 — Invoice creation and PDFs (2026-06-14)

*(prior entries preserved above Task 07)*

**Search / entry**
- Searchable modal picker; 1,199-product fixture; match name/item/company/HSN.

**Cash / Credit**
- SegmentedButton; controller maps Cash→TOTAL_PAID; Credit unpaid/partial validation.

**PDF policy**
- GST HSN snapshot; non-GST omits GST columns; 3dp unit prices; A5≤15 / A4>15.

**Focused verification:** 71 tests green.

### Task 04 — Atomic daily collection grid (2026-06-14)

**Backend/mobile:** seven-day grid, atomic batch POST, idempotent hash, stale-balance errors.

**Focused verification:** 55 pure + 37 mobile batch tests.

### Task 05 — Encrypted Google Drive backup (2026-06-14)

**Implementation:** orchestrator, secure password, WorkManager + catch-up, 30-retention prune.

**Focused verification:** 69 backup tests; debug + release APK green.

**Device evidence (blocked):** AC10/AC11 require configured OAuth + hardware.

### Task 06 — Owner analytics dashboard (2026-06-14)

**KPI parity fixture (2026-04-01..2026-04-03):** revenue 350, profit 140, receivables 150, payables 500.

**Focused verification:** 19 backend pure + 18 mobile analytics tests.
