# AI Workflow Cycle Registry

Workflow schema: five-stage-v1

Project: Internal Billing and Khata System (`khata_app`)

Workflow root: `docs/ai-workflow/`

Current repository HEAD: `862dc3468005f7e3bd87881090f0ee38f9abe47d`

Active cycle: none

Last accepted/reviewed cycle: `20260614-invoice-collections-backup-analytics` (integrated at `1d8e5dc`; release followups open)

Last updated: 2026-06-18 IST

## Cycle Registry

| Cycle ID | Type | Objective/scope | Status | Baseline SHA | Final reviewed feature SHA | Integration SHA/status | Areas/tags | Lineage | Artifact path |
|---|---|---|---|---|---|---|---|---|---|
| `khata-app-baseline` | first-cycle | GST/non-GST invoicing, adaptive PDFs, sharing, local production audit | accepted-with-followups | `7699ae6` | `de7318a` | historical / superseded by upgrade cycle | invoicing, pdf, sharing | none | `khata-app-baseline/` |
| `20260614-invoice-collections-backup-analytics` | new-cycle | HSN/precision, invoice UX/PDF, batch collections, Drive backup, owner analytics | accepted-with-followups; merged-and-verified; release-unverified | `837ccbc` | `5b66165` | `1d8e5dc` merged into `main`; post-merge commits through `862dc34` | hsn, collections, drive, analytics, local-mode | `khata-app-baseline` | `cycles/20260614-invoice-collections-backup-analytics/` |

## Active Cross-Cycle Blockers

- Physical Android Google OAuth, WorkManager, Drive backup, and restore remain unverified (AC10/AC11).
- Production Android application ID and signing remain unresolved.
- API collection concurrency defect in `backend/app/services/customer_service.py` must be repaired before any future server-mode deployment.

## Deferred Opportunities

- Production Android identity/signing configuration.
- Physical-device Drive backup/restore evidence matrix.
- API collection concurrency repair with PostgreSQL-backed proof.
- Catalog v3 rebuild from corrected source workbook (uncommitted WIP on `main`).

## Superseded Cycles/Decisions

- `khata-app-baseline` A5 threshold ≤10 lines: superseded by code using ≤15 lines (`invoice_pdf_service.dart`).
- `khata-app-baseline` backup schema 8/9: superseded by Drift/backup schema 10.
- Prior canonical worktree `/Users/abhishek/python_venv/khata_app-upgrade` at `1d8e5dc`: historical; `main` has advanced to `862dc34`.

## Planning Checkout And Worktree Policy

- Integration target branch: `main`
- Planning checkout absolute path: `/Users/abhishek/python_venv/khata_app`
- Proposed feature branch convention: `feature/<scope-slug>` or `codex/<scope-slug>`
- Proposed worktree locations: `.worktrees/<scope-slug>` (in-repo) or sibling `/Users/abhishek/python_venv/khata_app-<scope-slug>`
- Feature branch/worktree creation: pending Stage 3 only

### Registered Worktrees (as-of `862dc34`)

| Path | Branch | HEAD | Ancestor of `main` |
|---|---|---|---|
| `/Users/abhishek/python_venv/khata_app` | `main` | `862dc34` | yes (current) |
| `/Users/abhishek/python_venv/khata_app-upgrade` | `codex/khata-invoice-collections-backup-analytics` | `1d8e5dc` | yes |
| `/Users/abhishek/python_venv/khata_app/.worktrees/invoice-pdf-sharing-buyer-link` | `feature/invoice-pdf-sharing-buyer-link` | `9ba5d49` | yes |
| `/Users/abhishek/python_venv/khata_app/.worktrees/offline-first-local-mode` | `feature/offline-first-local-mode` | `9280ea0` | yes |
| `/Users/abhishek/python_venv/khata_app/.worktrees/wholesaler-business-workflow` | `feature/wholesaler-business-workflow` | `707d8e6` | yes |
