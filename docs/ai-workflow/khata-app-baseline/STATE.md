# Workflow State

Workflow ID: khata-app-baseline

Objective: Deliver mobile-first GST/non-GST invoicing, date-only invoice creation, adaptive invoice PDFs, attached invoice sharing, and customer pending-balance sharing while keeping local and API contracts aligned.

Current stage: 2-planning

Stage status: complete

Repository: `/Users/abhishek/python_venv/khata_app`

Branch: `main`

Stage 2 repository baseline SHA: `7699ae634988fcf577d7ee3e26480a37c475be02`

Worktree at Stage 2 start: clean. Stage 2 changed workflow documentation only; no production code was implemented.

## Context Topology
- Persistent LLM lane: `paused-after-stage-2`
- Current context owner: paused Stage 1/2 persistent LLM conversation
- Next context owner: Stage 3 fresh SLM
- Minimum Stage 3 read set: this `STATE.md`, `01-design.md`, `02-plan/00-plan-index.md`, and the assigned task packet
- First task packet: `02-plan/01-contracts-and-migrations.md`
- Later Stage 5 rehydration: this file, `02-llm-review-anchor.md`, Stage 4 return packet, actual diff/commit range

## Upstream Recovery And Evidence
- Stage 0 discovery exists at `00-discovery.md` and was partial because no feature request was supplied.
- Stage 1 reconstructed the feature from repository truth and user input, resolved GST legality/financial semantics, customer-vs-buyer terminology, daily summary meaning, and WhatsApp attachment behavior.
- Stage 1 design is durable at `01-design.md`.
- Stage 0 evidence remains valid unless contradicted here: 355 mobile tests had passed; backend suite was not completed because PostgreSQL availability was unresolved; README/agent backup schema docs were stale at 6 while code was 8.

## Refined Scope
- Persist seller and invoice `gst_flag` in backend/local schemas and snapshots.
- Enforce genuine GST/non-GST calculation and seller eligibility in API/local quote/create.
- Make mobile invoice input date-only while preserving legacy aware-datetime backend compatibility.
- Render GST/non-GST A5 PDFs for <=10 rows and A4 for >10 rows.
- Share attached invoice PDF plus safe caption through OS chooser.
- Preview/share individual customer balance and all-positive-customer dated daily summary.
- Migrate/backfill safely, bump Drift/backup schema to 9, update docs, and prove parity/runtime behavior.

## Non-Goals
- GST filing/IRN/e-way bills/legal automation.
- Arbitrary taxable non-GST invoices by GST sellers.
- Supplier/buyer payable sharing.
- Cloud/Drive completion, direct WhatsApp Business API, auto-send, or delivery receipts.
- Destructive removal of persisted `invoice_datetime`.
- Conversion/import support for old v8 encrypted backup packages.

## Locked Decisions
- Non-GST documents calculate zero tax; they never hide non-zero GST.
- Non-GST seller cannot issue GST and forces effective line tax to zero while treating selling price as final.
- GST seller may select non-GST only when all resolved line GST rates are zero.
- Stable validation codes: `INVALID_GST_PROFILE`, `GST_INVOICE_NOT_ALLOWED`, `NON_GST_TAXABLE_LINES`.
- Resolved `gst_flag` is included in idempotency hash and immutable invoice persistence.
- New mobile sends only `invoice_date`; date-only persistence derives UTC midnight; legacy aware datetime remains supported.
- PDF threshold uses item-row count exactly: <=10 A5, >10 A4.
- Primary WhatsApp path is attached PDF via system chooser; remove misleading invoice `wa.me` action.
- Balance sharing targets customer receivables; daily means current positive balances labeled with current local date.
- No new balance API endpoint; reuse one canonical customer-list query in either mode.

## Acceptance Criteria
- `AC-GST-01`: seller defaults and allowed modes in API/local/UI.
- `AC-GST-02`: zero-tax non-GST calculation and omission of GST PDF content.
- `AC-DATE-01`: date-only mobile quote/create with legacy aware-datetime compatibility.
- `AC-PDF-01`: exact 10/A5 and 11/A4 behavior for both modes.
- `AC-PDF-02`: readable/correct four variants and canceled state.
- `AC-SHARE-01`: PDF attachment plus caption through OS chooser.
- `AC-BAL-01`: individual shared balance equals canonical ledger balance.
- `AC-BAL-02`: daily positive-only summary and exact total/empty state.
- `AC-COMPAT-01`: deterministic legacy migration and compatible clients.
- `AC-REGRESSION-01`: stock/ledger/idempotency/cancel/parity/full suites/build/runtime remain sound.

## Plan Artifacts And Task Order
- Index: `02-plan/00-plan-index.md`
- Task 01: `02-plan/01-contracts-and-migrations.md`
- Task 02: `02-plan/02-invoice-tax-semantics.md`
- Task 03: `02-plan/03-mobile-profile-and-date-flow.md`
- Task 04: `02-plan/04-adaptive-invoice-pdfs.md`
- Task 05: `02-plan/05-invoice-sharing.md`
- Task 06: `02-plan/06-balance-sharing-and-integration.md`
- LLM review anchor: `02-llm-review-anchor.md`
- Stage 3 evidence log: `03-implementation-log.md`

Task order: 01 -> 02 -> 03 -> 04 -> 05 -> 06. Do not parallelize Tasks 01-03 because they share schemas/models/contracts. Task 04 may be locally prepared after Task 03 but merges after Task 02 canonical semantics.

## Plan Assumptions
- Zero numeric GST rate is sufficient to identify GST-seller lines eligible for non-GST mode.
- `share_plus` 10 can attach PDF plus caption on the target Android environment; runtime proof is mandatory.
- Customer-list archived-record behavior is aligned across API/local or will be returned as a plan defect.
- Current dated balance snapshot, not same-day movement, is the approved daily summary.

## High-Risk Gates
- Task 01: human/strong-model review of Alembic backfill and generated Drift diff.
- Task 02: review non-GST price math, GST regression, ledger totals, cancellation, and idempotency hash.
- Task 04: parsed dimensions/content plus visual review of four variants and canceled/long documents.
- Task 05/06: Android chooser/attachment and privacy/accuracy runtime review.
- Final: full backend PostgreSQL suite, full mobile suite, analyzer accounting for known baseline lint dependency defect, local release APK, and Android local-mode E2E.

## Stage 3 Execution Rules
- Use a fresh SLM context per assigned packet and TDD where specified.
- Read only the minimum set plus packet-directed files; repository evidence outranks plan if a path drifted.
- Stop on packet escalation conditions; return a plan defect instead of inventing policy.
- Update `03-implementation-log.md` and this state after each task with actual evidence.
- Do not mark planned commands as passed or planned behavior as implemented.

## Execution Ledger
| Stage | Context/model lane | Start SHA | End SHA | Status | Primary artifacts |
|---|---|---|---|---|---|
| 0 | fresh SLM discovery | `53886a6` | `7699ae6` documentation baseline | partial | `00-discovery.md`, original `STATE.md` |
| 1 | persistent strong LLM | `7699ae6` | documentation-only worktree | complete | `01-design.md` |
| 2 | same persistent strong LLM | `7699ae6` | documentation-only worktree | complete | `02-plan/*`, `02-llm-review-anchor.md`, this state |

Last completed stage: 2-planning

Next required stage: 3-implementation

Exact next action: Pause the persistent LLM conversation. In a fresh SLM context, read this file, `01-design.md`, `02-plan/00-plan-index.md`, and `02-plan/01-contracts-and-migrations.md`; execute Task 01 only, stop on listed escalation conditions, and update `03-implementation-log.md` plus this file before ending.

Last updated: 2026-06-13
