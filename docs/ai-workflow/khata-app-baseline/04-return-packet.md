# Stage 4 Return Packet For The Original LLM

## Resume Instructions
Return to the same LLM conversation used for Stages 1 and 2. If compacted, read:
1. `STATE.md`
2. `02-llm-review-anchor.md`
3. This return packet
4. The actual diff/commits listed below

Do not restart broad repository discovery unless a contradiction below requires it.

## Identity And Final State
Workflow objective: GST/non-GST invoicing, date-only creation, adaptive PDFs, attached sharing, customer balance sharing with API/local parity.

Repository/branch/worktree: `/Users/abhishek/python_venv/khata_app`, `main`, dirty (Stage 4 test fixes uncommitted)

Planning baseline SHA: `7699ae634988fcf577d7ee3e26480a37c475be02`

Stage 3 starting/ending SHA: `7699ae6` → `3f71e22` (code), `de7318a` (docs handoff)

Stage 4 starting/final SHA: `de7318a` / `de7318a` (+ uncommitted test fixes)

Target release/environment: Local-mode Android APK (`DATA_MODE=local`); API mode requires Postgres on `55432`

## Executive Delta
- Six plan tasks implemented across backend and mobile with matching `gst_flag` contracts, tax semantics, UI, PDFs, sharing, and balance messages.
- Drift/backup schema **9** and Alembic **0009** add deterministic `gst_flag` backfills without touching money/ledger columns.
- Mobile independently passes **372** tests; release APK builds (59MB).
- Invoice PDFs adapt A5 (≤10 lines) / A4 (>10), GST vs non-GST content, canceled banner.
- Invoice sharing uses OS chooser with PDF attachment + safe caption; `wa.me` invoice action removed.
- Customer balance sharing: individual preview + daily positive-balance summary with exact total.
- Stage 4 found and fixed one stale backend pure test after `gst_flag` hash contract change.
- **Blocked:** full PostgreSQL pytest and Android device E2E — environment, not code failure.
- **Verdict:** pass-with-minor-issues — ready for Stage 5 senior review with explicit unverified gates.

## Commit Ledger
| Commit | Stage/task | Intent | Key files/contracts | Validation at commit |
|---|---|---|---|---|
| `7a961b2` | 01 | `gst_flag` migrations/DTOs | `0009_invoice_gst_flags.py`, Drift v9, backup 9 | Migration contract + mobile local tests (Stage 3) |
| `61f097e` | 02 | GST/non-GST tax + hash | `pricing.py`, `invoice_service.py`, `local_invoices_service.dart` | Service tests (Stage 3; DB blocked Stage 4) |
| `ad7fb43` | 03 | Seller GST switch, date-only | `company_profile_screen.dart`, `invoice_draft.dart` | Mobile profile/invoice tests |
| `cc03688` | 04 | Adaptive PDFs | `invoice_pdf_service.dart` | PDF dimension/content tests |
| `65e6e41` | 05 | PDF+caption share | `invoice_share_service.dart`, invoice screens | Share service/widget tests |
| `3f71e22` | 06 | Balance sharing + integration | `balance_share_service.dart`, customer screens | Balance + customer widget tests |
| `de7318a` | docs | Handoff SHAs | `03-implementation-log.md`, `STATE.md` | Documentation only |
| *(uncommitted)* | 04 | Test repair | `test_invoice_v2_domain_pure.py`, `test_invoice_create_api.py` | Pure 47 pass (Stage 4) |

## Change Manifest
| Path | Symbol/section | Before -> after | Why | Task/AC | Commit | Risk |
|---|---|---|---|---|---|---|
| `backend/alembic/versions/0009_invoice_gst_flags.py` | `upgrade()` | N/A -> add/backfill `gst_flag` | Persist seller/invoice mode | 01 / AC-GST-01 | `7a961b2` | High — inspect backfill |
| `backend/app/services/invoice_service.py` | `_build_invoice_request_hash` | no mode -> includes `gst_flag` | Idempotency parity | 02 | `61f097e` | High |
| `backend/app/core/pricing.py` | `normalize_non_gst_line` | N/A -> zero-tax final price | Non-GST math | 02 / AC-GST-02 | `61f097e` | High |
| `mobile/lib/local/local_database.dart` | schema v9 | 8 -> 9 `gst_flag` columns | Local parity | 01 | `7a961b2` | High |
| `mobile/lib/models/invoice_draft.dart` | `toJson()` | datetime field -> date only | Mobile date-only | 03 / AC-DATE-01 | `ad7fb43` | Medium |
| `mobile/lib/services/invoice_pdf_service.dart` | page format helpers | A4 only -> A5/A4 + GST variants | Adaptive PDFs | 04 / AC-PDF | `cc03688` | Medium |
| `mobile/lib/services/invoice_share_service.dart` | `formatInvoiceShareCaption` | wa.me path -> `shareXFiles`+caption | Safe sharing | 05 / AC-SHARE-01 | `65e6e41` | Medium |
| `mobile/lib/services/balance_share_service.dart` | formatters | N/A -> individual/daily messages | Collections | 06 / AC-BAL | `3f71e22` | Medium |

## Contract And Architecture Delta
- **APIs/schemas:** `gst_flag` on company profile upsert/response; optional on invoice quote/create, required on responses; validation codes `INVALID_GST_PROFILE`, `GST_INVOICE_NOT_ALLOWED`, `NON_GST_TAXABLE_LINES`.
- **Persistence:** Alembic 0009 + Drift v9; backup `currentSchemaVersion = 9`; v8 backups rejected.
- **Mobile payloads:** `invoice_date` only (no `invoice_datetime`); always sends `gst_flag` when set on draft.
- **PDF:** Uses persisted `invoice.gstFlag` and snapshot fields — not live profile inference.
- **Sharing:** `Share.shareXFiles([XFile(path)], text: caption)`; SMS remains `sms:` URI only.
- **Unchanged:** append-only ledger, transactional stock/invoice writes, existing GST math for GST mode, auth/session, `backend_compatibility_version`.

## Plan And Acceptance Coverage
| Task/AC | Implementation evidence | Validation evidence | Status |
|---|---|---|---|
| 01 / AC-GST-01 | Migrations, models, Drift v9 | Migration contract 1 pass; mobile local/backup tests pass | pass-with-gaps |
| 02 / AC-GST-02 | `normalize_non_gst_line`, policy validators, hash | Mobile local tests; pure tests; DB service tests blocked | pass-with-gaps |
| 03 / AC-DATE-01 | Draft date-only, profile switch | Mobile tests + new pure date-only test | pass-with-gaps |
| 04 / AC-PDF-01/02 | PDF service refactor | 12 PDF tests (dimensions/helpers) | pass-with-gaps |
| 05 / AC-SHARE-01 | Share service + screens | Service/widget tests | pass-with-gaps |
| 06 / AC-BAL-01/02 | Balance service + screens | Formatter/widget tests | pass-with-gaps |
| AC-COMPAT-01 | Backfill predicates aligned | Contract + Drift tests | pass-with-gaps |
| AC-REGRESSION-01 | Full mobile + APK | 372 pass, APK OK; backend/Android E2E blocked | pass-with-gaps |

## Deviations And Decisions During Execution
| Planned | Actual | Reason/evidence | Defect source | Approved/safe? |
|---|---|---|---|---|
| Backend date API tests in Task 03 | Not evidenced with Postgres | DB unavailable | Environment | Safe pending rerun |
| Android E2E in Task 05/06 | Deferred | No device session | Environment | Safe pending rerun |
| Manual PDF visual review | Not committed | Test seam used instead | Verification | Acceptable interim |
| Pure hash test update in Task 02 | Missed | Stale test arity | Verification | Fixed in Stage 4 |

## Fixes Found By Stage 4
| Finding | Root cause | Fix | Regression evidence | Commit |
|---|---|---|---|---|
| Pure hash test failure | Test not updated for `gst_flag` param | Pass `True` as 4th arg; add date-only pure test | `pytest backend/pure_tests -q` → 47 pass | uncommitted |
| Duplicate `gst_flag` in API fixture | Copy/paste | Remove duplicate key | Hygiene only | uncommitted |

## Commands And Evidence Index
| Command/scenario | Final result | What it proves | Raw log/artifact path |
|---|---|---|---|
| `flutter test test` | 372 pass | Full mobile regression | Stage 4 session stdout |
| `flutter build apk --release --dart-define=DATA_MODE=local` | OK | Release build | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| `pytest backend/pure_tests -q` | 47 pass | Schema/hash/date contracts without DB | Stage 4 session |
| `pytest backend/tests/test_invoice_gst_flag_migration_contract.py -q` | 1 pass | Migration safety | Stage 4 session |
| `pytest backend/tests -q` (with test DB URL) | 156 errors | Postgres unavailable | Stage 4 session |
| `flutter analyze` | 19 baseline issues | No new analyzer errors | Stage 4 session |

## Runtime/E2E Evidence
No Android device/emulator session was available. Widget and service tests prove UI wiring for share/balance preview flows. APK artifact exists but was not installed/tested on hardware this session.

## New Repository Facts Since Planning
- Backend pure-test ladder is required when Postgres is down; it caught a stale hash test the full suite would also exercise once DB is up.
- `docker start khata-postgres` did not become ready within validation window; port 55432 remained closed.
- Current HEAD includes doc-only commit `de7318a` after Task 06 code commit `3f71e22`.

## Known Issues, Unverified Claims, And Residual Risk
- **Unverified:** entire `pytest backend/tests -q` integration surface (invoice create/cancel API, company profile API, wholesaler E2E).
- **Unverified:** Android share chooser actually delivers attachment+caption together on target device (`share_plus` assumption).
- **Unverified:** live Alembic 0009 backfill row inspection on real data.
- **Low risk:** unused `_buildHeader` in PDF service (analyzer warning only).
- **Stage 4 fixes uncommitted** — commit or include before release branch merge.

## Defect Attribution
| Source | Count | Examples |
|---|---|---|
| Environment | 2 | Postgres down; Android E2E not run |
| Verification | 2 | Stale pure test; missing API date tests when DB down |
| Implementation | 1 | Duplicate dict key in test fixture (minor) |
| Discovery/Design/Plan | 0 | No upstream return required |

## Stage 5 Review Map
### Read first
1. `backend/alembic/versions/0009_invoice_gst_flags.py` — backfill safety
2. `backend/app/services/invoice_service.py` — `_resolve_gst_flag`, `_validate_invoice_gst_mode`, `_build_invoice_request_hash`, `create_invoice`
3. `backend/app/core/pricing.py` — `normalize_non_gst_line`
4. `mobile/lib/local/local_invoices_service.dart` — local parity for hash/policy/non-GST
5. `mobile/lib/services/invoice_pdf_service.dart` — adaptive layout
6. `mobile/lib/services/invoice_share_service.dart` — caption formatter
7. `mobile/lib/services/balance_share_service.dart` — balance formatters

### Read on demand
- Task-specific tests under `mobile/test/services/`, `mobile/test/widgets/`, `backend/tests/services/test_invoice_service.py`
- `mobile/lib/screens/customer_detail_screen.dart`, `customer_list_screen.dart` for preview UX
- `docs/ai-workflow/khata-app-baseline/04-validation-report.md` for full evidence table

### Commands to rerun
```bash
docker start khata-postgres  # or create per README
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' \
  PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
cd mobile && flutter test test
cd mobile && flutter build apk --release --dart-define=DATA_MODE=local
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
```

### Review hypotheses
- Non-GST math might diverge between API Decimal and local double at boundary values — run paired quote tests when Postgres is up.
- PDF readability for long GST invoices (>10 lines) not visually confirmed.
- Daily balance summary uses `Customer.pendingBalance` from list fetch — confirm archived customers excluded consistently.
- Idempotency conflict on `gst_flag` flip may be proven only on local path until DB tests run.

### Do not waste context on
- Workflow doc-only files unless tracing a plan discrepancy
- Unchanged auth/analytics/buyer modules
- Baseline `flutter analyze` warnings predating Stage 3

## Recommended Stage 5 Verdict Question
**Can this ship for local-mode Android wholesalers after Postgres integration tests and device E2E pass, with no migration or financial contract regressions?**

Evidence still needed:
1. Green `pytest backend/tests -q` on `internal_billing_test`
2. Android matrix: GST/non-GST 10/11-line PDF share, balance share, cancel watermark, restart persistence
3. Decision on committing Stage 4 test fixes
