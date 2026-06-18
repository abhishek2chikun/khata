# Context Refresh: 2026-06-18

Workflow schema: five-stage-v1

## Mode

**context-refresh** — Stage 1 input contained no concrete neutral discovery brief (template placeholders only). Project memory reconciled to current `main` HEAD without opening a new feature cycle.

## Repository Identity

| Field | Value | Status |
|---|---|---|
| Root | `/Users/abhishek/python_venv/khata_app` | confirmed |
| Remote | `git@github.com:abhishek2chikun/khata.git` | confirmed |
| Branch | `main` | confirmed |
| HEAD | `862dc3468005f7e3bd87881090f0ee38f9abe47d` | confirmed |
| Planning checkout | `/Users/abhishek/python_venv/khata_app` on `main` | confirmed |
| Integration target | `main` | confirmed |
| Layout | `backend/` (FastAPI), `mobile/` (Flutter), `docs/`, `tools/` | confirmed |

## Worktree Inventory

| Path | Branch | HEAD | Ancestor of `main` |
|---|---|---|---|
| `/Users/abhishek/python_venv/khata_app` | `main` | `862dc34` | yes (integration checkout) |
| `/Users/abhishek/python_venv/khata_app-upgrade` | `codex/khata-invoice-collections-backup-analytics` | `1d8e5dc` | yes (historical feature worktree) |
| `.worktrees/invoice-pdf-sharing-buyer-link` | `feature/invoice-pdf-sharing-buyer-link` | `9ba5d49` | yes |
| `.worktrees/offline-first-local-mode` | `feature/offline-first-local-mode` | `9280ea0` | yes |
| `.worktrees/wholesaler-business-workflow` | `feature/wholesaler-business-workflow` | `707d8e6` | yes |

All feature-branch worktree HEADs are ancestors of current `main`; none are ahead of integration.

## Prior Cycles Read

| Cycle | Relationship | Verdict/SHA | Artifacts read |
|---|---|---|---|
| `khata-app-baseline` | lineage root | accepted `de7318a` | registry row only |
| `20260614-invoice-collections-backup-analytics` | last accepted | accept-with-followups; integrated `1d8e5dc` | `STATE.md`, `05-final-review.md`, registry |

## Prior Knowledge Freshness

| Claim/decision | Source/SHA | Status | Evidence checked | Consequence |
|---|---|---|---|---|
| Local mode primary runtime | final review `1d8e5dc` | carry-forward-confirmed | `PROJECT_CONTEXT`, `AppDependencies` | preserve |
| Drift/backup schema 10 | upgrade cycle | carry-forward-confirmed | `local_database.dart:363` | preserve |
| Alembic head `0009` only | PROJECT_CONTEXT pre-refresh | superseded | `0010_product_hsn_and_unit_price_precision.py` | update memory |
| Integrated code SHA `1d8e5dc` is latest `main` | INDEX pre-refresh | superseded | `main` at `862dc34` | post-merge commits exist |
| Mobile tests 458 passed | agent.md | superseded | `flutter test test` → **474 passed** | update baseline |
| Backend pure 55 passed | prior refresh | superseded | **56 passed** | update baseline |
| Physical Drive unverified | final review | carry-forward-confirmed | no device run | release blocker |
| API collection concurrency defect | final review | carry-forward-confirmed | `customer_service.py` not re-audited | server-mode blocker |
| A5 threshold ≤10 | agent.md | contradicted | `invoice_pdf_service.dart:12` uses ≤15 | doc drift |
| Pre-confirm PDF preview | not in accepted cycle | carry-forward-confirmed | commit `862dc34`, tracked files | new capability on `main` |
| Catalog v3 rebuild | agent.md progress note | carry-forward-provisional | uncommitted `products.xlsx`, catalog JSON | WIP, not integrated |

## Repository Delta Since Last Accepted Integration (`1d8e5dc..862dc34`)

Commits on `main`:

1. `b971df0` — docs(workflow): seal local-mode integration review
2. `9dfe1cf` — fix(mobile): harden Drive backup and polish workflows
3. `240f491` — fix(mobile): verify Drive restores and cleanup failures
4. `f4bedfa` — feat(mobile): polish all local app workflows (broad UI polish + screenshot artifacts)
5. `862dc34` — Add pre-confirm invoice PDF preview and simplify place-of-supply defaults

Notable post-integration capabilities:

- **Invoice PDF preview**: `invoice_preview_builder.dart`, `invoice_pdf_preview_screen.dart`, `printing` dependency, backend/local place-of-supply default alignment
- **Drive hardening**: restore verification and cleanup failure handling (still adapter-tested, not device-proven)
- **UI polish**: analytics, collections, buyers, customers, login, backup screens

## Uncommitted Work (preserved, not part of verified HEAD)

| Path | Nature |
|---|---|
| `data/source/products.xlsx` | catalog source update |
| `mobile/assets/catalog/preinstalled_catalog.json` | regenerated asset |
| `tools/build_preinstalled_catalog.py` | build script changes |
| `Invoices (3).xlsx` (untracked) | source workbook reference |
| `docs/hybrid-supabase-architecture.html` (untracked) | external architecture sketch; not verified product scope |

## Verification Run In This Refresh

| Purpose | Command | Verified now? | Result |
|---|---|---|---|
| Backend pure tests | `PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q` | yes | 56 passed |
| Mobile full suite | `(cd mobile && flutter test test)` | yes | 474 passed |
| PostgreSQL integration | `backend/tests` with Postgres | no | not attempted |
| Physical Drive matrix | device OAuth/upload/restore | no | not attempted |
| Release APK build | `flutter build apk --release` | no | not attempted |

## Reconciliation Notes

- Accepted cycle integration SHA `1d8e5dc` remains the reviewed feature merge point; `main` has five additional commits through `862dc34` that are code-verified by tests but not workflow-reviewed.
- Prior canonical worktree `khata_app-upgrade` is historical at `1d8e5dc`; planning should use `/Users/abhishek/python_venv/khata_app` on `main`.
- No neutral scope was supplied; Stage 2 must not start until a concrete brief is provided.

## Future Worktree Policy (for next feature cycle)

- Stage 2 commits discovery/planning artifacts on integration checkout (`main`).
- Stage 3 creates feature branch + worktree from clean planning baseline.
- Naming convention: `feature/<YYYYMMDD-scope-slug>` or `codex/<scope-slug>`; worktree at `.worktrees/<scope-slug>` or sibling directory.
- Unrelated uncommitted work (current catalog WIP) must not be moved into a future cycle branch without explicit user action.

## Exact Next Action

Await a neutral discovery brief, then rerun Stage 1 as `new-cycle` (or `follow-up-cycle` if explicitly tied to a closed cycle scope).
