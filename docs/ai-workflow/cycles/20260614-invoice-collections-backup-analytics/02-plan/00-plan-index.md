# Implementation Plan Index: Khata Invoice, Collections, Backup, And Analytics Upgrade

Objective: Deliver AC1-AC14 with API/local parity, migration safety, and production-like evidence.

Cycle/lineage: `20260614-invoice-collections-backup-analytics` / parent `khata-app-baseline`

Repository baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Integration target branch: `main`

Feature branch: `codex/khata-invoice-collections-backup-analytics`

Worktree name/ID: `khata_app-upgrade`

Canonical worktree: `/Users/abhishek/python_venv/khata_app-upgrade`

Scope/non-goals: See `../02-design.md`. Do not implement invoice-list search, regenerate identifiers, guess HSN, rewrite history, add advance credit, commit secrets, or merge.

Execution model: one fresh SLM context per task. Tasks 03, 04, and 06 may start after Task 02, but use separate contexts and do not edit shared schema/contracts concurrently.

## Locked Decisions

- HSN separate/non-unique; stable item identity; GST write gate.
- Integral new quantities; three-decimal unit prices; two-decimal totals.
- New discounts zero; legacy discount history retained.
- Cash fully paid; Credit unpaid/partial.
- Seven-day atomic batch collections; zero/blank means no entry.
- Encrypted visible-folder Drive backups, secure password, best-effort 02:00, 30 retained.
- Owner KPI/trend dashboard; low stock removed only from analytics UI.

## Requirements Coverage

| AC/invariant | Task(s) | Implementation evidence expected | Verification | Runtime scenario |
|---|---|---|---|---|
| AC1 stable catalog identity + HSN | 02 | catalog v2 JSON/build/seeder | script/unit identity comparison | fresh + upgraded local DB |
| AC2 HSN GST gate | 02,03 | API/local validators + snapshot | quote/create tests | GST and non-GST create |
| AC3 integral new quantity/history | 02,03 | validators, unchanged decimal columns | migration + service/widget tests | fractional reject, legacy read |
| AC4 price precision | 02,03 | Numeric scale 3 + decimal normalization | paired backend/local fixture | `3.0075 -> 3.008` |
| AC5 product search | 03 | searchable picker | widget test with 1,199 fixtures | device typing/selection |
| AC6 non-GST omission | 03 | conditional controls/PDF | widget/PDF text tests | non-GST A5/A4 |
| AC7 Cash/Credit truth | 03 | derived internal state | controller/service/ledger tests | cash, unpaid, partial |
| AC8 PDF alignment | 03 | revised four variants | page/text/render review | 9/10/15/16-row boundaries |
| AC9 batch collections | 04 | batch DTO/service/router/local/UI | atomicity/idempotency tests | 1-day and 7-day grid |
| AC10 Drive behavior | 01,05 | adapters, upload verify, scheduler | fake Drive/WorkManager + device | foreground + background/catch-up |
| AC11 restore digest | 05 | download + existing import | seeded digest round trip | configured Drive restore |
| AC12 analytics | 06 | additive DTO/service/UI | backend/local parity + widgets | presets/custom/empty/error |
| AC13 compatibility | 02,03,05 | v9 restore, legacy invoice fixtures | migration/backup/PDF tests | upgrade existing app data |
| AC14 full gates | 07 | completed logs/artifacts | commands and hashes | release APK/device matrix |

## Task/Slice Order

| ID | Outcome | Depends on | Parallel? | Risk | Plan file |
|---|---|---|---|---|---|
| 01 | Preflight and platform feasibility proof | none | no | high | `01-platform-feasibility.md` |
| 02 | Contracts, migrations, catalog, compatibility | 01 | no | high | `02-contracts-migrations-catalog.md` |
| 03 | Invoice creation, settlement UX, and PDFs | 02 | no | high | `03-invoice-creation-and-pdfs.md` |
| 04 | Atomic seven-day batch collections | 02 | yes with 05/06 | high | `04-batch-khata-collections.md` |
| 05 | Encrypted Drive backup and scheduling | 01,02 | yes with 04/06 | high | `05-google-drive-backup.md` |
| 06 | Owner analytics contracts and dashboard | 02 | yes with 04/05 | medium | `06-owner-analytics.md` |
| 07 | Cross-task integration and release evidence | 03-06 | no | high | `07-integration-and-handoff.md` |

## Baseline Commands

```bash
git branch --show-current
git rev-parse HEAD
git status --short
.venv/bin/python -m pytest backend/pure_tests -q
(cd mobile && flutter test test)
pg_isready -h localhost -p 55432
```

Expected baseline: correct feature branch, start SHA `837ccbc0...`, clean except cycle docs, backend pure tests green, mobile suite green, PostgreSQL availability recorded rather than assumed.

## Cross-Task Integration

- Task 02 owns all shared schemas, migrations, generated Drift code, catalog JSON, and backup versioning. Later tasks consume those contracts and must not redesign them.
- Task 03 owns invoice controller/screens/PDFs and may adjust invoice-focused tests only after Task 02 lands.
- Task 04 owns customer batch DTO/router/service/local service/screen. It must reuse customer ledger primitives but add a true atomic service boundary.
- Task 05 owns backup/Drive/background code and dependency lockfile changes after Task 01 approves feasibility.
- Task 06 owns analytics DTO/service/screen/chart changes and must retain legacy response fields.
- Task 07 resolves integration conflicts, generated files, documentation, and evidence; it must not weaken tests to obtain green results.

## Runtime And Release Evidence

- Render and inspect GST/non-GST A5/A4 PDFs including double-digit serials and historical discounts.
- Exercise 1-day and 7-day collection grids, zero cells, retries, overpayment conflict, and refreshed balances.
- On a configured Android device, prove Google sign-in, foreground upload, scheduled registration, catch-up, listing, wrong-password restore safety, successful restore, and restart persistence.
- Build a local-mode release APK and record size/SHA-256. Do not call it distribution-ready while app ID/signing remain unresolved.

## Rollout/Rollback

- Take a verified encrypted backup before installing the migrated APK on real data.
- Migrate API before API-mode clients. Local migration runs on first launch.
- Retain the prior APK only as an emergency artifact; do not reinstall an older schema-9-only build over schema 10 data.
- Drive pruning occurs only after verified upload, so rollback always has previous backups.

## Strong-Model/Human Review Gates

1. Task 01 feasibility verdict before dependency-heavy Drive work.
2. Task 02 migration/financial-contract review before UI tasks.
3. Task 04 atomicity/idempotency review before runtime testing.
4. Task 05 security/privacy review and physical-device evidence.
5. Task 07 final baseline-to-head review; Stage 5 alone decides merge.

## Known Plan Assumptions

- Business date follows device/local date; no separate company timezone setting exists.
- Google Cloud OAuth configuration is supplied outside git for runtime proof.
- PostgreSQL may require starting the project test database; absence is an environment blocker, not permission to omit DB evidence.

## Plan Self-Review Result

Every AC maps to one owner task and an independent proof. Shared contract ownership is serialized. No production behavior, migration rule, failure policy, package family, or acceptance gate is delegated to the SLM.
