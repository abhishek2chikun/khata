# LLM Review Anchor

Workflow objective: Make catalog-scale invoicing practical and compliant, add atomic daily customer collections, protect local data with encrypted Drive recovery, and provide owner-grade analytics.

Cycle ID and lineage: `20260614-invoice-collections-backup-analytics`, child of accepted `khata-app-baseline`.

Repository baseline SHA: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Integration target: `main`

Feature branch: `codex/khata-invoice-collections-backup-analytics`

Worktree: `khata_app-upgrade`

Canonical path: `/Users/abhishek/python_venv/khata_app-upgrade`

Merge owner/status: Stage 5 persistent LLM / not-started; authorization required.

## Approved Scope And Non-Goals

Scope: HSN/precision/quantity/discount contracts, searchable invoice entry, Cash/Credit UX, four PDF variants, seven-day atomic customer collections, encrypted Drive backup/restore/scheduling, owner analytics, migrations, compatibility, and evidence.

Non-goals: invoice-list search, regenerated identifiers, guessed HSN, rewritten history, advance credit, exact alarms, app ID/signing, committed secrets, iOS scheduling, multilingual fonts.

## Architecture In One Page

- Task 01 proves package/platform feasibility.
- Task 02 exclusively owns shared backend/Drift/backup/catalog contracts and migrations.
- Task 03 consumes those contracts for invoice UI and PDFs.
- Task 04 adds a true atomic batch ledger service, not a client loop.
- Task 05 transports existing encrypted packages through Drive and WorkManager; encryption/restore authority stays in `LocalBackupService`.
- Task 06 adds canonical service-calculated KPI/trend fields and presentation-only charts.
- Task 07 integrates and validates; Stage 5 alone decides merge.

## Key Decisions And Rejected Alternatives

- Separate nullable HSN, stable item identity; reject HSN-derived item numbers.
- GST write gate with immutable snapshot; reject UI/PDF-only compliance.
- Integral new quantities and three-decimal unit prices; preserve historical decimal quantities and two-decimal totals.
- New discounts zero; reject destructive field/history removal.
- Cash=fully paid; Credit=unpaid/partial.
- Atomic seven-day batches; reject repeated single-row client calls.
- Visible encrypted Drive folder, secure password, verified upload, 30 retained; reject unencrypted/hidden/selected-folder variants.
- Additive analytics response; reject breaking removal of low-stock API data.

## Contracts And Invariants That Must Survive

- API/local parity and canonical request hashing.
- Transactional invoice stock/ledger side effects.
- Stable IDs/item numbers and immutable invoice snapshots.
- Append-only customer ledger and no negative balance from batch entry.
- Legacy schema-9 backup and historical invoice readability.
- Secrets never in source, DB backup settings, Drive metadata, or logs.
- Upload verification before success/pruning; restore validation before replacement.

## Acceptance Criteria By Risk

- Financial/migration: AC1-AC4, AC7, AC9, AC11, AC13.
- Document/UX: AC5, AC6, AC8.
- External/platform: AC10.
- Reporting: AC12.
- Integration/release: AC14.

## Expected Change Surface By Task/Commit

1. Dependency/platform adapter proof.
2. Alembic/Drift/catalog/backup and shared DTO/service contracts.
3. Invoice picker/controller/screens/PDFs.
4. Customer batch schemas/router/services/local/UI.
5. Backup auth/Drive/secure store/WorkManager/UI.
6. Analytics schemas/services/models/screen/charts.
7. Integration fixes, generated artifacts, docs, evidence.

## Highest-Risk Failure Modes

- Financial value rewrite during migration.
- API/local precision or hash divergence.
- Hidden GST state on non-GST invoices.
- Partial batch postings or duplicate retries.
- Drive success before verified upload or deletion of unrelated files.
- Restore mutating data before full validation.
- Analytics using current product prices rather than invoice snapshots.

## Review Hypotheses

- Catalog v2 seeding may overwrite user stock unless update columns are explicit.
- Cash total resolution may race quote/create unless the service remains authoritative.
- PostgreSQL batch balance checks may need row locking to prevent overpayment races.
- Background auth may require foreground re-consent after token expiry.
- PDF column tuning may regress A5 fit or historical discounted reconciliation.
- Low-stock-only data may incorrectly suppress the analytics empty state.

## Expected Runtime/Release Evidence

- Four current PDF variants plus historical canceled/discounted fixture.
- 1,199-product search on device.
- One-day/seven-day collection grid with zero, retry, failure, and overpay scenarios.
- Configured physical Android Drive sign-in/upload/schedule/catch-up/restore/restart proof.
- Full backend/mobile suites, live migrations, analyzer, local release APK, artifact hash.

## Plan Assumptions To Recheck

- Business date follows device local date.
- OAuth test configuration can be supplied outside git.
- PostgreSQL test database can be started for final evidence.
- Current app ID may be used for test OAuth configuration but remains a distribution blocker.

## Final Review And Merge Checklist

- Compare actual diff to baseline and task contracts.
- Verify AC coverage and blockers from independent evidence.
- Confirm no secrets, unrelated changes, or default-branch implementation.
- Re-run high-risk migration, financial, batch, backup, and PDF tests.
- Keep merge status not-started until Stage 5 authorization.

## Rehydration Order

1. `STATE.md`
2. This anchor
3. Stage 4 `04-return-packet.md` and `04-validation-report.md`
4. `03-implementation-log.md` (AC1–AC14 evidence)
5. Actual `837ccbc0..validated-head` diff
6. Targeted evidence named by Stage 4

## Stage 3 Handoff (2026-06-14)

- Stage 3 complete; owner → Stage 4 fresh validation agent.
- Automated: 55 pure + 458 mobile pass; release APK SHA-256 `3de1bc6a…` at HEAD `18693a9`.
- Blocked: Postgres `backend/tests`; AC10/AC11 physical Drive matrix.
- First command: `pg_isready -h localhost -p 55432`
