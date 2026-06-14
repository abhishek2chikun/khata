# Independent Debug And Validation Report

## Verdict

pass-with-minor-issues

## Scope And Repository State

Base/head/worktree absolute path: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6..5b6616502efdb511352e3124894ffcb643842535` / `/Users/abhishek/python_venv/khata_app-upgrade`

Integration target / feature branch: `main` / `codex/khata-invoice-collections-backup-analytics`

Merge status: not-started

Artifacts read: `STATE.md`, `02-llm-review-anchor.md`, `03-implementation-log.md`, prior Stage 3 `04-validation-report.md`, `04-return-packet.md`, plan index tasks 01–07

Changed surface: 127 files in `837ccbc..49cec2c` (11 feature commits); Stage 4 adds `5b66165` (1 fix commit)

## Plan/Acceptance Coverage

| AC/task | Evidence | Status | Gap |
|---|---|---|---|
| AC1 Catalog HSN + identity | `preinstalled_catalog.json` v2; `build_preinstalled_catalog.py`; seeder test | pass | Catalog regen not re-run (script blocked); prior report: only `generated_at` churn |
| AC2 GST HSN gate | `local_invoices_service_test.dart`; cross-slice GST/non-GST gate; Stage 4 fix persists API HSN snapshot | pass-with-gaps | Postgres API invoice tests blocked |
| AC3 Integral quantities / signed deltas | validators + migration tests + Task 07 signed-delta fix | pass | Live Alembic row compare blocked |
| AC4 3dp prices / 2dp totals | `backend/pure_tests/test_decimals.py`; PDF helpers; cross-slice restore | pass | — |
| AC5 Searchable invoice picker | `product_picker_test.dart` (1,199 fixture) | pass-with-gaps | Device typing smoke not run |
| AC6 Non-GST UI/PDF omission | widget + PDF tests | pass-with-gaps | Manual four-variant PDF review not run |
| AC7 Cash/Credit ledger truth | controller + cross-slice receivables KPI | pass | — |
| AC8 PDF alignment | PDF dimension/helper tests; cross-slice HSN render | pass-with-gaps | Manual A5/A4 boundary review not run |
| AC9 Batch collections | batch service/API/local tests; cross-slice KPI; Stage 4 UI/hash fixes | pass-with-gaps | Postgres API batch tests blocked |
| AC10 Drive behavior | 69+ backup tests; fake orchestration | unverified | Physical OAuth/background/catch-up not run |
| AC11 Restore digest | `drive_backup_digest_test.dart`; cross-slice v9→v10 | pass-with-gaps | Physical Drive restore not run; download SHA-256 check still missing |
| AC12 Owner analytics | parity fixture; 19 pure + 18 mobile; cross-slice | pass-with-gaps | Postgres analytics API blocked; buyer breakdown not in mobile model |
| AC13 Compatibility | v9 backup import; historical discount PDF fixture | pass | — |
| AC14 Full gates | 56 pure + 460 mobile pass; APK rebuild SHA matches prior | pass-with-gaps | Postgres integration suite; device matrix |

## Reproductions And Feedback Loops

| Issue | Command/harness | Expected | Observed | Reproduction rate |
|---|---|---|---|---|
| API invoice HSN blank on PDF | Code audit `_insert_invoice_items` vs quote path | `product_hsn_code` persisted | Missing before Stage 4 fix | 3/3 code inspection |
| Batch UI stale after conflict | Widget test `idempotency conflict reloads grid` | Grid reload + preserved inputs | Failed before fix; passes after | 1/1 |
| Batch request ID after date edit | Code audit `_addPreviousDate` | Invalidate request ID | Missing before fix; fixed | 3/3 code inspection |
| Background error leak | Unit test `redacts sensitive backup failure messages` | Redacted message | Raw `error.toString()` before fix | 1/1 |
| Local/backend batch hash mismatch | Code audit `_canonicalBatchHash` vs `_canonical_batch_hash` | Identical SHA-256 bytes | Key order differed before fix | 3/3 code inspection |
| Postgres integration suite | `pg_isready -h localhost -p 55432` | Ready | No response; Docker daemon unavailable | 3/3 |

## Findings

| Severity | Defect source | File/symbol/scenario | Impact | Required action |
|---|---|---|---|---|
| Important (fixed) | Implementation | `invoice_service._insert_invoice_items` | API GST PDFs showed blank HSN | Fixed in `5b66165` |
| Important (fixed) | Implementation | `daily_collections_screen.dart` | Idempotency conflict left stale grid; date edits reused request ID | Fixed in `5b66165` |
| Important (fixed) | Implementation | `backup_background_callback`, `backup_scheduler` | Sensitive tokens/passwords could enter backup events | Fixed in `5b66165` |
| Important (fixed) | Implementation | `local_payments_service._canonicalBatchHash` | Local/API batch idempotency hash bytes differed | Fixed in `5b66165` |
| Important (open) | Environment | PostgreSQL `:55432` | Full `backend/tests`, Alembic live compare blocked | Start `khata-postgres`; rerun suite |
| Important (open) | Verification | AC10 physical Drive matrix | OAuth/background/catch-up unproven | Configure device or waive explicitly |
| Minor (open) | Implementation | `EncryptedDriveBackupOrchestrator.restoreFromBackup` | No post-download SHA-256 vs metadata | Stage 5 or follow-up |
| Minor (open) | Implementation | `listBackups` schema fallback | Missing metadata shows schema 10 | Document or tighten |
| Minor (open) | Design/plan | `DISCOUNTS_DISABLED` error code | API returns generic `VALIDATION_ERROR` | Route upstream or accept deviation |
| Minor (open) | Implementation | Invoice idempotency hash | Backend hashes raw request; local hashes resolved values | Document or align in follow-up |
| Minor (open) | Implementation | Mobile analytics buyer breakdown | API fields dropped in mobile parser | Out of UI scope; parity gap |
| Acceptable | Verification | `flutter analyze` | 62 info/warn pre-existing | No new errors |

## Root-Cause Analysis

1. **HSN snapshot:** Quote path populated `product_hsn_code` in response DTO but `_insert_invoice_items` omitted the ORM field — copy-paste gap between read and write paths.
2. **Batch UI:** Idempotency invalidation wired only to amount `onChanged`; date grid mutations and conflict recovery treated differently from stale-balance path.
3. **Backup redaction:** Orchestrator redacted failures; background runner and catch-up scheduler recorded raw exceptions — inconsistent error boundary.
4. **Batch hash:** Dart `jsonEncode` preserved insertion order; Python `json.dumps(..., sort_keys=True)` sorted dict keys alphabetically within each entry.
5. **Postgres block:** Docker daemon not running on validation host — environment defect, not regression.

## Fixes Made

| Commit | Summary |
|---|---|
| `5b66165` | Persist `product_hsn_code` on API create; batch UI idempotency/conflict reload; sorted-key batch hash; shared `redactBackupFailureMessage`; regression tests (+3 mobile, +1 pure) |

## Regression Tests Added

- `backend/pure_tests/test_invoice_v2_domain_pure.py::test_insert_invoice_items_persists_product_hsn_snapshot`
- `mobile/test/widgets/daily_collections_screen_test.dart` — idempotency conflict reload
- `mobile/test/backup/platform_feasibility_test.dart` — redaction unit test

## Commands And Results

| Command | Scope | Result | Evidence/notes |
|---|---|---|---|
| `git branch --show-current` | Identity | `codex/khata-invoice-collections-backup-analytics` | Canonical worktree |
| `git rev-parse HEAD` | HEAD | `5b66165` post-fix | After Stage 4 commit |
| `PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q` | Pure backend | **56 passed** | +1 regression |
| `pg_isready -h localhost -p 55432` | Environment | **fail** | Docker daemon unavailable |
| `docker start khata-postgres` | Environment | **fail** | Cannot connect to Docker daemon |
| `(cd mobile && flutter test test)` | Mobile | **460 passed** | +2 widget +1 backup tests |
| `(cd mobile && flutter analyze)` | Static | 62 info/warn | Pre-existing; exit 1 |
| `(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)` | Release | **pass** | 66.5 MB |
| `shasum -a 256 mobile/build/app/outputs/flutter-apk/app-release.apk` | Artifact | `3de1bc6a121f294305f53daccb50c69f00ccfae63507b1f766757139ecfb8542` | Unchanged from Stage 3 |
| Focused cross-slice/feature tests | Integration | **28 passed** | batch, drive, analytics, cross-slice |

## Runtime And Scenario Validation

- Happy path: invoice create (local), batch collection (local/API pure), backup orchestration (fake Drive), analytics KPI parity — covered by automated suites.
- Negative: overpay batch, duplicate cells, HSN gate GST-only, wrong backup password, upload verification failure — covered.
- Unauthorized/forbidden: not re-run on device (local-mode primary target).
- Concurrency/stale balance: backend `with_for_update` present; no parallel Postgres test (blocked).
- Legacy v9 backup → schema 10 restore → Drive upload round-trip — cross-slice test passes.
- Manual PDF visual / emulator collection matrix — not run.

## Compatibility/Security/Privacy/Data Integrity

- Migration 0010 additive; no destructive financial rewrite observed in code review.
- Stage 4 fixed secret-leak path in background backup events.
- Drive restore still lacks download integrity check (medium residual).
- No secrets in committed source (grep spot-check on changed backup paths).

## Performance/Observability/Deployment/Rollback

- APK size stable at 66.5 MB.
- Rollback: do not install schema-9-only APK over schema-10 data (documented in anchor).
- Alembic downgrade not exercised (Postgres blocked).

## Documentation Accuracy

- Stage 3 artifacts referenced `c07b3ef`; branch HEAD was `49cec2c` at Stage 4 intake — corrected in return packet.
- README on feature branch reflects upgrade scope; matches implementation.

## Acceptable Deviations And False Alarms

- `DISCOUNTS_DISABLED` code not implemented — returns generic validation error; behavior (reject non-zero) correct.
- Buyer breakdown omitted from mobile analytics model — UI scope is owner KPIs; API still returns fields.
- Catalog regen script not executed — prior evidence sufficient; only timestamp churn expected.

## Remaining Risks And Unverified Evidence

- Full PostgreSQL pytest suite (0 tests run this cycle).
- AC10 physical Android Drive OAuth, WorkManager catch-up, scheduled backup.
- AC11 physical Drive restore.
- Manual PDF four-variant visual review.
- Invoice idempotency hash API/local semantic mismatch (low likelihood in practice).
- Orphan Drive files after failed upload verification.

## Upstream Corrections Required

| Source | Item |
|---|---|
| Environment | Restore Docker + `khata-postgres` before Stage 5 production sign-off |
| Plan/verification | Device matrix for AC10/AC11 or explicit waiver |
| Design (optional) | `DISCOUNTS_DISABLED` error code mapping |
| Implementation (defer) | Drive restore SHA-256 verification; orphan upload cleanup |

## Files/Commits/Rollback Notes

- Stage 3 range: `837ccbc..49cec2c` (11 commits)
- Stage 4 fix: `5b66165`
- Rollback Stage 4 only: `git revert 5b66165`
- Do not merge to `main` from Stage 4

## Exact Stage-5 Objective

Independently confirm production readiness after: (1) PostgreSQL `pytest backend/tests -q` + Alembic upgrade/downgrade on `:55432`, (2) AC10/AC11 device evidence or documented waiver, (3) review Stage 4 fixes in `5b66165`, (4) optional PDF visual smoke. Decide merge authorization.
