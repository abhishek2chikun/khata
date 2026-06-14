# AI Workflow Cycle Registry

Project: Internal Billing and Khata System (`khata_app`)

Workflow root: `docs/ai-workflow/`

Current repository baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Active cycle: `20260614-invoice-collections-backup-analytics`

## Cycle Registry

| Cycle ID | Objective | Status | Baseline | Parent | Artifact path |
|---|---|---|---|---|---|
| `khata-app-baseline` | GST/non-GST invoicing, adaptive PDFs, sharing, local production audit | accepted-with-followups | `7699ae6` | none | `khata-app-baseline/` |
| `20260614-invoice-collections-backup-analytics` | HSN/precision, invoice UX/PDF, batch collections, Drive backup, owner analytics | Stage 5 accepted-with-followups; awaiting integration | `837ccbc0`; reviewed code `5b66165` | `khata-app-baseline` | `cycles/20260614-invoice-collections-backup-analytics/` |

## Canonical Active Worktree

- Branch: `codex/khata-invoice-collections-backup-analytics`
- Path: `/Users/abhishek/python_venv/khata_app-upgrade`
- Integration target: `main`
- Merge owner/status: Stage 5 persistent LLM / authorized, awaiting safe worktree preflight

## Active Followups

- Physical Android Drive backup/restore evidence unavailable.
- Production Android application ID/signing unresolved.
- API collection concurrency must be repaired before future server-mode deployment.

Final review: `cycles/20260614-invoice-collections-backup-analytics/05-final-review.md`

Last updated: 2026-06-14 IST
