# Mobile — agent.md

Role: Flutter client for login, inventory, seller ledger, payments, and invoice creation against the FastAPI backend.

## How to use this system

- Start the backend first; this app is a thin authenticated client and does not work meaningfully offline.
- Prefer running against `8010` right now. Android emulator support is built around `10.0.2.2` and optional `adb reverse`.
- Keep business rules in the backend. Mobile should mirror backend DTOs and surface backend validation clearly.
- Secure storage is only for auth session data. Invoice draft state is transient in memory.

## Project overview

The app currently supports:

- username/password login
- secure session restore via refresh token
- inventory list with add/edit product flow
- seller list and seller detail
- payment recording, opening balance, and balance adjustment
- invoice create → preview → confirm flow

Important live behavior:

- API base URL is auto-discovered at startup from common local development targets, or can be forced with `--dart-define=API_BASE_URL=...`.
- Auth uses `HttpAuthService`, `SecureSessionStore`, and `AuthController`.
- All non-auth API calls go through `ApiClient`, which retries once after token refresh on `401`.
- Seller detail doubles as the current invoice-history surface.

## Directory structure

```text
mobile/
  agent.md
  pubspec.yaml
  analysis_options.yaml
  lib/
    main.dart
    auth/
    config/
    models/
    screens/
    services/
    state/
    widgets/
  test/
    auth/
    config/
    services/
    state/
    widgets/
    app_shell_test.dart
```

## Module status

| Module | Status | Location | `agent.md` |
|---|---|---|---|
| App composition | Done | `mobile/lib/main.dart` | None yet |
| Auth/session | Done | `mobile/lib/auth/` | None yet |
| API base URL resolution | Done | `mobile/lib/config/api_base_url.dart` | None yet |
| Shared API client | Done | `mobile/lib/services/api_client.dart` | None yet |
| Products flow | Done | `mobile/lib/services/products_service.dart`, `mobile/lib/screens/inventory_list_screen.dart`, `mobile/lib/screens/product_form_screen.dart` | None yet |
| Sellers + ledger flow | Done | `mobile/lib/services/sellers_service.dart`, `mobile/lib/screens/seller_list_screen.dart`, `mobile/lib/screens/seller_detail_screen.dart` | None yet |
| Payments flow | Done | `mobile/lib/services/payments_service.dart`, `mobile/lib/screens/record_payment_screen.dart`, `mobile/lib/screens/opening_balance_screen.dart`, `mobile/lib/screens/balance_adjustment_screen.dart` | None yet |
| Invoice flow | Done — needs UX expansion | `mobile/lib/services/invoices_service.dart`, `mobile/lib/state/invoice_draft_controller.dart`, `mobile/lib/screens/create_invoice_screen.dart`, `mobile/lib/screens/invoice_preview_screen.dart` | None yet |
| Company profile client | In Progress | `mobile/lib/services/company_profile_service.dart` | None yet |
| Widget/test coverage | Done — focused flows covered | `mobile/test/` | None yet |

## Conventions

- Use `ApiClient` for authenticated JSON requests instead of ad-hoc `HttpClient` calls in feature code.
- Keep request/response field names aligned with backend JSON exactly.
- Preserve current state ownership:
  - auth session: `SecureSessionStore`
  - auth flow state: `AuthController`
  - invoice draft state: `InvoiceDraftController`
- The app currently uses `ChangeNotifier` + `AnimatedBuilder`, not a heavier state-management library.
- API URL selection comes from `API_BASE_URL` first, then local dev auto-detection.

## Verification commands

```bash
# Install dependencies
(cd /Users/abhishek/python_venv/khata_app/mobile && flutter pub get)

# Run on Android emulator against the current backend port
(cd /Users/abhishek/python_venv/khata_app/mobile && \
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8010/)

# Run using adb reverse instead
adb reverse tcp:8010 tcp:8010
(cd /Users/abhishek/python_venv/khata_app/mobile && \
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://localhost:8010/)

# Run mobile tests
(cd /Users/abhishek/python_venv/khata_app/mobile && flutter test test)
```

## Progress

- Login is working against the current local backend setup.
- Inventory and seller flows now have realistic dev data available through the backend demo seed command.
- The app can create and confirm invoices, and seller detail refreshes can reflect resulting ledger changes.
- Local backend discovery now handles `8010` and emulator-friendly hosts.

## Deferred work

- `mobile/lib/services/company_profile_service.dart` exists, but there is no company-profile UI yet.
- There is no dedicated invoice list/detail/cancel UI outside seller detail history and the create flow.
- There is no UI for product archive, seller archive, or manual stock adjustment even though backend APIs exist.
- The invoice screen currently exposes a single line-item form; multi-line invoice authoring is not surfaced yet.
- `mobile/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, but `flutter_lints` is not listed in `pubspec.yaml`, so analyzer/format tooling may warn until that is reconciled.
