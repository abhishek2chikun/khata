# Agent Progress Log

## Recent Changes (latest first)

1. **2026-06-19 — Catalog v7 from CSV + Supabase reseed**
   - Source: `data/source/MASTER CATALOG.csv` (from `MASTER CATALOG - Master Catalog.csv`)
   - Generator updated: CSV support, ₹/comma parsing, `CATALOG_VERSION=7`
   - Outputs: `mobile/assets/catalog/preinstalled_catalog.json`, `supabase/seed/master_catalog.json`
   - Counts: 30 buyers, 1528 products (47 duplicate rows merged)
   - Supabase seeded via `python3 tools/seed_supabase_master_catalog.py --reset` (stock reset)
   - Seed script now supports `--reset` flag for forced reseed
   - **Build blocked**: agent-side `flutter build apk` hung (Gradle sandbox cache); existing APK is pre-v7 (2026-06-19 20:24). Build locally in Terminal for fresh APK.
