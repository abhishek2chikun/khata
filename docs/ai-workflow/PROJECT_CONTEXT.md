# Verified Project Context

Workflow schema: five-stage-v1

Repository: `/Users/abhishek/python_venv/khata_app`

As-of product-code baseline: `f873c3853c263bcbd91dbaab8b72b4f1ed2e8eb1`

Last reconciled by cycle: `20260618-hybrid-supabase` Stage 2 planning

Last updated: 2026-06-18 IST

## Product And Architecture Summary

- Current implemented product: Flutter Android local mode backed by Drift/SQLite (`DATA_MODE=local`); this release path does not require FastAPI/PostgreSQL at runtime.
- Planned next product architecture: hybrid Supabase runtime where Supabase Postgres is source of truth, Drift is cache, and official writes use Supabase RPC only.
- FastAPI/PostgreSQL remains compatibility code for future server mode; not a deployment gate for local mode.
- API/local service boundaries remain parallel through `AppDependencies`.
- Buyers are suppliers/payables; customers are retail shops/receivables.
- Invoice creation/cancellation owns stock and ledger side effects transactionally.
- Backup packages are AES-256-GCM encrypted, version-gated, and exclude sessions.

## Current Capability Matrix

| Capability | Status | Evidence/source cycle | As-of SHA | Notes |
|---|---|---|---|---|
| GST/non-GST invoicing with `gst_flag` | implemented | baseline + upgrade | `862dc34` | seller profile + invoice snapshot |
| HSN/precision contracts (schema 10) | implemented | `20260614` cycle | `1d8e5dc` | Alembic `0010`; Drift schema 10 |
| Searchable invoice product picker | implemented | `20260614` cycle | `1d8e5dc` | 1,199 bundled products |
| Batch daily collections (local) | implemented | `20260614` cycle | `1d8e5dc` | Drift transaction boundary |
| Encrypted Drive backup orchestration | implemented; device-unverified | `20260614` + post-merge | `240f491` | fake adapters in tests only |
| Owner analytics dashboard | implemented | `20260614` cycle | `1d8e5dc` | KPIs, trends, rankings |
| Pre-confirm invoice PDF preview | implemented | post-merge commit | `862dc34` | `InvoicePreviewBuilder`, `printing` package |
| Preinstalled catalog seeding | implemented | baseline + v3 WIP | `862dc34` | uncommitted catalog rebuild in progress |
| Hybrid Supabase runtime | planned, not implemented | `20260618-hybrid-supabase` Stage 2 | `f873c38` | Stage 3 must implement from planning packet |
| API collection concurrency | deferred defect | `20260614` final review | `1d8e5dc` | `customer_service.py:211`, `:346` |
| Production Android identity/signing | unresolved | baseline audit | historical | release blocker |

## Stable Contracts And Invariants

- Alembic head: `0010_product_hsn_and_unit_price_precision` (down from `0009_invoice_gst_flags`).
- Drift and backup schema: **10**; backend compatibility: `local-v2`.
- Products carry nullable non-unique `hsn_code`; invoice lines snapshot `product_hsn_code`.
- GST invoice creation rejects products missing HSN; non-GST allows missing HSN.
- New invoice quantities must be whole numbers; unit prices use 3dp; monetary totals 2dp.
- New invoice writes require zero discount; historical discounted invoices remain readable.
- PDF page format: A5 when `itemCount <= 15`, else A4 (`invoice_pdf_service.dart`).
- Place of supply resolves customer state → company state; optional override on GST create form; hidden for non-GST.
- Non-GST PDFs use simplified item table without Code column.
- Blank/zero daily collection cells create no transaction.
- Bundled catalog: 1,199 products and 29 buyers (as-of committed asset; v3 rebuild uncommitted).

## Module/Ownership Map

| Area | Primary paths | Responsibility |
|---|---|---|
| Mobile app shell | `mobile/lib/main.dart`, `mobile/lib/app/` | mode selection, dependency wiring |
| Local persistence | `mobile/lib/local/` | Drift schema, local services |
| Invoice flow | `mobile/lib/screens/create_invoice_screen.dart`, `invoice_preview_screen.dart`, `invoice_pdf_preview_screen.dart` | draft → quote → PDF preview → confirm |
| PDF generation | `mobile/lib/services/invoice_pdf_service.dart`, `invoice_preview_builder.dart` | adaptive GST/non-GST PDFs |
| Backup/Drive | `mobile/lib/backup/` | encrypted backup, Drive orchestration, scheduler |
| Analytics | `mobile/lib/screens/analytics_screen.dart`, `mobile/lib/local/local_analytics_service.dart` | owner KPIs and trends |
| Backend API | `backend/app/` | FastAPI services, Alembic migrations |
| Catalog build | `tools/build_preinstalled_catalog.py`, `data/source/products.xlsx` | preinstalled asset generation |
| Hybrid planning packet | `docs/ai-workflow/cycles/20260618-hybrid-supabase/` | Supabase/Drift/RPC Stage 3 handoff |

## Canonical Build/Test/Run Commands

```bash
.venv/bin/python -m pytest backend/pure_tests -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests -q
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)
python3 tools/build_preinstalled_catalog.py
```

Verified at context-refresh `20260618`:
- `backend/pure_tests`: **56 passed**
- `mobile/test`: **474 passed**
- PostgreSQL integration tests: not run (`pg_isready` not attempted this refresh)

## Deployment/Environment State

- Remote: `git@github.com:abhishek2chikun/khata.git`
- Integration branch: `main` at `f873c38`
- Safety branch: `main_backup` pushed at `f873c38`
- Local-mode release APK build documented; production signing/app ID unresolved.
- Google Drive OAuth requires external Google Cloud configuration; no committed secrets.

## Active Risks, Blockers, And Verification Gaps

- Physical Android Google OAuth, WorkManager, Drive backup, and restore unverified.
- Production Android application ID and signing unresolved.
- API collection concurrency defect deferred; blocks future server-mode deployment.
- PostgreSQL-backed integration tests not verified in this refresh.
- `mobile/agent.md` still documents A5 ≤10 lines; code uses ≤15 (doc drift).

## Deferred Work

- Catalog v3 rebuild from corrected `Invoices (3).xlsx` source (uncommitted changes to `products.xlsx`, `preinstalled_catalog.json`, build script).
- Invoice cancel UI limited to invoice detail.
- No UI for product archive, customer archive, or manual stock adjustment.
- `flutter_lints` referenced in `analysis_options.yaml` but not in `pubspec.yaml`.

## Decision Ledger

| Decision | Current rule | Source cycle | As-of SHA | Supersedes |
|---|---|---|---|---|
| Local mode is primary deployment runtime | FastAPI not required for release | `20260614` final review | `1d8e5dc` | server-first assumptions |
| A5 PDF threshold | ≤15 line items | code truth | `862dc34` | baseline ≤10 docs |
| Backup schema version | 10 / `local-v2` | `20260614` cycle | `1d8e5dc` | schema 8/9 |
| API concurrency fix deferred | local mode unaffected | `20260614` final review | `1d8e5dc` | — |
| Pre-confirm PDF shows actual generated PDF | View PDF on preview screen | post-merge | `862dc34` | quote-only preview |

## Known Documentation Drift

- `mobile/agent.md` A5 threshold (≤10) vs code/README (≤15).
- `INDEX.md` prior baseline SHA `837ccbc` superseded by post-merge `main` history.
- `MASTER CATALOG.xlsx` is untracked but selected as the planned canonical catalog source for Stage 3.
