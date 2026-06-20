# Mobile Agent Guide

Role: Flutter client for Supabase-authenticated billing, inventory, customer
receivables, buyer payables, collections, invoices, PDFs, and analytics.

## Architecture

- The only runtime is hybrid: Supabase Postgres authority plus Drift cache.
- `AppDependencies.create()` always composes hybrid services.
- `Hybrid*Service` implementations own official writes through RPC.
- `Local*Service` implementations are Drift read/cache delegates and deterministic
  quote/PDF/analytics helpers. They are not production write authorities.
- `HybridSyncService` upserts canonical rows and applies RPC results immediately.
- Supabase Auth is wrapped by `HybridAuthService`; session tokens use secure storage.
- Offline official writes are intentionally unsupported.

## Important Paths

| Path | Responsibility |
| --- | --- |
| `lib/app/` | Hybrid dependency composition and runtime validation |
| `lib/hybrid/` | Auth, RPC adapters, write services, and synchronization |
| `lib/local/` | Drift schema/cache repositories and cached read behavior |
| `lib/screens/` | User workflows |
| `lib/services/` | Shared service contracts, PDF/share, and validation |
| `test/hybrid/` | RPC-only write and cache-sync tests |
| `test/local/` | Drift mapping/read/cache regression tests |

## Invariants

- Never add a direct Supabase table write from Flutter; official writes use RPC.
- Never assign an official invoice number on the phone.
- Retry a timed-out write with the same request ID and payload.
- Apply canonical RPC response rows to Drift before returning from a write.
- Normal sync is row-level upsert; only first hybrid cutover clears business cache.
- Keep archived products/customers/buyers available for historical invoice rendering.
- Preserve whole invoice quantities, 3-decimal unit prices, 2-decimal totals,
  GST/non-GST behavior, HSN snapshots, PDF preview, and PDF sharing.
- Do not reintroduce local auth, API mode, backup/restore, Drive, or WorkManager.

## Commands

```bash
flutter pub get
flutter test test
flutter analyze
flutter build apk --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<public-key>
```

Catalog regeneration runs from the repository root (CSV preferred over xlsx):

```bash
python3 tools/build_preinstalled_catalog.py
python3 tools/test_catalog_parity.py
python3 tools/seed_supabase_master_catalog.py --reset   # push to Supabase
```

Current bundled catalog: **v7** — 30 buyers, 1528 products from `data/source/MASTER CATALOG.csv`.

The backend directory is historical reference only. The Flutter app must not
import or call it.
