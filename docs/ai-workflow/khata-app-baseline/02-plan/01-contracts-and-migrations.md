# Task 01: Add Aligned GST Flags And Safe Migrations

## Outcome
Company profiles and invoices expose and persist deterministic `gst_flag` values in PostgreSQL, API DTOs, Flutter models, Drift, and encrypted backups without changing historical financial values.

## Why This Task Exists
Covers AC-GST-01 and AC-COMPAT-01. Every later calculation, UI, PDF, and sharing task needs a stable immutable mode field first.

## Dependencies
No prior task. Baseline Alembic head is `0008_invoice_v2`; Drift and backup schema versions are 8. PostgreSQL is required for full migration/API proof.

## Repository Evidence
- `backend/app/models/company_profile.py:CompanyProfile` and `backend/app/models/invoice.py:Invoice` are persistence extension points.
- `backend/app/schemas/company_profile.py` and `backend/app/schemas/invoice.py` define wire contracts.
- `mobile/lib/local/local_database.dart:CompanyProfiles, Invoices, LocalDatabase` owns aligned local schema/migrations.
- `mobile/lib/backup/backup_models.dart:LocalBackupPayload.currentSchemaVersion` and `local_backup_service.dart` enforce exact backup versions.
- `backend/alembic/versions/0008_invoice_v2.py` is the migration style/head to follow.

## Read Before Editing
Read the files above plus `mobile/lib/models/company_profile.dart`, `mobile/lib/models/invoice_detail.dart`, `mobile/lib/models/invoice_draft.dart`, and their focused tests.

## Scope
- Create: `backend/alembic/versions/0009_invoice_gst_flags.py` and `backend/tests/test_invoice_gst_flag_migration_contract.py`.
- Modify: backend company/invoice models and schemas; Flutter company/invoice models; Drift tables/migration; backup schema constant.
- Generate: `mobile/lib/local/local_database.g.dart` through build_runner, never by hand.
- Tests: company profile API/local tests, invoice mapping/service fixtures, backup tests, and migration tests.
- Docs/state: append actual evidence to `03-implementation-log.md`; update `STATE.md` task status only after green validation.

## Contracts And Invariants
- Persist `gst_flag` as non-null boolean on company profiles and invoices.
- New company profile request accepts `gst_flag` default false; responses always return it.
- Invoice quote/create request uses optional `gst_flag` server-side for compatibility; quote/detail/list responses return resolved `gst_flag`.
- Flutter constructors require explicit `gstFlag` after fixtures are migrated; `InvoiceDraft` may default false until Task 03 wires profile defaults.
- Backfill company true iff `gstin` is non-null and trimmed non-empty.
- Backfill invoice true iff `company_gstin` is non-empty or `gst_total <> 0`; otherwise false.
- Never update invoice items, totals, snapshots, customer transactions, stock movements, dates, or request hashes in this migration.
- Drift schema and column names must remain backend-aligned as `gst_flag`; backup schema becomes 9 and compatibility remains `local-v2`.

## Implementation Guidance
1. Write failing schema/serialization/migration tests before production edits.
2. Add Alembic columns nullable with temporary server defaults, backfill, then make non-null; leave a sensible server default only if repository migration style requires it.
3. Downgrade drops only the two additive columns. Document that old code cannot faithfully interpret new non-GST records.
4. Add matching Drift `BoolColumn`s and `from < 9` migration SQL/addColumn operations. Infer local backfills with the same predicates.
5. Raise `LocalDatabase.schemaVersion` and `LocalBackupPayload.currentSchemaVersion` to 9.
6. Regenerate Drift output with:
   `cd mobile && dart run build_runner build --delete-conflicting-outputs`.
7. Thread fields through JSON models and fixtures without implementing tax policy yet.

## Test-First Specification
- `backend/tests/test_invoice_gst_flag_migration_contract.py::test_upgrade_adds_and_backfills_only_gst_flags`: inspect migration source/order and assert no financial table updates. Fails because `0009` is absent; prevents broad historical rewrites.
- `backend/tests/api/test_company_profile_api.py::test_company_profile_round_trips_gst_flag`: upsert false/true payloads and assert response. Prevents persistence-only fields omitted from API.
- Existing invoice API fixtures updated to assert `gst_flag` in quote/detail/list; fails before schemas change.
- `mobile/test/local/local_company_profile_service_test.dart`: round-trip both values.
- `mobile/test/local/invoice_detail_mapping_test.dart`: persisted invoice maps its immutable value.
- `mobile/test/backup/local_backup_service_test.dart`: v9 export/import carries both columns and v8 package is rejected. Prevents silent backup data loss.
- Add a v8-to-v9 Drift migration fixture/test if current test harness supports schema fixtures; otherwise prove with a temporary v8 SQL database opened by v9 code and inspect values.

## Validation Ladder
1. Red: run focused new migration/profile/local tests; expect missing fields/migration.
2. Green: `PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/test_invoice_gst_flag_migration_contract.py backend/tests/api/test_company_profile_api.py -q` and focused Flutter tests.
3. Run all backend invoice/company tests and mobile local/backup/service tests.
4. Run build_runner, `dart format --output=none --set-exit-if-changed` only after formatting changed Dart files, and `flutter analyze` without rewriting unrelated files.
5. Apply `alembic upgrade head` on disposable Postgres; inspect old/new rows and `alembic downgrade 0008` on a disposable copy.
6. Proves AC-GST-01 schema foundation and AC-COMPAT-01 migration portion.

## Review Checklist
- Migration predicates match backend and Drift exactly.
- Historical monetary/date/hash fields are untouched.
- Generated code diff contains only expected columns/version effects.
- Backup required table list still includes the same tables; no secrets added.
- API omission compatibility is preserved.

## Allowed Adaptation
Adjust exact generated type names or test fixture helpers to current Drift conventions. A migration test may use source inspection plus disposable DB evidence if no reusable migration harness exists.

## Stop And Escalate If
- Existing production rows violate the proposed deterministic backfill.
- Drift cannot add/backfill non-null booleans without rebuilding tables and risking unrelated data.
- Alembic head differs from `0008` or another migration concurrently owns revision `0009`.
- Generated code rewrites unrelated tables.

## Commit Checkpoint
Suggested: `feat: add seller and invoice gst mode contracts`

## Done When
- Both schemas are versioned/aligned, all DTOs/models round-trip the flag, v8 data upgrades deterministically, v9 backups work, old package rejection is explicit, focused suites pass, and migration diffs receive review.

## Handoff Update
Record migration revision, schema/backup versions, commands/results, generated file diff note, and any baseline failures in `03-implementation-log.md`. Set Task 01 complete and Task 02 next in `STATE.md`; do not mark tax behavior implemented.
