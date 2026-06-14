# Verified Project Context

Repository: `/Users/abhishek/python_venv/khata_app-upgrade`

Accepted baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Active candidate reviewed code SHA: `5b6616502efdb511352e3124894ffcb643842535` (not accepted or merged)

Active cycle: `20260614-invoice-collections-backup-analytics`

## Stable Architecture

- FastAPI/PostgreSQL backend and Flutter mobile client.
- Primary delivery target: Android local mode backed by Drift/SQLite.
- API/local service boundaries remain parallel through `AppDependencies`.
- Buyers are suppliers/payables; customers are retail shops/receivables.
- Invoice creation/cancellation owns stock and ledger side effects transactionally.
- Backup packages are AES-256-GCM encrypted, version-gated, and exclude sessions.

## Accepted Baseline Facts

- Alembic head: `0009_invoice_gst_flags`.
- Drift and backup schema: 9; compatibility: `local-v2`.
- Bundled catalog: 1,199 products and 30 buyers.
- Catalog workbook HSN: 109 distinct non-empty codes, 67 repeated codes, 125 missing values.
- Product picker has no search.
- Drive and background scheduling are skeletons.
- Analytics is list-based and includes low stock.
- Android application ID/signing remain release blockers outside the active cycle.

## Canonical Commands

```bash
.venv/bin/python -m pytest backend/pure_tests -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
python3 tools/build_preinstalled_catalog.py
```

## Active Handoff

The feature branch contains candidate schema-10 HSN/precision, invoice UX/PDF, daily collections, Drive, and analytics capabilities. They are not promoted as accepted current behavior because Stage 5 found a blocking API collection concurrency defect.

Read `cycles/20260614-invoice-collections-backup-analytics/STATE.md`, `05-final-review.md`, and Task 04. Stage 3 must make single and batch collection writes share a durable PostgreSQL serialization contract and add concurrent regression tests before Stage 4 revalidation. Do not merge.

## Active Risks And Release Blockers

- Concurrent batch requests can reuse one batch request ID with disjoint payloads and both commit.
- Concurrent single and batch collection writes do not share customer locking and can over-collect.
- Live Alembic/full backend integration evidence is unavailable while PostgreSQL is down.
- Physical Android Google OAuth, WorkManager, Drive backup, and restore remain unverified.
- Production Android application ID and signing remain outside this cycle and unresolved.
