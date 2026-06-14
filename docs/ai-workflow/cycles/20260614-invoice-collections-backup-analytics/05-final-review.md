# Final Senior Review

## Verdict

**fix-required**

The feature is not merge-eligible. Most local-mode behavior is implemented and the focused mobile/backend-pure evidence is healthy, but AC9 is contradicted under concurrent API writes. PostgreSQL migration/integration tests and physical-device Drive evidence also remain unavailable. No merge authorization is recorded.

## Executive Reasoning

The delivered product substantially matches the approved scope: HSN and precision contracts, searchable invoice entry, GST/non-GST document behavior, Cash/Credit settlement, a seven-day collection grid, encrypted Drive orchestration, and owner analytics are present. Blank or zero collection cells correctly create no transaction, so customers may have zero collection on any selected date.

The blocking defect is the API collection concurrency contract. `create_collection_batch` checks batch idempotency before writing but has no batch-level unique key or transaction lock. Two concurrent requests using one batch request ID with different non-overlapping entries can both commit. It locks customer rows, but `create_collection` does not take the same lock, so a concurrent single collection can also invalidate the batch balance check and permit over-collection. Task 04 explicitly required serialization against concurrent writes and concurrency tests.

## Objective, Scope, And Non-Goals Reconstructed

- Objective: practical compliant invoicing, atomic daily customer collections, encrypted Drive recovery, and owner-grade analytics while preserving API/local parity and historical data.
- Scope: AC1-AC14 from `02-design.md`, including API and local collection atomicity/idempotency.
- Non-goals preserved: invoice-list search, guessed HSN, rewritten history, advance credit, exact alarms, iOS scheduling, production app-ID/signing changes, and committed OAuth secrets.

## Evidence And Repository State

- Baseline/integration target: `main` at `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`.
- Canonical worktree/branch: `/Users/abhishek/python_venv/khata_app-upgrade`, `codex/khata-invoice-collections-backup-analytics`.
- Current artifact HEAD at review intake: `f25e5cadc9b6db16a71032ed6003aa6e8ea2e435`.
- Last code-changing HEAD: `5b6616502efdb511352e3124894ffcb643842535`.
- Commits after `5b66165` are workflow documentation only.
- Feature worktree had untracked `.venv`, `docs/ai-workflow/INDEX.md`, and `PROJECT_CONTEXT.md`; primary checkout had unrelated untracked workflow files. Neither checkout met the clean merge gate.
- Stage 4 did not validate another worktree, but its artifacts inconsistently called `2399fae`, `5b66165`, and later `f25e5ca` the final SHA. This review distinguishes code SHA from artifact SHA.

## Requirement/Decision Truth Table

| Requirement/decision | Intended behavior | Actual evidence | Status | Defect source |
|---|---|---|---|---|
| AC1-AC4 catalog/HSN/quantity/precision | Stable identities, GST HSN gate, integral new quantities, 3dp prices | Migrations/contracts, pure tests, focused mobile tests | proven except live Alembic | environment |
| AC5 searchable picker | Search 1,199 products by approved fields | widget fixture | partial | verification |
| AC6-AC8 invoice UX/PDF | No GST fields in non-GST; compliant aligned variants | widget/PDF tests; no manual render review | partial | verification |
| AC7 Cash/Credit | Cash paid; Credit unpaid/partial | controller and cross-slice tests | proven | none |
| AC9 batch collections | Atomic, idempotent, zero-safe, no overpay under concurrency | zero omission/local transaction tests pass; API race exists | contradicted | implementation, verification |
| AC10 Drive operations | Real OAuth/upload/schedule/catch-up/retention | fake adapters only | unverified | environment, verification |
| AC11 restore digest | Identical digest after restore | fake Drive/local digest tests | partial | verification |
| AC12 analytics | Canonical KPIs/trends/rankings | parity fixtures and widget tests | partial | environment |
| AC13 compatibility | Historical invoices/backups readable | v9 restore and historical discount tests | proven | none |
| AC14 full gates | Backend integration, mobile, migrations, analysis, release build | pure/focused mobile pass; Postgres blocked | partial | environment |

## Findings

| Severity | Defect source | Evidence/location | Impact | Required action |
|---|---|---|---|---|
| Critical | Implementation | `backend/app/services/customer_service.py:346` `create_collection_batch` | Same batch request ID with concurrent disjoint payloads can both commit; idempotency is not guaranteed | Add durable batch-level serialization/uniqueness and a real concurrent PostgreSQL conflicting-retry test |
| Critical | Implementation | `backend/app/services/customer_service.py:211` and `:376` | Batch locks customer rows, but single collection writes do not; concurrent single/batch collection can overpay | Use one shared per-customer serialization contract for every collection write and prove no negative balance under concurrency |
| Important | Environment/verification | PostgreSQL `localhost:55432` unavailable; Docker daemon unavailable | Alembic upgrade/downgrade and backend integration suite are unproven | Restore PostgreSQL and run the complete migration/backend gate |
| Important | Verification | Physical Android Google OAuth/Drive/WorkManager/restore matrix absent | AC10 and physical AC11 are unproven | Run the planned device matrix with external OAuth configuration |
| Minor | Implementation | `mobile/lib/backup/encrypted_drive_backup_orchestrator.dart:113` | Missing schema metadata is displayed as current schema, which can mislead restore selection | Represent unknown schema explicitly or derive it after package inspection |
| Minor | Workflow | `STATE.md`, return packet, validation report, implementation log | Final/code HEAD labels became stale or contradictory | Track validated code SHA and artifact HEAD separately |

## Product Correctness

The local product flow is coherent and zero/blank daily collection cells behave as requested. The API collection workflow is not safe enough for financial production use because its concurrency boundary is incomplete. This is not a cosmetic edge case: retries and simultaneous collection entry are exactly where idempotency and balance invariants matter.

## Architecture And Tradeoffs

The overall boundaries follow the approved design. Invoice rules live in services, local/API implementations remain parallel, backup encryption stays in `LocalBackupService`, and analytics calculations remain service-owned. The batch implementation under-engineered its database coordination: row locking only in one write path is not a system-wide serialization contract, and notes are not a durable unique batch identity.

## Code And Contract Quality

Stage 4's `5b66165` fixes are accepted: API HSN snapshot persistence, canonical batch hash ordering, batch UI request-ID invalidation/conflict reload, and backup error redaction are correct and covered by focused tests. No production code was changed during Stage 5 because the required concurrency repair needs PostgreSQL-backed proof and must coordinate both batch and single collection paths.

## Accepted/Rejected/Missed Stage-4 Findings

- Accepted: all four fixed Stage 4 findings and the open PostgreSQL/device evidence gaps.
- Accepted as non-blocking: restore download metadata hash hardening and unknown schema metadata handling.
- Rejected: Stage 4's `pass-with-minor-issues` severity. AC9 is contradicted, not a minor evidence gap.
- Missed: concurrent conflicting payloads sharing a batch request ID; concurrent single collection versus batch balance validation; missing planned concurrency test.

## Fresh Commands And Results

| Command/scenario | Scope | Result | What it proves |
|---|---|---|---|
| `PYTHONPATH=backend .venv/bin/python -m pytest backend/pure_tests -q` | backend pure | 56 passed | pure domain regressions remain green |
| focused Flutter collection/backup/PDF/cross-slice suite | highest-risk local paths | 42 passed | zero-safe local batch, backup digest, PDFs, and cross-slice behavior |
| `pg_isready -h localhost -p 55432` | PostgreSQL | no response | integration environment unavailable |
| `docker ps` / Docker launch wait | environment recovery | daemon unavailable after wait | backend integration could not be recovered in review |
| `git diff --check 837ccbc0..HEAD` | diff hygiene | pass | no whitespace errors in committed delta |
| code inspection of collection transaction paths | concurrency contract | fail | shared serialization and durable batch identity are absent |

## Production Readiness Checklist

| Area | Status | Evidence |
|---|---|---|
| Original outcome/blocking ACs | fail | AC9 contradicted; AC10 unverified |
| Happy/negative local paths | pass | focused tests |
| Public/legacy compatibility | pass-with-gaps | automated compatibility; live API blocked |
| Security/privacy/secrets | pass-with-gaps | redaction and source spot-check; device auth unverified |
| Data integrity/migration | fail | concurrency defect and no live Alembic proof |
| Performance/cost/capacity | unverified | no production-scale runtime evidence |
| Observability/support diagnosis | partial | backup events exist; no deployed evidence |
| Configuration/dependencies | fail | OAuth/device and PostgreSQL unavailable |
| Deployment/rollout | unverified | merge/deployment not authorized |
| Rollback/recovery | partial | documented constraints; physical restore absent |
| Tests/build/static | partial | pure/focused pass; Stage 4 full mobile/build reusable; backend integration blocked |
| Workflow docs/state | fixed in this review | Stage 5 artifacts distinguish code/artifact SHA |
| No unresolved critical/important findings | fail | collection concurrency and evidence gaps remain |

## Security/Privacy/Data Integrity

No committed secret was identified in the reviewed backup paths. Encrypted package authentication protects restore payload integrity, but physical Drive authorization and recovery remain unverified. Collection concurrency is the principal data-integrity risk.

## Compatibility And Regression Risk

Schema changes are additive in code and legacy schema-9 restore tests pass. Live Alembic upgrade/downgrade remains required. The concurrency repair must preserve single collection APIs, local-mode behavior, canonical hashes, append-only ledger history, and deterministic retry responses.

## Performance/Cost/Operability

No new blocking performance issue was found. The collection grid's backend read path performs per-customer balance and totals queries, which may become noticeable at large customer counts but is not proven blocking for this cycle. Drive behavior remains operationally unproven without a device.

## Deployment/Rollout/Rollback

Do not merge or deploy. After the collection repair, rerun PostgreSQL migrations and concurrency tests, full backend/mobile suites, analyzer, release APK build, PDF visual smoke, and physical Drive backup/restore. Schema-10 data must not be opened by a schema-9-only app.

## Integration And Merge Record

- Integration target and pre-merge SHA: `main` / `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`
- Feature branch/worktree and validated code SHA: `codex/khata-invoice-collections-backup-analytics` / `/Users/abhishek/python_venv/khata_app-upgrade` / `5b6616502efdb511352e3124894ffcb643842535`
- Worktree name/ID and canonical absolute path: `khata_app-upgrade` / `/Users/abhishek/python_venv/khata_app-upgrade`
- Authorization/policy: authorization required and not recorded
- Integration method/status: not-started; verdict is not merge-eligible
- Merge/PR/integration SHA or URL: none
- Post-merge commands/evidence: not applicable
- Cleanup status: not performed

## Documentation And Workflow-State Accuracy

`STATE.md`, the cycle registry, and rolling context are updated by this review. The untracked top-level workflow files are now the canonical feature-worktree copies but remain uncommitted until the Stage 5 artifact checkpoint. The primary checkout's unrelated untracked workflow files were not modified.

## Fixes Made During Review

Workflow documentation only. No production fix was attempted because the collection repair requires a shared database concurrency mechanism and PostgreSQL-backed validation.

## Residual Risk And Unverified Evidence

- API batch/single collection concurrency.
- Live Alembic upgrade/downgrade and full `backend/tests`.
- Physical Google OAuth, scheduled/catch-up backup, retention, and restore.
- Manual rendered review of four invoice variants.
- Production application ID and signing remain a previously approved external release blocker.

## Upstream Process Defects

| Stage | Defect | Required improvement |
|---|---|---|
| Stage 3 | Task 04 did not implement shared concurrent-write serialization or the specified concurrency tests | Repair both collection paths and add PostgreSQL race tests |
| Stage 4 | Marked AC9 pass-with-gaps without exercising or reasoning through the planned concurrency scenarios | Inspect transaction boundaries and run concurrent conflicting-retry/overpay scenarios |
| Environment | PostgreSQL and physical Android OAuth environment unavailable | Restore required test environments before re-review |
| Workflow | Code SHA and artifact HEAD were conflated | Record both independently in every handoff |

## Project Memory Updates

- Cycle registry update: cycle remains active and is returned to Stage 3.
- Project context facts promoted/changed: candidate schema-10 capabilities are recorded as branch-only and not accepted current capability.
- Decisions superseded: none.
- Follow-up cycle candidates: Drive restore metadata hardening and collection-grid query optimization after this cycle is accepted.

## Required Next Action

Stage 3 must implement one shared PostgreSQL serialization contract for batch and single customer collections, add concurrent tests for conflicting batch retries and batch-versus-single overpayment, then restore PostgreSQL and rerun Task 04 plus the complete backend migration/integration gate before returning to Stage 4.
