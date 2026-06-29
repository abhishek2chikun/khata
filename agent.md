# Agent Progress Log

## Recent Changes (latest first)

1. **2026-06-29 — Hybrid developer docs refresh (documentation automation)**
   - Replaced stale Flutter template in `mobile/README.md` with hybrid runtime
     contract, layout, sync invariants, catalog commands, and troubleshooting.
   - Rewrote `docs/android-testing-guide.md` for Supabase hybrid (removed
     obsolete FastAPI/Docker/port-forward instructions from pre-hybrid runtime).
   - Linked new docs from root `README.md`.

2. **2026-06-26 — Hybrid sync concurrency hardening**
   - Background `syncAll()` no longer deactivates products hydrated by in-flight RPC writes (`_rpcTouchedProductIds` merged into deactivate guard set).
   - Paginated product sync uses `upsertProductIfNewer` so stale remote pages cannot overwrite fresher RPC cache rows.
   - Coalesced background sync schedules a follow-up pass when `_isSyncing` instead of silently dropping.
   - App resume only marks bootstrap complete when `syncAll()` actually ran.

2. **2026-06-21 — Batch collections local cache hydration**
   - `record_batch_collections` RPC returns summary stats only; `applyRpcResult` now fetches batch rows by `__batch__|request_id|%` notes marker and upserts into Drift immediately.
   - Prevents stale receivables in daily collections grid and duplicate server entries on re-submit before background sync.

2. **2026-06-19 — Catalog v7 from CSV + Supabase reseed**
   - Source: `data/source/MASTER CATALOG.csv` (from `MASTER CATALOG - Master Catalog.csv`)
   - Generator updated: CSV support, ₹/comma parsing, `CATALOG_VERSION=7`
   - Outputs: `mobile/assets/catalog/preinstalled_catalog.json`, `supabase/seed/master_catalog.json`
   - Counts: 30 buyers, 1528 products (47 duplicate rows merged)
   - Supabase seeded via `python3 tools/seed_supabase_master_catalog.py --reset` (stock reset)
   - Seed script now supports `--reset` flag for forced reseed
   - **Build blocked**: agent-side `flutter build apk` hung (Gradle sandbox cache); existing APK is pre-v7 (2026-06-19 20:24). Build locally in Terminal for fresh APK.
