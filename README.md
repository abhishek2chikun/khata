# Khata

Khata is a hybrid Flutter billing and ledger app for a small wholesaler. Supabase
Postgres is the business source of truth; Drift/SQLite is the on-device read
cache used for fast screens, invoice drafts, analytics, PDFs, and sharing.

## Runtime Contract

- Supabase Auth owns operator login and sessions.
- Official writes use transactional Supabase RPC functions.
- Drift never assigns official invoice numbers or authorizes a write.
- RPC results are upserted into Drift immediately; background sync reconciles
  changes from other devices.
- Startup/login, app resume, manual refresh, post-write debounce, and a 10-minute
  in-app timer trigger sync.
- Offline cached reads and invoice preview are supported. Official offline writes
  are blocked.
- There is no local-only, FastAPI, Google Drive backup, or restore runtime.

## Repository Map

| Path | Purpose |
| --- | --- |
| `mobile/` | Flutter app and Drift cache |
| `supabase/migrations/` | Canonical schema, RLS, and RPC functions |
| `supabase/tests/` | Postgres migration/RPC smoke tests |
| `data/source/MASTER CATALOG.xlsx` | Canonical product and buyer catalog |
| `tools/build_preinstalled_catalog.py` | Generates Drift JSON and Supabase seed SQL |
| `backend/` | Historical pre-hybrid reference; not used by the app |
| `docs/ai-workflow/cycles/20260618-hybrid-supabase/` | Design and release evidence |
| `docs/android-testing-guide.md` | Emulator and physical-device testing (Supabase hybrid) |
| `docs/hybrid-supabase-architecture.html` | Architecture diagram and RPC inventory |
| `mobile/README.md` | Flutter module layout, invariants, and troubleshooting |

## Configure Supabase

Keep credentials outside Git. The app build needs only the project URL and
public anonymous/publishable key:

```bash
export SUPABASE_URL='https://<project-ref>.supabase.co'
export SUPABASE_ANON_KEY='<public-key>'
export DATABASE_URL='postgresql://...'
```

Apply migrations and seed the canonical catalog:

```bash
bash supabase/tests/run_migrations_and_tests.sh
python3 tools/build_preinstalled_catalog.py
python3 tools/test_catalog_parity.py
```

Provision operator accounts in Supabase Auth before device login. The app expects
email/password credentials.

## Run And Build

```bash
cd mobile
flutter pub get
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Build the sideloadable family-test APK:

```bash
cd mobile
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`.

## Validate

```bash
python3 tools/test_catalog_parity.py
bash supabase/tests/run_migrations_and_tests.sh
(cd mobile && flutter test test)
(cd mobile && flutter analyze)
```

Before family cutover, install the same APK on two devices and verify this flow:

1. Login and complete initial sync on both devices.
2. Create a product/customer and confirm an invoice on device A.
3. Sync device B and compare invoice, stock movement, quantity, and customer ledger.
4. Cancel the invoice on device B.
5. Sync device A and compare the canceled invoice, stock reversal, and ledger reversal.

The pre-hybrid recovery branch is `main_backup`. Once real production writes
exist in Supabase, preserve/export that database before attempting rollback.
