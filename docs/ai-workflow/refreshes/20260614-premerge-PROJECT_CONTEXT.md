# Verified Project Context

Repository: `/Users/abhishek/python_venv/khata_app` (`git@github.com:abhishek2chikun/khata.git`)
As-of HEAD: `837ccbc0cfdb09a25b6aad02e4b0c357abafa8a6` (`main`, clean worktree)
Last reconciled by cycle: context-refresh `20260614`
Last updated: 2026-06-14 IST

## Product And Architecture Summary

Wholesaler billing and khata app for a small distributor:

- **Buyers** = suppliers (payable ledger)
- **Customers** = retail shops (receivable/khata ledger)
- **Products** = inventory with V2 fields (`buyer_id`, `company_name`, `buying_price`, `selling_price`, GST-inclusive)
- **Invoices** = multi-line sales with payment states (`CREDIT`, `PARTIAL_PAID`, `TOTAL_PAID`), stock + ledger side effects
- **Analytics** = dashboard revenue/profit by buyer/company/customer, top products, low stock, balances

Dual runtime modes share screen/service boundaries via `AppDependencies`:

1. **API mode** (default): Flutter → FastAPI → PostgreSQL
2. **Local mode** (`DATA_MODE=local`): Flutter → Drift/SQLite on device, no backend required

Primary delivery target is **Android local-mode release APK**. API contracts remain aligned for future server use.

## Current Capability Matrix

| Capability | Current status | Evidence/source cycle | As-of SHA | Notes |
|---|---|---|---|---|
| Auth (API + local first-user) | working | khata-app-baseline | `837ccbc` | Bearer auth API; local secure session |
| Products/inventory V2 | working | baseline + wholesaler workflow | `837ccbc` | Preinstalled catalog: 1199 products, 30 buyers in local APK |
| Customers/buyers + ledgers | working | baseline | `837ccbc` | Opening balance, collections, adjustments |
| GST/non-GST invoicing | working | khata-app-baseline | `837ccbc` | `gst_flag` on profile + invoice snapshot |
| Date-only invoice creation | working | khata-app-baseline | `837ccbc` | No timezone blocker from mobile |
| Adaptive invoice PDFs (4 variants) | working | khata-app-baseline Stage 5 | `837ccbc` | A5 candidate ≤15 rows + one-page fit fallback; else A4 |
| Invoice PDF sharing | partial | khata-app-baseline | `837ccbc` | Service tests pass; physical chooser unverified |
| Balance sharing (individual/daily) | working | khata-app-baseline Stage 5 | `837ccbc` | Daily summary excludes archived customers |
| Encrypted local backup/restore | partial | `837ccbc` prod audit | `837ccbc` | `LocalBackupTransferService` wired; physical file flow unverified |
| Google Drive backup | skeleton | offline-first design | — | Scheduler + interface only |
| Backend API + Alembic | working (no-DB verified) | backend tests/pure_tests | `837ccbc` | Full PostgreSQL pytest blocked when DB down |
| Analytics (API + local) | working | `837ccbc` audit fix | `837ccbc` | Local uses taxable revenue / canonical profit |
| CI | missing | refresh scan | `837ccbc` | No GitHub Actions workflows |

## Stable Public Contracts And Invariants

- REST error envelope: `{error: {code, message}}`
- Idempotent writes use `request_id` + canonical request hash (includes resolved `gst_flag` for invoices)
- Invoice creation/cancellation owns stock + ledger side effects transactionally
- Local monetary values stored as canonical decimal strings; server uses `Numeric`
- Backup envelope: AES-256-GCM + PBKDF2; requires matching `schema_version` and `backend_compatibility_version`
- Current versions: Drift schema **9**, backup schema **9**, compatibility **`local-v2`**, Alembic through **`0009_invoice_gst_flags`**
- PDF uses persisted invoice snapshot (profile changes do not rewrite historical documents)

## Module/Ownership Map

| Area | Paths | Owner lane |
|---|---|---|
| FastAPI entry + routers | `backend/app/main.py`, `backend/app/routers/` | backend |
| Domain services | `backend/app/services/` | backend |
| SQLAlchemy models | `backend/app/models/` | backend |
| Alembic migrations | `backend/alembic/versions/` | backend |
| Flutter app shell | `mobile/lib/main.dart`, `mobile/lib/app/app_dependencies.dart` | mobile |
| Local Drift DB | `mobile/lib/local/local_database.dart` | mobile |
| Local services | `mobile/lib/local/local_*_service.dart` | mobile |
| Invoice PDF + share | `mobile/lib/services/invoice_pdf_service.dart`, `invoice_share_service.dart`, `balance_share_service.dart` | mobile |
| Backup | `mobile/lib/backup/` | mobile |
| Preinstalled catalog | `mobile/assets/catalog/preinstalled_catalog.json`, `mobile/lib/local/local_product_catalog_seeder.dart`, `tools/build_preinstalled_catalog.py` | mobile |
| Agent instructions | `backend/agent.md`, `mobile/agent.md` | both |
| Workflow memory | `docs/ai-workflow/` | delivery chain |

## Canonical Build/Test/Run Commands

| Purpose | Command |
|---|---|
| Backend pure tests (no DB) | `.venv/bin/python -m pytest backend/pure_tests -q` |
| Backend integration tests | `BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing' .venv/bin/python -m pytest backend/tests -q` |
| Alembic upgrade | `(cd backend && BILLING_DATABASE_URL=... ../.venv/bin/python -m alembic upgrade head)` |
| Start API | `BILLING_DATABASE_URL=... PYTHONPATH=backend .venv/bin/python -m uvicorn app.main:app --app-dir backend --reload --port 8010` |
| Mobile tests | `(cd mobile && flutter test test)` |
| Mobile analyze | `(cd mobile && flutter analyze)` |
| Local-mode release APK | `(cd mobile && flutter build apk --release --dart-define=DATA_MODE=local)` |
| Rebuild preinstalled catalog | `python3 tools/build_preinstalled_catalog.py` |

## Current Deployment/Environment State

- Branch: `main` @ `837ccbc`, clean worktree
- PostgreSQL test container: **not running** (`localhost:55432` no response at refresh)
- Android package: `com.example.internal_billing_khata_mobile` (example ID)
- Release signing: debug keystore (not production-ready)
- Launcher label: `Khata` (confirmed in prod audit)

## Active Risks, Blockers, And Verification Gaps

1. Production release blocked by app ID + signing + physical-device matrix.
2. Full backend integration evidence requires Docker Postgres.
3. README and `mobile/agent.md` still describe PDF A5 threshold as ≤10 lines (code uses ≤15 + fit fallback).
4. Helvetica PDF font limitation for non-Latin names.
5. Drive backup remains external-configuration work.

## Deferred Work Across Cycles

- Choose permanent Android application ID and release keystore.
- Physical-device GST/non-GST PDF share, balance share, backup export/import, cancellation, restart persistence.
- Restore PostgreSQL and run full `backend/tests`.
- Unicode PDF font if multilingual invoices are required.
- Real Google Drive OAuth/upload implementation.

## Decision Ledger

| Decision | Current rule | Source cycle | As-of SHA | Supersedes |
|---|---|---|---|---|
| Four PDF variants required | A5/A4 × GST/non-GST | khata-app-baseline Stage 5 | `de7318a` | ≤10-line A5 rule |
| A5 sizing | ≤15 rows is candidate; keep A5 only if complete one-page render | khata-app-baseline Stage 5 | `de7318a` | hard ≤10 threshold |
| GST document identity | GST sections only on GST invoices; non-GST totals omit taxable mislabel | khata-app-baseline | `de7318a` | — |
| Daily balance share | Active customers with positive balance only | khata-app-baseline Stage 5 fix | `de7318a` | included archived customers |
| Local primary target | Local SQLite mode is release focus; API parity maintained | khata-app-baseline | `7699ae6` | — |
| Preinstalled catalog | Bundle 1199 products / 30 buyers on fresh local install | post-review `837ccbc` | `837ccbc` | empty local inventory |

## Known Documentation Drift

| Doc | Issue | Current truth |
|---|---|---|
| `README.md` GST section | Says "A5 (≤10 lines) / A4 (>10)" | Code: ≤15 candidate + fit fallback (`invoice_pdf_service.dart:10`) |
| `mobile/agent.md` | Same ≤10 wording; test count stale | 389 tests pass; PDF rule as above |
| `docs/ai-workflow/khata-app-baseline/00-discovery.md` | Baseline SHA `53886a6`, schema 8, 355 tests | Historical; superseded by accepted cycle + `837ccbc` |
| `docs/superpowers/plans/*` | Checkboxes still open | Implementation largely complete on `main` |
| Root `agent.md` | Missing | Use `backend/agent.md` and `mobile/agent.md` |
