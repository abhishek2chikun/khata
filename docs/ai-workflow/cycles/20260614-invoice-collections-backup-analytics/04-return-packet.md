# Stage 4 Return Packet For The Original LLM

## Resume Instructions

Return to the same LLM conversation used for Stage 2. If compacted, read:

1. `STATE.md`
2. `02-llm-review-anchor.md`
3. This return packet
4. The actual diff/commits listed below

Do not restart broad repository discovery unless a contradiction below requires it. Do not merge to `main` until Stage 5 authorization.

## Identity And Final State

Workflow objective: HSN/precision contracts, searchable invoice entry, Cash/Credit UX, atomic batch collections, encrypted Drive backup/restore, owner analytics — preserving local/API parity and historical data.

Repository/branch/worktree: `khata_app-upgrade` / `codex/khata-invoice-collections-backup-analytics` / `/Users/abhishek/python_venv/khata_app-upgrade`

Worktree name/ID: `khata_app-upgrade`

Canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app-upgrade`

Integration target branch: `main` (SHA `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6` — merge-base equals baseline)

Feature branch: `codex/khata-invoice-collections-backup-analytics`

Merge owner/authorization: Stage 5 persistent LLM / required

Merge status: not-started

Planning baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Stage 3 starting/ending SHA: `837ccbc..49cec2c630fed1add8db110c9001fab4f060e9f9`

Stage 4 starting/final SHA: `49cec2c..2399faecff7f594378a6d41dd2d41264de2bd5f0` (code fixes: `5b66165`)

Dirty/uncommitted state: clean for tracked cycle files; untracked `.venv`, top-level `docs/ai-workflow/INDEX.md`, `PROJECT_CONTEXT.md` (outside cycle folder)

Target release/environment: Local-mode Android APK (`DATA_MODE=local`); API mode requires Postgres on `:55432`

## Integration Preflight

Target branch current SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Merge base and divergence: merge-base = baseline; feature branch 12 commits ahead; 127 files changed vs `main`

Conflict check/result: `git merge-tree` shows content merges on `README.md` and docs — no textual conflict markers observed; standard doc merge review recommended

Feature worktree clean state: clean after `5b66165`

Required post-merge commands: Alembic upgrade on `internal_billing`; `pytest backend/tests -q`; mobile regression; verify catalog v2 ships in APK

Merge blockers or authorization gaps: Postgres integration unproven; AC10/AC11 device evidence missing; Stage 5 authorization not recorded

## Executive Delta

- Tasks 01–07 delivered HSN/precision contracts (Drift/Alembic v10), searchable invoice picker, Cash/Credit UX, four PDF variants, seven-day atomic batch collections, encrypted Drive orchestration + WorkManager scheduling, and owner analytics dashboard.
- Stage 3 recorded 458 mobile + 55 pure tests; Stage 4 independently confirmed **460 mobile + 56 pure** after fixes.
- Stage 4 found and fixed four in-scope implementation defects: API HSN snapshot omission, batch UI idempotency/conflict handling, local/backend batch hash key ordering, background backup error redaction.
- PostgreSQL on `:55432` remains down (Docker daemon unavailable) — full `backend/tests` still blocked.
- AC10 physical Drive OAuth/background matrix still unverified; AC11 digest proven via fake Drive only.
- Release APK rebuild succeeds; SHA-256 unchanged from Stage 3 handoff.
- Verdict: **pass-with-minor-issues** — ready for Stage 5 senior review after Postgres suite and device gaps addressed or waived.

## Commit Ledger

| Commit | Stage/task | Intent | Key files/contracts | Validation at commit |
|---|---|---|---|---|
| `a66aae4` | 01 | Drive/background dependency proof | `pubspec.yaml`, feasibility tests | platform tests |
| `d12306c` | 02 | HSN/precision contracts + migration 0010 | `decimals.py`, Alembic, catalog v2 | pure tests |
| `129f7e7` | 03 | Searchable invoices + PDFs | picker, PDF service, draft controller | widget + PDF tests |
| `97b100e` | 04 | Atomic batch collection grid | `customer_service.py`, `local_payments_service.dart`, daily collections UI | batch tests |
| `668a0b7` | 05 | Owner analytics KPIs/trends | analytics services, screen, charts | parity fixture tests |
| `0bcfa3d` | 05 | Encrypted Drive recovery | orchestrator, gateways, WorkManager | 69+ backup tests |
| `efd9a59`, `ecf032c`, `a69f093`, `c07b3ef`, `49cec2c` | 07/docs | Integration fixes + artifact sync | cross-slice tests, signed delta fix | 458 mobile at handoff |
| `5b66165` | 04 | Stage 4 fixes | HSN insert, batch UI/hash, backup redaction | 460 mobile + 56 pure |

## Change Manifest

| Path | Symbol/section | Before -> after | Why | Task/AC | Commit | Risk |
|---|---|---|---|---|---|---|
| `backend/app/services/invoice_service.py` | `_insert_invoice_items` | no HSN snapshot -> `product_hsn_code` persisted | GST PDF compliance | AC2/AC8 | `5b66165` | High |
| `backend/alembic/versions/0010_*` | migration | schema 9 -> 10 HSN + 3dp prices | Contract upgrade | AC1-AC4 | `d12306c` | High |
| `mobile/lib/local/local_database.dart` | Drift v10 | v9 -> v10 | Local parity | AC1-AC4 | `d12306c` | High |
| `mobile/lib/screens/daily_collections_screen.dart` | batch save flow | conflict no reload -> reload; date edit invalidates request ID | Idempotency UX | AC9 | `5b66165` | Medium |
| `mobile/lib/local/local_payments_service.dart` | `_canonicalBatchHash` | insertion-order JSON -> sorted keys | API/local hash parity | AC9 | `5b66165` | Medium |
| `mobile/lib/backup/*` | Drive orchestration | skeleton -> verified upload + retention + scheduler | Encrypted backup | AC10/AC11 | `0bcfa3d` | High |
| `mobile/lib/backup/backup_models.dart` | `redactBackupFailureMessage` | n/a -> shared redaction | Secret safety | AC10 | `5b66165` | Medium |
| `mobile/lib/screens/analytics_screen.dart` | owner dashboard | low-stock UI removed | Owner analytics | AC12 | `668a0b7` | Low |
| `mobile/test/integration/cycle_upgrade_cross_slice_test.dart` | cross-slice | n/a -> 5 regressions | Integration proof | AC14 | `c07b3ef` | Medium |

## Contract And Architecture Delta

- **APIs:** `POST /customers/collection-batch`, extended analytics response (additive KPI/trend fields), invoice line schemas include `product_hsn_code`, products include nullable `hsn_code`.
- **Persistence:** Alembic 0010 + Drift schema 10; backup compatibility version 10.
- **Mobile:** `DailyCollectionsScreen`, Drive backup screen overhaul, analytics charts, searchable `ProductPicker`.
- **Security:** Password in `FlutterSecureStorage`; Drive files tagged `khata_owner`; Stage 4 redacts background failures.
- **Unchanged:** Stable product IDs/item numbers; historical fractional quantities readable; low-stock still in API payloads; single-collection endpoints preserved.

## Plan And Acceptance Coverage

| Task/AC | Implementation evidence | Validation evidence | Status |
|---|---|---|---|
| AC1 | catalog v2 JSON, seeder | seeder + pure tests | pass |
| AC2 | GST gate local + API quote | cross-slice + Stage 4 HSN insert fix | pass-with-gaps |
| AC3 | integral validators, signed delta fix | migration + local tests | pass |
| AC4 | 3dp/2dp helpers | pure + PDF tests | pass |
| AC5 | searchable picker | 1,199 fixture test | pass-with-gaps |
| AC6 | non-GST PDF/UI | widget + PDF tests | pass-with-gaps |
| AC7 | Cash/Credit controller | controller + cross-slice | pass |
| AC8 | PDF layout helpers | PDF tests + cross-slice | pass-with-gaps |
| AC9 | atomic batch service/UI | batch tests + Stage 4 UI/hash fix | pass-with-gaps |
| AC10 | Drive orchestration | fake Drive tests only | unverified |
| AC11 | restore digest | digest + cross-slice | pass-with-gaps |
| AC12 | owner KPIs/trend | parity fixture 19+18 tests | pass-with-gaps |
| AC13 | v9 import | backup tests | pass |
| AC14 | full gates | 460 mobile + 56 pure + APK | pass-with-gaps |

## Deviations And Decisions During Execution

| Planned | Actual | Reason/evidence | Defect source | Approved/safe? |
|---|---|---|---|---|
| `DISCOUNTS_DISABLED` error code | `VALIDATION_ERROR` | Not implemented | Plan/design gap | Safe (behavior correct) |
| Backend idempotency hash resolved values | Raw request nulls | Implementation choice | Implementation | Document for Stage 5 |
| Mobile buyer breakdown parity | Omitted from mobile model | UI scope KPI-only | Acceptable deviation | Yes |
| Physical AC10 proof | Deferred | No configured device | Environment | Blocker for full AC10 |
| Postgres integration proof | Blocked | Docker down | Environment | Blocker for AC14 full |

## Fixes Found By Stage 4

| Finding | Root cause | Fix | Regression evidence | Commit |
|---|---|---|---|---|
| API invoice HSN blank | `_insert_invoice_items` omitted field | Add `product_hsn_code` | pure source assertion test | `5b66165` |
| Batch conflict stale grid | UI only reloaded on `STALE_BALANCE` | Reload on `IDEMPOTENCY_CONFLICT` too | widget test | `5b66165` |
| Date edit reused request ID | No invalidation on date add/remove | Call `_invalidateBatchRequestId()` | code + manual trace | `5b66165` |
| Batch hash API/local mismatch | JSON key order | Sorted-key canonical maps | code parity | `5b66165` |
| Background error leak | Raw `toString()` in catch paths | `redactBackupFailureMessage` | unit test | `5b66165` |

## Commands And Evidence Index

| Command/scenario | Final result | What it proves | Raw log/artifact path |
|---|---|---|---|
| `pytest backend/pure_tests -q` | 56 passed | Contract/pure logic | Stage 4 terminal |
| `flutter test test` | 460 passed | Full mobile regression | Stage 4 terminal |
| `flutter build apk --release --dart-define=DATA_MODE=local` | 66.5 MB APK | Release build | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| `shasum -a 256 app-release.apk` | `3de1bc6a...` | Artifact identity | Stage 4 terminal |
| `pg_isready -h localhost -p 55432` | fail | Postgres blocked | Stage 4 terminal |
| Cross-slice + batch + drive focused tests | 28 passed | Integration seams | Stage 4 terminal |

## Runtime/E2E Evidence

- Automated only this cycle; no physical device or emulator smoke run.
- Fake Drive orchestration: upload verification blocks success on hash mismatch; 30-retention prune; v9→v10 restore round-trip digest match.
- Cross-slice: schema-10 backup → restore → PDF HSN header + analytics revenue; batch collection → receivables KPI drop.

## New Repository Facts Since Planning

- Stage 3 artifact HEAD (`c07b3ef`) lagged branch tip (`49cec2c`) by two doc commits — use `5b66165` as validated HEAD.
- Backend invoice create was missing HSN snapshot despite quote path including it — fixed Stage 4.
- Docker daemon was unavailable on validation host (same as baseline cycle).
- Mobile test count is 460 (not 458) after Stage 4 regressions.

## Recommended Project Context Updates

- Drift/backup schema **10** is production path; do not downgrade APK over v10 data.
- Batch collections entry: Customers → Daily collections.
- Drive backup requires Google sign-in + 8+ char password in secure storage.
- Analytics UI is owner KPI snapshot; low-stock API-only.

## Known Issues, Unverified Claims, And Residual Risk

- **Blocked:** `pytest backend/tests -q` (0 run); Alembic live upgrade/downgrade.
- **Unverified:** AC10 physical OAuth, WorkManager scheduled/catch-up backup on hardware.
- **Unverified:** AC11 physical Drive restore; manual PDF visual matrix.
- **Open minor:** Drive restore lacks download SHA-256 check; orphan files on failed upload verification; invoice idempotency hash semantic gap; mobile omits buyer breakdown fields.

## Defect Attribution

| Source | Count | Examples |
|---|---|---|
| Implementation (fixed) | 4 | HSN insert, batch UI, batch hash, backup redaction |
| Environment | 2 | Postgres down, no physical device |
| Verification | 2 | Postgres API tests not run; AC10 device matrix |
| Plan/design | 2 | `DISCOUNTS_DISABLED` code; buyer breakdown mobile scope |
| Discovery | 0 | — |
| False alarm | 0 | — |

## Stage 5 Review Map

### Read first

1. `5b66165` diff — Stage 4 fixes
2. `backend/app/services/invoice_service.py` — `_insert_invoice_items`, GST gate, idempotency hash
3. `backend/app/services/customer_service.py` — `create_collection_batch`, locks, idempotency
4. `mobile/lib/backup/encrypted_drive_backup_orchestrator.dart` — upload verify, retention, restore
5. `mobile/lib/screens/daily_collections_screen.dart` — batch UX/idempotency
6. `backend/alembic/versions/0010_product_hsn_and_unit_price_precision.py` — migration safety

### Read on demand

- PDF: `mobile/lib/services/invoice_pdf_service.dart`
- Analytics parity: `backend/tests/fixtures/analytics_owner_parity.py`, `local_analytics_service_test.dart`
- Cross-slice: `mobile/test/integration/cycle_upgrade_cross_slice_test.dart`
- Plan tasks: `02-plan/00-plan-index.md`

### Commands to rerun

```bash
cd /Users/abhishek/python_venv/khata_app-upgrade
git checkout codex/khata-invoice-collections-backup-analytics
git rev-parse HEAD   # expect 5b6616502efdb511352e3124894ffcb643842535
docker start khata-postgres
pg_isready -h localhost -p 55432
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' \
  PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
(cd mobile && flutter test test)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
```

### Review hypotheses

- Backend invoice test fixtures may still lack `hsn_code` on GST products — will fail once Postgres runs.
- Batch hash fix may invalidate in-flight local idempotency markers (only affects retries mid-upgrade).
- Tests pass while API PDF HSN was broken pre-Stage-4 — Postgres persistence test still needed.
- Drive success paths tested with fakes; real OAuth token refresh untested.

### Do not waste context on

- Unchanged baseline screens unrelated to cycle scope.
- Pre-existing `flutter analyze` info/warn noise.
- Raw 94KB test logs.

## Recommended Stage 5 Verdict Question

**Is this branch authorized to merge to `main` for local-mode Android release after PostgreSQL integration tests pass and AC10/AC11 are either proven on hardware or explicitly waived by the product owner?**

Evidence still needed: `pytest backend/tests -q` green on `:55432`; Alembic 0010 upgrade proof; device Drive matrix or waiver document.
