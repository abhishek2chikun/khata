# Khata Mobile (Flutter)

Hybrid Flutter client for wholesaler billing, inventory, receivables, buyer
payables, invoices, PDFs, and analytics. Supabase Postgres is the write
authority; Drift/SQLite is the on-device read cache.

Canonical repo overview: [`../README.md`](../README.md). Module-level
architecture and invariants: [`agent.md`](agent.md). Android device setup:
[`../docs/android-testing-guide.md`](../docs/android-testing-guide.md).

## Runtime contract

- **Hybrid only.** `DATA_MODE=api|local` throws at startup. Production builds
  use empty or `hybrid` with Supabase dart-defines.
- **Official writes** go through Supabase RPC functions (`Hybrid*Service`). The
  phone never assigns invoice numbers or writes directly to Postgres tables.
- **Drift** holds cached rows for fast screens, PDF preview, analytics, and
  offline reads. RPC results are upserted into Drift before a write returns.
- **Sync** runs on startup/login, app resume, manual refresh, post-write debounce
  (2s), and a 10-minute in-app timer. Background sync reconciles other-device
  changes without blocking the write UI.
- **Offline official writes are blocked.** Cached reads and invoice preview work
  offline.
- **Removed runtimes:** local-only auth, FastAPI client mode, Google Drive
  backup/restore, WorkManager hooks. The repo `backend/` directory is historical
  reference only.

## Prerequisites

- Flutter SDK (stable channel, Dart 3.x)
- Android SDK for device/emulator builds
- Supabase project URL and public anonymous key (never commit secrets)

Export credentials before every run/build:

```bash
export SUPABASE_URL='https://<project-ref>.supabase.co'
export SUPABASE_ANON_KEY='<public-anon-key>'
```

Or place them in a repo-root `.env` and use `tools/build_hybrid_apk.sh`.

## Quick start

```bash
cd mobile
flutter pub get
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Release APK (from repo root, reads `.env` when present):

```bash
bash tools/build_hybrid_apk.sh
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Project layout

| Path | Role |
| --- | --- |
| `lib/app/` | Dependency wiring, runtime mode validation |
| `lib/hybrid/` | Supabase auth, RPC client, write services, sync |
| `lib/local/` | Drift schema, cache repositories, read helpers |
| `lib/screens/` | User workflows (inventory, invoices, collections, …) |
| `lib/services/` | Shared contracts, PDF/share, validation |
| `test/hybrid/` | RPC write path and cache-sync tests |
| `test/local/` | Drift mapping and read regression tests |
| `assets/catalog/preinstalled_catalog.json` | Bundled catalog v7 (30 buyers, 1528 products) |

## Developer invariants

- Never add direct Supabase table writes from Flutter; use RPC wrappers.
- Retry a timed-out write with the **same request ID and payload** (idempotent).
- Apply canonical RPC response rows to Drift before returning from a write.
- Normal sync is row-level upsert; only first hybrid cutover clears business cache.
- Do not reintroduce local auth, API mode, backup/restore UI, or Drive integration.

## Sync behavior (2026-06-26)

Recent hardening in `HybridSyncService`:

- `_rpcTouchedProductIds` prevents background deactivate from clobbering products
  hydrated by in-flight RPC writes.
- Paginated product sync uses `upsertProductIfNewer` so stale remote pages cannot
  overwrite fresher local RPC cache rows.
- When sync is already running, coalesced schedules queue a follow-up pass
  instead of dropping silently.
- App resume marks bootstrap complete only when `syncAll()` actually ran.

## Catalog regeneration

From the repository root (CSV preferred):

```bash
python3 tools/build_preinstalled_catalog.py
python3 tools/test_catalog_parity.py
python3 tools/seed_supabase_master_catalog.py --reset   # push to Supabase
```

Source of truth: `data/source/MASTER CATALOG.csv`.

## Validate

```bash
flutter test test
flutter analyze
```

Remote two-client smoke (requires live Supabase credentials in `.env`):

```bash
bash tools/run_remote_two_client_smoke.sh
```

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Startup crash mentioning dart-defines | Missing Supabase env | Export `SUPABASE_URL` and `SUPABASE_ANON_KEY` |
| Login fails on release APK | Wrong project/key baked into build | Rebuild with correct `--dart-define` values |
| Stale data after write on another device | Background sync not run yet | Pull-to-refresh or wait for debounce/periodic sync |
| Product disappeared after sync | RPC-hydrated row clobbered (regression) | Should be fixed by `_rpcTouchedProductIds`; file a bug with sync logs |
| `DATA_MODE=local` build | Legacy mode removed | Remove the define; use hybrid + Supabase keys only |

## Related docs

- [`../docs/hybrid-supabase-architecture.html`](../docs/hybrid-supabase-architecture.html) — architecture diagram and RPC inventory
- [`../docs/ai-workflow/cycles/20260618-hybrid-supabase/`](../docs/ai-workflow/cycles/20260618-hybrid-supabase/) — design, validation evidence, production checklist
- [`GOOGLE_DRIVE_SETUP.md`](GOOGLE_DRIVE_SETUP.md) — **obsolete** (pre-hybrid local mode only)
