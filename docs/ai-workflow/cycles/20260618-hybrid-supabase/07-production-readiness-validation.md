# Production Readiness Validation

Date: 2026-06-19

Verdict: `production-code-validated-awaiting-physical-device-smoke`

## Closed Blockers

- All official mobile writes are routed through Supabase RPC wrappers.
- Drift sync covers products, customers, buyers, company profiles, invoices,
  invoice items, stock movements, customer transactions, and buyer transactions.
- API mode, local-only auth/setup, backup/restore UI, Drive services, WorkManager,
  and their mobile dependencies are removed.
- Drift schema 12 replaces legacy backup metadata with catalog cache metadata.
- Post-write UI uses canonical RPC upserts and does not await a full sync.
- Supabase reads use stable `id` ordering and 1,000-row pagination.

## Real Supabase Scenario

Command: `bash tools/run_remote_two_client_smoke.sh`

The test used father and brother test users with separate `SupabaseClient`
sessions and separate in-memory Drift databases:

1. Both users authenticated.
2. Both initial cache builds loaded 30 buyers and all 1,530 active remote products.
3. Primary created a temporary product and customer through RPC.
4. Primary confirmed a credit invoice through `create_invoice` RPC.
5. Secondary synced invoice, item, stock, product quantity, and customer ledger.
6. Secondary canceled through `cancel_invoice` RPC.
7. Primary synced canceled status, restored stock, and ledger reversal.
8. Service-role cleanup removed all temporary rows; follow-up counts found zero
   test products and zero test customers.

The first run failed usefully: requesting 2,000 rows was capped by Supabase at
1,000, and the client incorrectly stopped pagination. The corrected second run
passed with all 1,530 current active products. The canonical workbook contributes
1,528; `oddy-01` and `s-01` are existing user-added products and were preserved.

## Final Automated Evidence

| Gate | Result |
| --- | --- |
| `bash supabase/tests/run_migrations_and_tests.sh` | pass |
| `python3 tools/test_catalog_parity.py` | pass, 30 buyers / 1,528 products |
| `bash tools/check_hybrid_runtime_cleanup.sh` | pass |
| `flutter test test` | pass, 379 tests |
| `flutter analyze` | pass, no issues |
| Release APK build | pass, 66.4 MB |
| APK ZIP integrity | pass |
| APK SHA-256 | `02b81f95b461681f26faafcaeaf7cd20ee5b179e7e6887a6967df4d6ca88cef3` |

APK: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## Physical Device Gate

Run once on the actual father and brother phones before relying on the app for
family production:

1. Install the final APK on both phones.
2. Login with each operator account and verify initial sync reaches 1,530 current
   active products, not exactly the 1,528 workbook baseline.
3. Open inventory, customers, buyers, invoices, analytics, and company profile.
4. Add one product and one customer; confirm the UI returns promptly.
5. Preview and confirm an invoice on phone A.
6. Resume or manually sync phone B and inspect invoice/PDF, stock, and ledger.
7. Cancel on phone B, resume/sync phone A, and inspect all reversals.
8. Share the PDF through the Android chooser and verify the attachment opens.
9. Temporarily disconnect data: cached screens/preview must work and official
   confirmation must show the offline block.

The current Android `release` build type still uses the local debug signing key.
That is acceptable for this controlled test APK, but a stable, backed-up private
release keystore is required before treating sideloaded installs as long-lived
production installations; future updates must be signed with the same key.

No code or data-authority blocker remains in current evidence. Physical Android
UX, OEM lifecycle behavior, and share-sheet behavior cannot be proven by the
host-only test environment.

An emulator smoke was attempted. Flutter lists `Pixel_9_API_35`, but this host's
Android SDK at `/opt/homebrew/share/android-commandlinetools` does not contain the
emulator executable and no ADB device boots. The release APK itself builds and
passes ZIP integrity; installation remains part of the physical-device gate.
