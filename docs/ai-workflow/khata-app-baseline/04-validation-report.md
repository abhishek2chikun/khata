# Independent Debug And Validation Report

## Verdict
pass-with-minor-issues

## Scope And Repository State
Base/head/worktree:
- Planning baseline: `7699ae634988fcf577d7ee3e26480a37c475be02`
- Stage 3 implementation range: `7699ae6..3f71e22` (Tasks 01–06)
- Stage 4 start HEAD: `de7318a` (docs handoff)
- Stage 4 validation HEAD: `de7318a` with **uncommitted** Stage 4 fixes in working tree
- Branch: `main`
- Worktree: dirty (2 backend test files modified by Stage 4)

Artifacts read:
- `STATE.md`, `02-llm-review-anchor.md`, `02-plan/00-plan-index.md`, task packets 01–06
- `03-implementation-log.md`
- Independent diff `7699ae6..de7318a` (64 files, +2871/−469)

Changed surface:
- Backend: Alembic `0009`, models/schemas/services, invoice tax semantics, tests
- Mobile: Drift v9, GST UI, PDF/share/balance services, customer screens, 372 tests
- Docs: workflow artifacts, `README.md`, `mobile/agent.md`, `backend/agent.md`

## Plan/Acceptance Coverage
| AC/task | Evidence | Status | Gap |
|---|---|---|---|
| Task 01 contracts/migrations | `0009_invoice_gst_flags.py`, Drift v9 backfill, backup schema 9, migration contract test | pass | Live Alembic upgrade on disposable Postgres not run (DB down) |
| Task 02 tax semantics | `normalize_non_gst_line`, `invoice_service` policy/hash, mobile `local_invoices_service` parity tests | pass (mobile + pure) | Full `test_invoice_service.py` blocked on Postgres |
| Task 03 date-only mobile | `InvoiceDraft.toJson()` omits `invoice_datetime`; local test `date-only draft stores UTC midnight`; profile GST switch tests | pass (mobile) | Backend API date matrix blocked on Postgres; pure test added in Stage 4 |
| Task 04 adaptive PDFs | `invoice_pdf_service.dart` helpers; MediaBox A5/A4 threshold tests (10/11 lines); canceled banner | pass | Manual visual review of four PDF variants not performed |
| Task 05 invoice share | `formatInvoiceShareCaption`, `Share.shareXFiles` + caption; no `wa.me`; widget tests | pass (unit/widget) | Android share-sheet runtime smoke not executed |
| Task 06 balance share | `balance_share_service.dart`, preview modals, customer detail/list widget tests | pass (unit/widget) | Android runtime smoke not executed |
| AC-GST-01/02 | Migrations + mobile/local policy tests + PDF omission helpers | pass-with-gaps | Backend DB integration unverified |
| AC-DATE-01 | Mobile date-only + `resolved_invoice_datetime()` pure test | pass-with-gaps | Postgres API datetime compatibility tests unverified |
| AC-PDF-01/02 | Dimension tests + layout helpers | pass-with-gaps | No committed manual PDF artifacts |
| AC-SHARE-01 | Service/widget proof of attachment+caption path | pass-with-gaps | No device chooser evidence |
| AC-BAL-01/02 | Formatter/widget tests | pass-with-gaps | No device runtime evidence |
| AC-COMPAT-01 | Source-inspected migration + Drift v9 tests | pass | Live Postgres backfill inspection not run |
| AC-REGRESSION-01 | Mobile 372 pass, APK build OK, pure backend 47 pass | pass-with-gaps | Full backend pytest + Android E2E blocked |

## Reproductions And Feedback Loops
| Issue | Command/harness | Expected | Observed | Reproduction rate |
|---|---|---|---|---|
| Backend full suite unavailable | `BILLING_DATABASE_URL=...internal_billing_test pytest backend/tests -q` | Tests run after Alembic upgrade | 156 errors at session setup; `pg_isready localhost:55432` → no response | 3/3 |
| Stale hash pure test | `PYTHONPATH=backend pytest backend/pure_tests -q` | All pass | 1 fail: `_build_invoice_request_hash` arity mismatch after Task 02 `gst_flag` addition | 1/1 |
| Mobile regression | `cd mobile && flutter test test` | All pass | **372 passed** | 2/2 |
| Release build | `flutter build apk --release --dart-define=DATA_MODE=local` | APK produced | `app-release.apk` 59MB | 1/1 |
| Migration contract | `pytest backend/tests/test_invoice_gst_flag_migration_contract.py` | 1 pass | 1 pass | 1/1 |

## Findings
| Severity | Defect source | File/symbol/scenario | Impact | Required action |
|---|---|---|---|---|
| Important | Environment | PostgreSQL `localhost:55432` | Full backend pytest, live Alembic 0009 proof, API date/GST integration tests blocked | Start `khata-postgres` per README; rerun suite before Stage 5 production sign-off |
| Important | Verification | `backend/pure_tests/test_invoice_v2_domain_pure.py::test_total_paid_request_hash_uses_resolved_paid_amount` | False-red on no-DB ladder; hid hash-contract regression risk | **Fixed** — pass `gst_flag` arg |
| Minor | Implementation | `backend/tests/api/test_invoice_create_api.py::_company_payload` duplicate `gst_flag` key | Harmless Python overwrite; sloppy fixture | **Fixed** — removed duplicate |
| Minor | Verification | Plan Task 03 backend date API tests | Only pure/mobile coverage when DB down | Add/rerun API tests when Postgres available |
| Minor | Verification | Manual four-variant PDF visual review | Layout helpers tested; typography not human-reviewed | Optional visual pass in Stage 5 |
| Acceptable deviation | — | Android E2E deferred in Stage 3 log | Widget/service proof exists | Record honest blocker; run on device before release |
| False alarm | — | Implementation log claimed 372 mobile tests | Independently reproduced **372 passed** | None |

## Root-Cause Analysis
### Stale pure hash test
Task 02 changed `_build_invoice_request_hash(..., gst_flag: bool, paid_amount: Decimal | None = None)` but `test_total_paid_request_hash_uses_resolved_paid_amount` still passed `Decimal("236.00")` as the fourth positional argument (previously `paid_amount`). Pytest compared hashes built with different implicit semantics, producing assertion failure. Defect source: **verification** (test not updated with contract change). Production hash code is consistent with `invoice_service` usage.

### PostgreSQL blocker
`pg_isready -h localhost -p 55432` reports no response; `docker start khata-postgres` hung (>3 min, no daemon response). Defect source: **environment** — not an implementation regression.

## Fixes Made
1. Updated `test_total_paid_request_hash_uses_resolved_paid_amount` to pass `gst_flag=True` before `paid_amount`.
2. Added `test_date_only_invoice_request_resolves_to_utc_midnight` pure test for AC-DATE-01 schema behavior.
3. Removed duplicate `gst_flag` key from `_company_payload()` in API test fixture.

## Regression Tests Added
- `test_date_only_invoice_request_resolves_to_utc_midnight` in `backend/pure_tests/test_invoice_v2_domain_pure.py`

## Commands And Results
| Command | Scope | Result | Evidence/notes |
|---|---|---|---|
| `git log --oneline 7699ae6..HEAD` | Stage 3 commits | 8 commits (7 feat + 1 docs) | Tasks 01–06 present |
| `cd mobile && flutter test test` | Full mobile | **372 passed** | Independent rerun |
| `cd mobile && flutter analyze` | Mobile lint | 19 issues (baseline warnings/info) | No new errors from Stage 3 |
| `flutter build apk --release --dart-define=DATA_MODE=local` | Release | **OK** 59MB APK | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| `pytest backend/pure_tests -q` | No-DB backend | **47 passed** (after fix) | Was 46 pass / 1 fail before fix |
| `pytest backend/tests/test_invoice_gst_flag_migration_contract.py -q` | Migration contract | **1 passed** | Source-inspect only |
| `BILLING_DATABASE_URL=... pytest backend/tests -q` | Full backend | **156 errors** | Postgres unavailable |
| `pg_isready -h localhost -p 55432` | Environment | **no response** | Port closed |

## Runtime And Scenario Validation
| Scenario | Method | Result |
|---|---|---|
| GST/non-GST PDF page threshold | `invoice_pdf_service_test.dart` MediaBox parse | A5 at 10 rows, A4 at 11 |
| Non-GST PDF content omission | Layout helper tests | GSTIN/supply section omitted when `gstFlag=false` |
| Canceled invoice watermark | PDF header helper test | `CANCELED` banner when status canceled |
| Invoice share caption privacy | `invoice_share_service_test.dart` | No GSTIN/bank/IDs in caption |
| Share PDF not phone-gated | `invoice_detail_screen.dart` + widget tests | `sharePdfButton` always shown when service injected |
| Individual balance preview/share | `customer_detail_screen_test.dart` | Preview modal + confirm/cancel |
| Daily positive-balance summary | `customer_list_screen_test.dart` | Filter/sort/total/empty preview |
| Non-GST zero-tax local create | `local_invoices_service_test.dart` | Zero tax, final price preserved |
| Idempotency includes gst_flag (local) | `local_invoices_service_test.dart` | Mode flip conflicts |
| Android chooser attachment+caption | — | **Not executed** (no device session) |
| Restart persistence E2E | — | **Not executed** |

## Compatibility/Security/Privacy/Data Integrity
- Migration `0009` adds/backfills only `gst_flag`; contract test forbids financial column updates.
- Drift v9 backfill predicates match Alembic (source-inspected).
- Share captions/messages exclude GSTIN, bank, and internal IDs (tested).
- Balance sharing is explicit (preview modal) and text-only.
- No `wa.me` invoice PDF action remains in mobile codebase (grep clean).
- Invoice PDFs render from persisted `InvoiceDetail` snapshots, not live profile (code path verified).

## Performance/Observability/Deployment/Rollback
- Release APK builds successfully for `DATA_MODE=local`.
- Rollback guidance in plan remains accurate: downgrade `0009` only after confirming no non-GST records need old-client rendering; local v9 not downgradable in place.
- No new metrics/logging of share bodies introduced.

## Documentation Accuracy
| Doc | Claim | Actual | Accurate? |
|---|---|---|---|
| `mobile/agent.md` | Schema 9, 372 tests | Confirmed | Yes |
| `03-implementation-log.md` | 372 mobile pass | Reproduced | Yes |
| `03-implementation-log.md` | Postgres blocked | Reproduced | Yes |
| `README.md` | Schema 9 / GST features | Matches code | Yes |

## Acceptable Deviations And False Alarms
- Android E2E matrix deferred with honest logging — acceptable for Stage 4 given environment; not acceptable for final production approval.
- PDF text extraction via MediaBox/latin1 decode instead of full PDF parser — acceptable test seam per plan.
- Implementation log HEAD `3f71e22` vs current `de7318a` docs commit — expected doc-only delta.

## Remaining Risks And Unverified Evidence
1. **Full backend PostgreSQL suite** — 0 integration tests executed this session.
2. **Live Alembic 0009 upgrade/backfill inspection** on disposable DB.
3. **Android runtime** — share chooser attachment+caption, balance share, persistence after restart.
4. **Visual PDF review** — four variants not manually inspected.
5. **API-mode mobile** end-to-end against running backend not exercised (local mode primary proof).

## Upstream Corrections Required
| Target | Item | Source |
|---|---|---|
| Stage 5 / ops | Start `khata-postgres` and rerun full `pytest backend/tests -q` | Environment |
| Stage 5 | Android local-mode E2E matrix on device/emulator | Plan AC-REGRESSION-01 |
| None | No design/plan defects requiring Stage 1–2 return | — |

## Files/Commits/Rollback Notes
Stage 3 implementation commits (verified present):
- `7a961b2` Task 01 contracts
- `61f097e` Task 02 tax semantics
- `ad7fb43` Task 03 mobile date/GST UI
- `cc03688` Task 04 PDFs
- `65e6e41` Task 05 share
- `3f71e22` Task 06 balance share
- `de7318a` docs handoff

Stage 4 uncommitted fixes:
- `backend/pure_tests/test_invoice_v2_domain_pure.py`
- `backend/tests/api/test_invoice_create_api.py`

## Exact Stage-5 Objective
Determine production readiness after independently running: (1) full PostgreSQL pytest with `khata-postgres`, (2) Android local-mode E2E matrix, (3) optional visual PDF review; confirm no financial/migration regressions in API+local parity paths.
