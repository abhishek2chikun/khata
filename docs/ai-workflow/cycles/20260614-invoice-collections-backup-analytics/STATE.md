# Workflow State

Cycle ID: `20260614-invoice-collections-backup-analytics`

Parent cycle: `khata-app-baseline`

Objective: Upgrade product/HSN and invoice contracts, invoice entry/PDF UX, batch customer collections, encrypted Google Drive backups, and owner analytics while preserving local/API parity and historical accounting data.

Workflow schema: five-stage-v1

Current stage: `3-implementation`

Stage status: `in_progress`

Current task: `04-batch-khata-collections` (complete)
Current HEAD: `97b100e6a520a87aa33bb786b5cb9a6ed369351a`

## Stage 1 Repair

The supplied Stage 1 artifact was a context refresh with no objective-specific discovery. Stage 2 repaired the minimum missing context by inspecting the live contracts, catalog workbook, invoice UI/PDFs, customer ledger, backup skeleton, analytics services, and current tests. The approved design is recorded in this cycle and implementation is grounded at the baseline below.

## Git And Worktree Contract

Integration target branch: `main`

Feature branch: `codex/khata-invoice-collections-backup-analytics`

Worktree name/ID: `khata_app-upgrade`

Canonical worktree absolute path: `/Users/abhishek/python_venv/khata_app-upgrade`

Worktree baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Worktree status: `task-04-complete`

Merge owner: Stage 5 persistent LLM

Merge authorization: required

Merge status: not-started

The primary checkout contains user-owned untracked workflow refresh files and must remain untouched.

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

Exact first task: `02-plan/01-platform-feasibility.md`

## High-Risk Gates

- No financial column may be destructively rewritten during migration.
- API and local quote/create paths must agree on HSN, quantity, discount, payment, and precision rules.
- Batch collection failure must leave every customer balance unchanged.
- Restore must validate schema/compatibility before replacing local data.
- Drive credentials and tokens must never be committed.
- Physical-device Google OAuth/background/restore evidence is required before AC10/AC11 can be marked proven.

## Acceptance Criteria

AC1-AC14 are fully mapped in `02-plan/00-plan-index.md`. Stage 3 records implementation evidence in `03-implementation-log.md`; Stage 4 creates `04-validation-report.md` and `04-return-packet.md`.

## Context Topology

- Persistent LLM lane: `paused-after-stage-2`
- Current owner: `Stage 3 fresh SLM`
- Next owner: `Stage 4 fresh validation agent` (after Stage 3 complete)
- Owner after Stage 3: `Stage 4 fresh validation agent`
- Minimum read set: this file, `02-design.md` sections referenced by the assigned task, `02-plan/00-plan-index.md`, and exactly one assigned task packet.
- Merge owner/status: `Stage 5 persistent LLM` / `not-started`

## Stage 2 Handoff

- Persistent LLM lane: `paused-after-stage-2`
- No production code has been implemented in this cycle.
- The only worktree changes are Stage 2 workflow artifacts.
- Stage 3 must verify branch/worktree identity and baseline before editing.
- Stage 3 begins with Task 01 and must stop at its feasibility gate if package/platform requirements cannot be met without reopening design.

Last updated: 2026-06-14 IST (Task 04 batch collection grid complete)
