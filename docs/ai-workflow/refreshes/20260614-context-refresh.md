# Context Refresh: 2026-06-14

## Mode

**context-refresh** — no concrete feature objective was supplied in the Stage 0 input (template placeholders empty). Project memory reconciled to current `main` HEAD without opening a new feature cycle.

## Repository Identity

| Field | Value | Status |
|---|---|---|
| Root | `/Users/abhishek/python_venv/khata_app` | confirmed |
| Remote | `git@github.com:abhishek2chikun/khata.git` | confirmed |
| Branch | `main` | confirmed |
| HEAD | `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6` — "updates, data dump, prod testing" | confirmed |
| Worktree | clean | confirmed |
| Layout | `backend/` (FastAPI), `mobile/` (Flutter), `docs/` | confirmed |

## Prior Cycle Selected

**khata-app-baseline** (`docs/ai-workflow/khata-app-baseline/`) — only existing workflow cycle.

- Closed at Stage 5 with verdict: `code-ready-for-phone-testing; production-release-blocked`
- Final reviewed SHA: `de7318a9f1ec5a47d40b6642a8127879d2aa9f34`
- Artifacts read: `STATE.md`, `00-discovery.md`, `05-final-review.md`, `06-local-production-audit.md`

Cycles ignored: none other exist.

## Prior Knowledge Freshness

| Claim/decision | Source/as-of SHA | Current status | Evidence checked | Planning consequence |
|---|---|---|---|---|
| GST/non-GST invoicing with `gst_flag` | baseline `de7318a` | carry-forward-confirmed | models, pure_tests, mobile tests | reuse contracts |
| Adaptive PDF 4 variants | baseline Stage 5 `de7318a` | carry-forward-confirmed | `invoice_pdf_service.dart`, tests | reuse renderer rules |
| A5 threshold ≤10 lines | baseline discovery/README | superseded | `invoice_pdf_service.dart:10` uses ≤15 + fit fallback | update docs in future cycle if touching docs |
| Daily balance excludes archived | baseline Stage 5 fix | carry-forward-confirmed | `balance_share_service.dart`, tests | preserve behavior |
| Backup schema version 8 | baseline discovery | superseded | `local_database.dart` schema 9, README | use version 9 in new work |
| Mobile tests 376 passed | baseline Stage 5 | superseded | `flutter test test` → **389 passed** at `837ccbc` | use 389 as current baseline |
| Stage 4/5 fixes uncommitted | baseline STATE | superseded | `837ccbc` committed audit/PDF/backup/catalog changes | no dirty-worktree concern |
| PostgreSQL integration verified | baseline Stage 4/5 | contradicted | `pg_isready` no response | still a verification gap |
| Physical share/backup verified | baseline Stage 5 | unknown | not re-run on device in refresh | still release blocker |
| Example Android app ID | baseline audit | carry-forward-confirmed | `build.gradle.kts` | still release blocker |
| Preinstalled product catalog | not in baseline final review | carry-forward-confirmed | README, `preinstalled_catalog.json`, seeder tests | new reusable capability since `de7318a` |

## Repository Delta Since Accepted Cycle (`de7318a..837ccbc`)

Single commit `837ccbc` (+44 files). Notable changes:

- **Preinstalled catalog**: `mobile/assets/catalog/preinstalled_catalog.json`, `LocalProductCatalogSeeder`, `tools/build_preinstalled_catalog.py`, source `data/source/products.xlsx`
- **Backup file transfer**: `LocalBackupTransferService`, backup screen wiring, tests
- **PDF/layout refinements**: further `invoice_pdf_service.dart` consolidation
- **Local analytics fix**: taxable revenue / canonical profit
- **Invoice list UX**: GST toggle from list route, payment state display
- **Workflow artifacts committed**: Stage 4/5 reports, return packet, prod audit, STATE updates
- **README expanded**: catalog, schema v9, backup compatibility

## Verification Run In This Refresh

| Purpose | Command | Verified now? | Result |
|---|---|---|---|
| Backend pure tests | `.venv/bin/python -m pytest backend/pure_tests -q` | yes | 47 passed |
| Mobile full suite | `(cd mobile && flutter test test)` | yes | 389 passed |
| PostgreSQL availability | `pg_isready -h localhost -p 55432` | yes | no response |
| CI presence | glob `.github/workflows` | yes | none found |

## Documentation Drift Reconciled

- Created missing project registry: `docs/ai-workflow/INDEX.md`
- Created rolling context: `docs/ai-workflow/PROJECT_CONTEXT.md`
- Preserved closed cycle `khata-app-baseline/STATE.md` unchanged (historical)
- Flagged stale ≤10-line PDF wording in README and `mobile/agent.md`

## Stale Local Branches (not checked out)

| Branch | SHA | Note |
|---|---|---|
| `feature/offline-first-local-mode` | `9280ea0` | likely merged/superseded by `main` |
| `feature/wholesaler-business-workflow` | `707d8e6` | likely merged/superseded by `main` |
| `feature/invoice-pdf-sharing-buyer-link` | `9ba5d49` | merged via PR #3 per baseline discovery |

## Next Action

Provide a concrete feature objective (paste or describe the desired outcome). Stage 0 will then open a **new linked cycle** under `docs/ai-workflow/cycles/<YYYYMMDD>-<feature-slug>/` with `STATE.md` and `00-discovery.md`.

Suggested near-term objectives if choosing release path:

1. Permanent Android app ID + release keystore + signed APK build
2. Physical-device verification matrix for share/backup/persistence
3. PostgreSQL integration test restoration on CI or local Docker

Do **not** resume `khata-app-baseline`; it is closed. New work should link it as parent/relevant cycle.
