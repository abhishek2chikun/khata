# Verified Project Context

Repository: `/Users/abhishek/python_venv/khata_app`

Accepted baseline: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6`

Integrated code SHA: `1d8e5dca5c04e2ff40efc0fca636df29b2296d47`

Latest cycle: `20260614-invoice-collections-backup-analytics` (integrated; release followups open)

## Stable Architecture

- Primary deployed product: Flutter Android local mode backed by Drift/SQLite; this release does not use the client-server runtime.
- FastAPI/PostgreSQL remains compatibility code and is not a deployment gate for local mode.
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

Schema-10 HSN/precision, invoice UX/PDF, daily collections, Drive, and analytics capabilities are integrated on `main` for local mode. Physical Drive evidence and production Android identity/signing remain release blockers.

Read `cycles/20260614-invoice-collections-backup-analytics/STATE.md` and `05-final-review.md`. Integration is complete; the next action is production Android identity/signing plus physical Drive verification.

## Active Risks And Release Blockers

- Physical Android Google OAuth, WorkManager, Drive backup, and restore remain unverified.
- Production Android application ID and signing remain outside this cycle and unresolved.
- API collection concurrency remains deferred and must be repaired before any future server-mode deployment.
