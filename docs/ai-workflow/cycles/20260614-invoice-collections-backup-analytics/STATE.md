# Workflow State

Cycle ID: `20260614-invoice-collections-backup-analytics`

Parent cycle: `khata-app-baseline`

Objective: Upgrade product/HSN and invoice contracts, invoice entry/PDF UX, batch customer collections, encrypted Google Drive backups, and owner analytics while preserving local/API parity and historical accounting data.

Workflow schema: five-stage-v1

Current stage: `5-final-review`

Stage status: `returned-to-stage-3`

Current task: Repair collection concurrency and revalidate with PostgreSQL

Current artifact HEAD at Stage 5 intake: `f25e5cadc9b6db16a71032ed6003aa6e8ea2e435`

Final reviewed code SHA: `5b6616502efdb511352e3124894ffcb643842535`

## Stage 1 Repair

The supplied Stage 1 artifact was a context refresh with no objective-specific discovery. Stage 2 repaired the minimum missing context by inspecting the live contracts, catalog workbook, invoice UI/PDFs, customer ledger, backup skeleton, analytics services, and current tests. The approved design is recorded in this cycle and implementation is grounded at the baseline below.

## Git And Worktree Contract

Integration target branch: `main` (SHA `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`)

Feature branch: `codex/khata-invoice-collections-backup-analytics`

Worktree name/ID: `khata_app-upgrade`

Canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app-upgrade`

Worktree baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Stage 3 ending SHA: `49cec2c630fed1add8db110c9001fab4f060e9f9`

Stage 4 reviewed code SHA: `5b6616502efdb511352e3124894ffcb643842535`

Stage 4 validation artifact commit: `2399faecff7f594378a6d41dd2d41264de2bd5f0`; post-validation SHA-label correction: `f25e5cadc9b6db16a71032ed6003aa6e8ea2e435`

Worktree status: `stage-5-artifacts-dirty`; untracked `.venv` and rolling workflow files are present

Merge owner: Stage 5 persistent LLM

Merge authorization: required (not recorded)

Merge status: not-started (not merge-eligible)

Untracked outside cycle folder: `.venv`, `docs/ai-workflow/INDEX.md`, `docs/ai-workflow/PROJECT_CONTEXT.md`

Primary checkout `/Users/abhishek/python_venv/khata_app` must remain untouched.

## Locked Decisions

- HSN is nullable and non-unique on products, snapshotted on invoice lines, and required for every new GST invoice line.
- Existing product IDs and item numbers remain stable. Missing workbook HSN values are not invented.
- New invoice and stock-adjustment quantities must be whole numbers; historical fractional values remain readable.
- Unit prices use three-decimal precision; financial totals remain two-decimal currency values.
- Discounts remain in legacy contracts but new invoice writes require zero.
- Product search is in invoice creation only and matches name, item number, company, and HSN.
- Non-GST creation and documents expose no GST controls or columns.
- Cash means fully paid. Credit means unpaid or partially paid while preserving exact paid and balance amounts.
- Normal status labels are removed from documents; canceled invoices retain a visible watermark.
- Batch customer collections are seven-day, atomic, idempotent, zero-safe, and cannot overpay.
- Drive backups use Google sign-in, a visible `Khata Backups` folder, secure password storage, best-effort 02:00 scheduling with catch-up, and 30-backup retention.
- Analytics becomes an owner snapshot; low-stock data remains API-compatible but is removed from the analytics UI.

## Execution Order

1. Platform/dependency feasibility gate.
2. Contracts, migrations, catalog, and backup compatibility.
3. Invoice semantics, creation UX, and PDFs.
4. Atomic batch Khata collections.
5. Drive integration and background scheduling.
6. Analytics contracts and dashboard UI.
7. Full verification, artifacts, and handoff.

All seven implementation tasks were attempted. Task 04 is returned to Stage 3 because its API concurrency contract is incomplete.

## High-Risk Gates

- No financial column may be destructively rewritten during migration.
- API and local quote/create paths must agree on HSN, quantity, discount, payment, and precision rules.
- Batch collection failure must leave every customer balance unchanged.
- Restore must validate schema/compatibility before replacing local data.
- Drive credentials and tokens must never be committed.
- Physical-device Google OAuth/background/restore evidence is required before AC10/AC11 can be marked proven.

## Acceptance Criteria

AC1-AC14 mapped in `03-implementation-log.md` and `04-validation-report.md`.

Stage 4 verdict: **pass-with-minor-issues** (overruled by Stage 5)

Stage 5 verdict: **fix-required**

Stage 5 artifact: `05-final-review.md`

Stage 4 artifacts: `04-validation-report.md`, `04-return-packet.md`

## Stage 4 Summary

### Fixes (commit `5b66165`)

- Persist `product_hsn_code` on API invoice create (`invoice_service._insert_invoice_items`).
- Batch UI: reload grid on `IDEMPOTENCY_CONFLICT`; invalidate request ID on date column add/remove.
- Align local `_canonicalBatchHash` key ordering with backend `sort_keys`.
- Redact sensitive backup failures in background callback and catch-up scheduler.

### Independent evidence

| Check | Result |
|---|---|
| `pytest backend/pure_tests -q` | 56 passed |
| `flutter test test` | 460 passed |
| `flutter build apk --release --dart-define=DATA_MODE=local` | 66.5 MB; SHA-256 `3de1bc6a121f294305f53daccb50c69f00ccfae63507b1f766757139ecfb8542` |
| `pg_isready -h localhost -p 55432` | fail (Docker daemon unavailable) |
| `pytest backend/tests -q` | blocked |

### Stage 5 Blocking Findings

1. `create_collection_batch` has no durable batch-level lock/unique identity, so concurrent conflicting payloads using the same batch request ID can both commit.
2. `create_collection` does not share the customer lock used by batch writes, so concurrent single and batch collections can violate the no-overpayment invariant.
3. PostgreSQL on `:55432` remains unavailable; Alembic and full backend integration evidence is missing.
4. AC10 and physical AC11 Drive evidence remain unverified.

### Fresh Stage 5 Evidence

| Check | Result |
|---|---|
| `pytest backend/pure_tests -q` | 56 passed |
| focused collection/backup/PDF/cross-slice Flutter tests | 42 passed |
| `pg_isready -h localhost -p 55432` | no response |
| Docker Desktop recovery wait | daemon remained unavailable |
| collection transaction code review | AC9 concurrency contradicted |

## Context Topology

- Persistent LLM lane: `resumed-stage-5`
- Current owner: `Stage 5 persistent LLM`
- Next owner: `Stage 3 fresh SLM`
- Minimum read set: this file, `05-final-review.md`, Task 04, `customer_service.py`, and batch service/API tests
- Merge owner/status: `Stage 5 persistent LLM` / `not-started`

## Integration Preflight

- Merge-base with `main`: `837ccbc` (no upstream divergence)
- Feature code commits ahead: 12 (`837ccbc..5b66165`); artifact commits at Stage 5 intake: 14 (`837ccbc..f25e5ca`)
- Likely merge conflicts: low (README/docs content merges only)
- Post-merge checks: Alembic 0010, `pytest backend/tests -q`, mobile suite, APK smoke

## Exact Next Action

Start a fresh Stage 3 SLM in `/Users/abhishek/python_venv/khata_app-upgrade`. Verify branch `codex/khata-invoice-collections-backup-analytics`, read `STATE.md`, `05-final-review.md`, and `02-plan/04-batch-khata-collections.md`, then implement shared PostgreSQL serialization for single and batch collection writes with real concurrent regression tests. Do not merge.

Last updated: 2026-06-14 IST (Stage 5 returned to Stage 3)
