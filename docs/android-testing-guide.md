# Android Testing Guide (Hybrid Supabase)

This guide covers running the Khata Flutter app on Android emulator or a physical
device against a live Supabase project. There is **no local FastAPI backend** in
the current runtime — do not follow older guides that mention port forwarding to
`localhost:8000` or `8010`.

## What you need

| Requirement | Notes |
| --- | --- |
| Flutter SDK | Stable channel; run `flutter doctor` |
| Android SDK | Platform tools, build-tools, at least one system image |
| Supabase project | Migrations applied; operator account in Supabase Auth |
| Credentials | `SUPABASE_URL` + `SUPABASE_ANON_KEY` (public anon/publishable key) |

Apply schema and seed catalog from the repo root before first device login:

```bash
bash supabase/tests/run_migrations_and_tests.sh
python3 tools/build_preinstalled_catalog.py
python3 tools/test_catalog_parity.py
```

Provision email/password operator accounts in the Supabase dashboard (Auth →
Users). The app does not bootstrap users locally.

## Environment variables

Export before every `flutter run` or build:

```bash
export SUPABASE_URL='https://<project-ref>.supabase.co'
export SUPABASE_ANON_KEY='<public-anon-key>'
```

Optional: store values in a repo-root `.env` (gitignored) and use
`tools/build_hybrid_apk.sh` for release APKs.

**No `adb reverse` is required.** The app talks to Supabase over HTTPS, not a
local backend.

## Install Flutter dependencies

```bash
cd mobile
flutter pub get
```

## Emulator workflow

### 1. Start an Android emulator

List available AVDs and launch one:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

Wait until the emulator finishes booting, then confirm visibility:

```bash
adb devices
# Expected: emulator-5554    device
```

### 2. Run the app

```bash
cd mobile
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Replace `emulator-5554` with the ID from `adb devices` or `flutter devices`.

## Physical device workflow

### 1. Enable USB debugging

On the phone:

1. Settings → About phone → tap **Build number** seven times
2. Settings → System → Developer options → enable **USB debugging**

### 2. Connect and authorize

```bash
adb devices
```

If the device shows `unauthorized`, unlock the phone and accept the USB debugging
prompt.

### 3. Run the app

```bash
cd mobile
flutter devices
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

## Release APK for sideloading

From the repo root (loads `.env` when present):

```bash
bash tools/build_hybrid_apk.sh
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`

Install on device:

```bash
adb install -r mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Manual smoke test (single device)

After login and initial sync complete:

1. Open inventory and confirm catalog products load.
2. Create or edit a product; verify it appears after sync indicator clears.
3. Create a customer and draft an invoice; confirm PDF preview renders.
4. Confirm the invoice on device; verify stock movement and ledger update.
5. Background the app and resume; confirm sync runs without data loss.
6. Toggle airplane mode; confirm cached reads work but official writes are blocked.

## Two-device sync smoke (pre-production)

Install the **same APK** on two devices with different operator accounts (or the
same account on two phones for cache isolation testing):

1. Login and complete initial sync on both devices.
2. Create a product/customer and confirm an invoice on device A.
3. Sync device B (pull-to-refresh or wait for background sync) and compare
   invoice, stock movement, quantity, and customer ledger.
4. Cancel the invoice on device B.
5. Sync device A and verify canceled invoice, stock reversal, and ledger reversal.

Automated remote proof (requires `.env` with live Supabase):

```bash
bash tools/run_remote_two_client_smoke.sh
```

## Automated checks (no device)

```bash
cd mobile && flutter test test
cd mobile && flutter analyze
python3 tools/test_catalog_parity.py
bash supabase/tests/run_migrations_and_tests.sh
bash tools/check_hybrid_runtime_cleanup.sh
```

## Useful debug commands

```bash
adb devices                    # connected emulators/phones
flutter devices                # Flutter-visible targets
flutter logs                   # stream device logs while app runs
adb logcat | grep -i flutter   # raw Android log filter
```

## Common problems

### App crashes at startup with dart-define error

Hybrid mode requires both Supabase defines. Re-export `SUPABASE_URL` and
`SUPABASE_ANON_KEY` and rebuild.

### Login works in debug but fails on release APK

Release builds bake dart-defines at compile time. Rebuild the APK with the
correct Supabase project keys.

### API / network errors on emulator

Confirm the emulator has internet access (Supabase is cloud-hosted). This is not
a localhost port-forward issue.

### Stale catalog or missing products

Regenerate and reseed:

```bash
python3 tools/build_preinstalled_catalog.py
python3 tools/seed_supabase_master_catalog.py --reset
```

Reinstall the app or trigger a full sync after reseed.

### `flutter doctor` Android toolchain errors

Install Android SDK command-line tools and accept licenses:

```bash
flutter doctor --android-licenses
```

On macOS with Homebrew Java:

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
flutter config --jdk-dir="$JAVA_HOME"
```

### Legacy docs mention FastAPI, Docker Postgres, or `API_BASE_URL`

Those apply to the pre-hybrid runtime on branch `main_backup`. The current app
uses Supabase RPC + Drift cache only. See [`../README.md`](../README.md) and
[`../mobile/README.md`](../mobile/README.md).

## Recommended daily loop

1. Ensure Supabase migrations are current.
2. Export `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. Start emulator or connect physical device.
4. `flutter run` from `mobile/` with dart-defines.
5. Keep `flutter logs` open while reproducing bugs.
