# Implementation Plan Index: GST And Non-GST Invoices, Adaptive PDFs, And Balance Sharing

Objective: Deliver the approved invoice and customer-balance experience with local/API parity and migration safety.

Design/discovery references: `../00-discovery.md`, `../01-design.md`

Repository baseline: `7699ae634988fcf577d7ee3e26480a37c475be02` on `main`; clean before Stage 2 artifact writes.

Target outcome: A fresh SLM can implement six coherent slices without choosing tax policy, compatibility behavior, layout thresholds, or sharing scope.

Scope/non-goals: Use `01-design.md` as authoritative. Do not add GST filing/e-invoicing, supplier payable sharing, cloud sync, direct WhatsApp APIs, old-backup conversion, or destructive datetime removal.

Locked decisions:
- Seller and invoice use persisted boolean `gst_flag`.
- Non-GST seller forces zero effective tax and cannot issue GST invoices.
- GST seller may issue non-GST only when every line resolves to 0% GST.
- Mobile is date-only; backend retains aware `invoice_datetime` compatibility and persists UTC midnight for date-only requests.
- At most 10 item rows is A5; more than 10 is A4.
- Invoice PDF is shared with a caption through the OS share sheet.
- Balance sharing covers individual customer receivables and an all-positive-balances daily summary.

Contracts to preserve: auth, request-id idempotency, append-only ledgers, transactional stock/invoice side effects, existing GST calculations for GST invoices, API error envelope, local/backend field alignment, and immutable invoice snapshots.

Global risks and stop conditions:
- Stop if effective non-GST calculation cannot preserve line total as the entered/final selling price without changing approved pricing semantics.
- Stop if a migration would rewrite historical amounts, tax snapshots, ledger rows, or stock movements.
- Stop if generated Drift output contains unrelated schema churn.
- Stop if attachment sharing requires a new external service or platform credentials.
- Do not proceed past Task 02 until backend and local tax/idempotency tests are green.

Execution model: fresh SLM context per task. Execute sequentially because later tasks consume shared schemas/models; Task 04 can be prepared after Task 03 but should merge only after Task 02.

## Requirements Coverage
| AC/invariant | Task(s) | Proof |
|---|---|---|
| AC-GST-01 | 01, 02, 03 | migration, API/local service, profile/draft widget tests |
| AC-GST-02 | 02, 04 | zero-tax calculation plus PDF text assertions |
| AC-DATE-01 | 03 | API compatibility, mobile payload, local service and widget tests |
| AC-PDF-01 | 04 | parsed first-page dimensions for 10/11 lines in both modes |
| AC-PDF-02 | 04 | parsed text/amount/status tests and manual rendering |
| AC-SHARE-01 | 05 | handler/widget tests and Android share-sheet smoke |
| AC-BAL-01 | 06 | formatter and customer-detail widget tests |
| AC-BAL-02 | 06 | positive-filter/total/empty-state tests and runtime smoke |
| AC-COMPAT-01 | 01, 03 | Alembic/Drift backfill tests and legacy aware-datetime API test |
| AC-REGRESSION-01 | 02-06 | focused gates, full suites, build, and local Android E2E |
| Append-only ledger/transactionality | 02 | existing invoice create/cancel integration tests plus new mode cases |
| Idempotency includes tax mode | 02 | same request/same mode succeeds; changed mode conflicts |
| Privacy/user initiation | 05, 06 | no auto-send/logging; preview and explicit share actions |

## Task/Slice Order
| ID | Outcome | Depends on | Parallel? | Risk | Plan file |
|---|---|---|---|---|---|
| 01 | Add aligned GST flags and safe migrations | none | No | High | `01-contracts-and-migrations.md` |
| 02 | Enforce GST/non-GST calculation and idempotency | 01 | No | High | `02-invoice-tax-semantics.md` |
| 03 | Make profile/draft mobile flow date-only and policy-aware | 02 | No | High | `03-mobile-profile-and-date-flow.md` |
| 04 | Render four adaptive invoice PDF variants | 02, 03 models | Limited | Medium | `04-adaptive-invoice-pdfs.md` |
| 05 | Share attached invoice PDF with formatted caption | 04 | No | Medium | `05-invoice-sharing.md` |
| 06 | Share individual and daily customer balances; integrate/release | 03 | No | Medium | `06-balance-sharing-and-integration.md` |

## Cross-Cutting Decisions
- API compatibility: request `gst_flag` is optional server-side during the compatibility window and resolves from active profile; responses always include it after migration. Mobile always sends it.
- Validation codes: `INVALID_GST_PROFILE`, `GST_INVOICE_NOT_ALLOWED`, and `NON_GST_TAXABLE_LINES`, wrapped through existing error behavior.
- New profiles default `gst_flag=false`; migrated profiles infer it from non-empty GSTIN.
- Local database and backup schema become 9; `backend_compatibility_version` remains `local-v2`.
- Do not add feature flags: local migration plus additive backend columns provide the compatibility window.
- Do not log share bodies or sensitive profile/customer fields. No new metrics stack is justified; user-visible errors and test evidence are sufficient for this local-first release.

## Baseline Commands
Run before Task 01 and record actual results in `03-implementation-log.md`:

```bash
git status --short
(cd mobile && flutter test test)
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
```

If PostgreSQL is unavailable, record the exact failure and run no-DB migration contract tests; backend completion still requires the PostgreSQL suite before Stage 4.

## Integration And Release Validation
1. Apply Alembic `0009` to a disposable test database and inspect backfilled flags without changing historical totals.
2. Upgrade an in-memory/file Drift v8 fixture to v9 and export/import a v9 encrypted backup.
3. Run focused tests after every task, then full `flutter test test` and backend `pytest backend/tests -q`.
4. Run `flutter analyze`; known missing `flutter_lints` dependency is an upstream baseline defect, not permission for new analyzer errors.
5. Build local release APK with `flutter build apk --release --dart-define=DATA_MODE=local`.
6. On Android local mode, create and share GST/non-GST invoices with 10 and 11 rows; verify date-only creation, page size, attachment, captions, individual balance, daily summary, empty state, and canceled watermark.

## Rollout/Rollback
- API mode: deploy backend migration/code first, then mobile. Old clients continue because omitted `gst_flag` resolves from profile and aware datetimes remain accepted.
- Local mode: ship schema v9 and regenerated Drift code atomically. Existing installed databases migrate in place; v8 backup packages remain rejected.
- Rollback condition: incorrect totals, historical mutation, idempotency drift, migration failure, or share action leaking/auto-sending data.
- Rollback sequence: stop new invoice writes, restore prior app/backend, downgrade `0009` only after confirming no required non-GST records need old-client rendering. Local schema rollback is not supported in place; restore the prior APK only with a compatible pre-v9 backup/database snapshot.

## Strong-Model/Human Review Gates
- After Task 01: inspect migration/backfill and generated Drift diff.
- After Task 02: inspect tax normalization, price semantics, ledger totals, and request hashes.
- After Task 04: visually inspect all four PDF variants and canceled documents.
- Before release: inspect Android share chooser and balance-message privacy/accuracy.

## Known Plan Assumptions
- Product GST rate remains numeric; zero denotes an exempt/zero-rate line for the GST-seller non-GST eligibility rule.
- Non-GST seller product prices are final prices even if legacy product GST metadata is non-zero.
- `share_plus` supports attachment plus caption on the target Android environment; no WhatsApp-specific attachment API is promised.
- Current customer balances are the required “day-wise pending balance” snapshot as of the device-local current date, not transaction-only movement for that date.

## Plan Self-Review Result
- Coverage: all ten acceptance criteria and core invariants map to tasks/proofs.
- Repository accuracy: paths, symbols, migration head, schema version, routes, and commands were checked at baseline SHA.
- Decision completeness: no consequential tax, date, layout, sharing, migration, or rollback choice remains for the SLM.
- Negative behavior: invalid modes, legacy compatibility, empty reports, canceled invoices, failures, and idempotency are explicit.
- Context size: each packet is bounded to one coherent fresh-context slice.

