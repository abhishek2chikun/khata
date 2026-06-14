# Stage 4 Return Packet — Khata Invoice/Collections/Backup/Analytics Upgrade

## Resume Instructions

Read in order:
1. `STATE.md`
2. `02-llm-review-anchor.md`
3. This return packet
4. `04-validation-report.md`
5. `git log 837ccbc..HEAD` and `git diff 837ccbc..HEAD`

Do not merge to `main` until Stage 5 authorization.

## Identity And Final State

- Objective: HSN/precision contracts, searchable invoices, Cash/Credit UX, batch collections, encrypted Drive backup, owner analytics
- Worktree: `/Users/abhishek/python_venv/khata_app-upgrade`
- Branch: `codex/khata-invoice-collections-backup-analytics`
- Baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
- Stage 3 HEAD: `c07b3ef54e78ec6b9587bd7b16c7f0f30c84da2d` (`docs(workflow): hand off khata upgrade validation`)
- Target: local-mode Android APK (`DATA_MODE=local`); API mode needs Postgres on `:55432`
- Merge status: **not-started** (Stage 5 owner)

## Executive Delta

- Tasks 01–06 landed contracts, invoice UX/PDFs, atomic batch collections, Drive orchestration, owner analytics dashboard.
- Task 07 integrated slices, fixed signed stock-delta validation, refreshed stale tests, added 5 cross-slice regression tests, and recorded validation artifacts.
- Drift/backup schema **10**; Alembic **0010** adds HSN and three-decimal unit prices; catalog v2 includes nullable HSN.
- Mobile: **458** tests pass; release APK builds (66.5 MB).
- Backend pure: **55** tests pass.
- **Blocked:** full `backend/tests` Postgres suite; AC10 physical Drive OAuth/background evidence.

## Commit Ledger (Stage 3)

| Commit | Task | Intent |
|---|---|---|
| `a66aae4` | 01 | Drive/background dependency feasibility |
| `d12306c` | 02 | HSN/precision contracts + migrations |
| `129f7e7` | 03 | Searchable invoices + compliant PDFs |
| `97b100e` | 04 | Atomic daily collection grid |
| `668a0b7` | 05 | Encrypted Google Drive recovery |
| `0bcfa3d` | 05 | Drive orchestration implementation |
| `efd9a59` | 04 docs | Task 04 SHA record |
| `ecf032c` | 05 docs | Task 05 SHA record |
| `a69f093`, `c07b3ef` | 07 | Integration fixes + validation handoff |

## Acceptance Coverage Summary

| AC | Status |
|---|---|
| AC1–AC9, AC12–AC13 | pass or pass-with-gaps (automated) |
| AC10 | **unverified** (no configured physical device) |
| AC11 | pass-with-gaps (fake Drive digest; no physical restore) |
| AC14 | pass-with-gaps (mobile/pure/APK green; Postgres blocked) |

## Artifacts

| Artifact | Value |
|---|---|
| Release APK path | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| APK size | 66.5 MB |
| SHA-256 | `3de1bc6a121f294305f53daccb50c69f00ccfae63507b1f766757139ecfb8542` |
| Mobile tests | 458 passed |
| Backend pure tests | 55 passed |
| Backend integration tests | 0 run (Postgres down) |

## Unresolved Blockers For Stage 4

1. Start PostgreSQL on `:55432` and run full `backend/tests` + Alembic upgrade/downgrade row compare.
2. Physical Android: Google sign-in, foreground upload, scheduled/catch-up backup, wrong-password restore safety, successful restore + restart persistence.
3. Optional: emulator invoice search/GST matrix, seven-day collection grid smoke, manual PDF visual review.

## First Validation Sequence

```bash
cd /Users/abhishek/python_venv/khata_app-upgrade
git branch --show-current
git rev-parse HEAD
docker start khata-postgres  # or create per README
pg_isready -h localhost -p 55432
PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q
(cd backend && BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' ../.venv/bin/python -m alembic upgrade head)
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
shasum -a 256 mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Verdict For Stage 5

Ready for senior review **after** Postgres integration tests pass and AC10/AC11 device gaps are either proven or explicitly waived. Do not reinstall schema-9-only APK over schema-10 data.
