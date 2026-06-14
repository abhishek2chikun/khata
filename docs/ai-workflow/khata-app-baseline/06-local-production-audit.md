# Local Mobile Production Audit

## Verdict
code-ready-for-phone-testing; production-release-blocked

## Scope
Local SQLite mobile mode only. API/PostgreSQL deployment is not part of this runtime verdict.

## Product Decisions Verified
- Four invoice variants remain supported: A5 GST, A5 non-GST, A4 GST, and A4 non-GST.
- Up to 15 line items is an A5 candidate, not a guarantee. The generated document must fit one A5 page; otherwise it is regenerated as A4.
- More than 15 line items starts as A4.
- GST identity and tax sections are omitted from non-GST invoices.

## Fixes Added During The Audit
- Local analytics now uses taxable revenue and canonical profit instead of GST-inclusive line totals.
- Invoice creation from the invoice-list route now receives the company profile and exposes the GST/non-GST choice for GST sellers.
- Invoice list displays payment state rather than payment mode.
- Manual encrypted backup export/import is connected to Android file sharing and file selection, with password validation, audit events, restore replacement semantics, and logout after restore.
- Misleading automatic cloud-backup controls were removed; the UI states that cloud backup is not configured.
- The intended Flutter lint rules are now resolvable.
- The obsolete timezone validator was removed after date-only invoice creation became canonical.
- Android launcher label is now `Khata`.

## Fresh Automated Evidence
| Gate | Result |
|---|---|
| `flutter test --coverage test` | Exit 0, full mobile suite passed |
| Focused company-profile and invoice-list widget tests | 4 passed |
| Focused backup transfer tests | 5 passed |
| `flutter analyze` | No errors; 43 legacy warning/info findings remain |
| Release APK build | Passed with `DATA_MODE=local` |

## Emulator Runtime Evidence
Pixel 9 API 35, package `com.example.internal_billing_khata_mobile`:

- APK installed successfully with `adb install -r`.
- Explicit cold launch of `.MainActivity` succeeded and became the focused activity.
- First local user was created and authenticated.
- Local SQLite startup and preinstalled product-catalog seeding rendered successfully.
- Navigation drawer, Company Profile screen, GST seller toggle, Backup & Restore screen, and encrypted-export password dialog rendered successfully.
- No fatal Android exception was observed during this smoke path.

## APK
- Path: `mobile/build/app/outputs/flutter-apk/app-release.apk`
- Size: 63,198,682 bytes
- SHA-256: `bcbb0bcba2a4c6778e77807803467bbac9ddb9b8a4880985128f2f5c1ab9c52e`

## Blocking Release Findings
1. Android still uses the example application ID `com.example.internal_billing_khata_mobile`.
2. The release build still uses debug signing. A permanent keystore and protected signing configuration are required before distribution.
3. Physical-device evidence is still required for WhatsApp/share chooser attachment behavior, encrypted backup export destination, restore from a selected file, and restart persistence.
4. PDF Helvetica does not support non-Latin customer/product text.

## Non-Blocking Debt
- Analyzer reports legacy style/deprecation/test warnings but no compile errors.
- Dependency upgrades are available and should be handled separately from this release slice.

## Exact Next Action
Choose the permanent Android application ID and provide or authorize creation of a release keystore; then build a signed candidate and run the physical-device share, backup/restore, invoice cancellation, and restart-persistence matrix.
