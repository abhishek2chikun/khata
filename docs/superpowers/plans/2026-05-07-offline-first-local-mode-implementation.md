# Offline-First Local Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `DATA_MODE=local` Flutter app mode that stores all business data in Drift/SQLite, keeps the existing API mode intact, and supports encrypted export/import plus scheduled Google Drive backup plumbing.

**Architecture:** Preserve current screen/service boundaries. Add a dependency composition layer that chooses API or local services. Local services use Drift transactions and domain rules ported from the backend while keeping database schema fields compatible with future Postgres migration.

**Tech Stack:** Flutter, Dart, Drift, SQLite, cryptography, file picker/share integrations, Workmanager-style scheduled background tasks, existing ChangeNotifier service interfaces.

---

## File Structure

- Modify `mobile/pubspec.yaml`: add Drift, SQLite, build runner, crypto, file picker/share, path provider, background scheduling, and Google sign-in/Drive dependencies.
- Create `mobile/lib/app/app_mode.dart`: parse `DATA_MODE` and expose `DataMode.api` / `DataMode.local`.
- Create `mobile/lib/app/app_dependencies.dart`: compose auth, product, seller, payment, invoice, company profile, and backup dependencies for API/local modes.
- Modify `mobile/lib/main.dart`: use the new dependency container instead of constructing API services inline.
- Create `mobile/lib/local/local_database.dart`: Drift database, tables, schema version, connection helper.
- Create `mobile/lib/local/local_database_connection.dart`: platform SQLite connection factory.
- Create `mobile/lib/local/local_password_hasher.dart`: local password hashing and verification.
- Create `mobile/lib/local/local_auth_service.dart`: local implementation of `AuthService` and first-user setup helpers.
- Create `mobile/lib/local/local_products_service.dart`: Drift-backed `ProductsService`.
- Create `mobile/lib/local/local_sellers_service.dart`: Drift-backed `SellersService`.
- Create `mobile/lib/local/local_payments_service.dart`: Drift-backed `PaymentsService`.
- Create `mobile/lib/local/local_company_profile_service.dart`: Drift-backed `CompanyProfileService`.
- Create `mobile/lib/local/local_invoices_service.dart`: Drift-backed `InvoicesService`.
- Create `mobile/lib/backup/backup_models.dart`: backup metadata and result models.
- Create `mobile/lib/backup/backup_crypto.dart`: encrypted backup encode/decode.
- Create `mobile/lib/backup/local_backup_service.dart`: backup export/import orchestration.
- Create `mobile/lib/backup/backup_screen.dart`: local-mode Backup/Restore UI.
- Modify `mobile/lib/widgets/app_navigation_drawer.dart`: add Backup/Restore destination in local mode.
- Create tests under `mobile/test/app/`, `mobile/test/local/`, and `mobile/test/backup/`.

## Task 1: Add App Mode Composition Skeleton

**Files:**
- Create: `mobile/lib/app/app_mode.dart`
- Create: `mobile/lib/app/app_dependencies.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/app/app_mode_test.dart`
- Test: `mobile/test/app/app_dependencies_test.dart`

- [ ] **Step 1: Write failing app mode tests**

Create `mobile/test/app/app_mode_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('parseDataMode defaults to api', () {
    expect(parseDataMode(''), DataMode.api);
  });

  test('parseDataMode accepts local', () {
    expect(parseDataMode('local'), DataMode.local);
  });

  test('parseDataMode rejects unknown values', () {
    expect(() => parseDataMode('server'), throwsArgumentError);
  });
}
```

Create `mobile/test/app/app_dependencies_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('API dependencies preserve api mode label', () async {
    final dependencies = await AppDependencies.create(mode: DataMode.api);
    expect(dependencies.mode, DataMode.api);
    await dependencies.dispose();
  });
}
```

- [ ] **Step 2: Run tests to verify red**

Run:

```bash
(cd mobile && flutter test test/app/app_mode_test.dart test/app/app_dependencies_test.dart -r expanded)
```

Expected: FAIL because `mobile/lib/app/app_mode.dart` and `mobile/lib/app/app_dependencies.dart` do not exist.

- [ ] **Step 3: Implement app mode and API dependency container**

Create `mobile/lib/app/app_mode.dart`:

```dart
enum DataMode { api, local }

const String configuredDataMode = String.fromEnvironment('DATA_MODE');

DataMode parseDataMode(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'api') {
    return DataMode.api;
  }
  if (normalized == 'local') {
    return DataMode.local;
  }
  throw ArgumentError.value(rawValue, 'DATA_MODE', 'Expected api or local');
}

DataMode resolveDataMode() => parseDataMode(configuredDataMode);
```

Create `mobile/lib/app/app_dependencies.dart`:

```dart
import 'dart:io';

import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../auth/session_store.dart';
import '../config/api_base_url.dart';
import '../services/api_client.dart';
import '../services/company_profile_service.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import '../services/sellers_service.dart';
import 'app_mode.dart';

class AppDependencies {
  AppDependencies({
    required this.mode,
    required this.controller,
    required this.productsService,
    required this.sellersService,
    required this.companyProfileService,
    required this.paymentsService,
    required this.invoicesService,
    this._dispose,
  });

  final DataMode mode;
  final AuthController controller;
  final ProductsService productsService;
  final SellersService sellersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;
  final Future<void> Function()? _dispose;

  static Future<AppDependencies> create({DataMode? mode}) async {
    final resolvedMode = mode ?? resolveDataMode();
    switch (resolvedMode) {
      case DataMode.api:
        return _createApiDependencies();
      case DataMode.local:
        throw UnimplementedError('Local data mode is added in a later task');
    }
  }

  static Future<AppDependencies> _createApiDependencies() async {
    final baseUri = await resolveApiBaseUri();
    final authService = HttpAuthService(baseUri: baseUri);
    final sessionStore = SecureSessionStore();
    final controller = AuthController(
      authService: authService,
      sessionStore: sessionStore,
    );
    final apiClient = ApiClient(
      baseUri: baseUri,
      httpClient: HttpClient(),
      authService: authService,
      sessionStore: sessionStore,
      onAuthorizationFailed: controller.logout,
    );
    return AppDependencies(
      mode: DataMode.api,
      controller: controller,
      productsService: ApiProductsService(apiClient: apiClient),
      sellersService: ApiSellersService(apiClient: apiClient),
      companyProfileService: ApiCompanyProfileService(apiClient: apiClient),
      paymentsService: ApiPaymentsService(apiClient: apiClient),
      invoicesService: ApiInvoicesService(apiClient: apiClient),
    );
  }

  Future<void> dispose() async {
    await _dispose?.call();
  }
}
```

Modify `mobile/lib/main.dart` to call `AppDependencies.create()` and pass the dependency fields into `BillingApp`.

- [ ] **Step 4: Run tests to verify green**

Run:

```bash
(cd mobile && flutter test test/app/app_mode_test.dart test/app/app_dependencies_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Run existing app shell test**

Run:

```bash
(cd mobile && flutter test test/app_shell_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add mobile/lib/app mobile/lib/main.dart mobile/test/app
git commit -m "feat: add mobile data mode composition"
```

## Task 2: Add Drift Database Schema

**Files:**
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/lib/local/local_database.dart`
- Create: `mobile/lib/local/local_database_connection.dart`
- Create: `mobile/test/local/local_database_test.dart`

- [ ] **Step 1: Add failing database schema test**

Create `mobile/test/local/local_database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

void main() {
  test('local database exposes schema version and core tables', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
    expect(database.allTables.map((table) => table.actualTableName), containsAll(<String>[
      'local_users',
      'products',
      'stock_movements',
      'sellers',
      'seller_transactions',
      'company_profiles',
      'invoices',
      'invoice_items',
      'local_sessions',
      'backup_events',
      'backup_settings',
    ]));
  });
}
```

- [ ] **Step 2: Run test to verify red**

Run:

```bash
(cd mobile && flutter test test/local/local_database_test.dart -r expanded)
```

Expected: FAIL because Drift dependencies and `LocalDatabase` do not exist.

- [ ] **Step 3: Add dependencies**

Modify `mobile/pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.6
  drift: ^2.26.0
  sqlite3_flutter_libs: ^0.5.32
  path: ^1.9.1
  path_provider: ^2.1.5

dev_dependencies:
  build_runner: ^2.4.15
  drift_dev: ^2.26.0
  flutter_test:
    sdk: flutter
```

- [ ] **Step 4: Implement Drift database skeleton**

Create `mobile/lib/local/local_database_connection.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openLocalDatabaseConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'khata_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

Create `mobile/lib/local/local_database.dart` with Drift tables for all names in the test. Store money/quantity fields as text decimal strings for Postgres compatibility. Include `LocalDatabase.memory()` using `NativeDatabase.memory()` for tests.

- [ ] **Step 5: Generate Drift code**

Run:

```bash
(cd mobile && flutter pub get && dart run build_runner build --delete-conflicting-outputs)
```

Expected: generated `mobile/lib/local/local_database.g.dart`.

- [ ] **Step 6: Run test to verify green**

Run:

```bash
(cd mobile && flutter test test/local/local_database_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add mobile/pubspec.yaml mobile/pubspec.lock mobile/lib/local mobile/test/local/local_database_test.dart
git commit -m "feat: add drift local database schema"
```

## Task 3: Local Auth And First User Setup Core

**Files:**
- Create: `mobile/lib/local/local_password_hasher.dart`
- Create: `mobile/lib/local/local_auth_service.dart`
- Modify: `mobile/lib/app/app_dependencies.dart`
- Test: `mobile/test/local/local_auth_service_test.dart`

- [ ] **Step 1: Write failing local auth tests**

Create `mobile/test/local/local_auth_service_test.dart` with tests that create first user, reject duplicate username, login successfully, reject wrong password, return `me`, and clear local session on logout.

- [ ] **Step 2: Run test to verify red**

Run:

```bash
(cd mobile && flutter test test/local/local_auth_service_test.dart -r expanded)
```

Expected: FAIL because local auth service does not exist.

- [ ] **Step 3: Implement password hasher and local auth**

Use `crypto` with random salt and repeated SHA-256 rounds for this first implementation. Store `salt`, `password_hash`, and `password_hash_version` in `local_users`. Throw `AuthException('Invalid username or password', statusCode: 401, code: 'INVALID_CREDENTIALS')` for wrong login.

- [ ] **Step 4: Wire local mode dependencies to local auth placeholder services**

Modify `AppDependencies.create(mode: DataMode.local)` to open `LocalDatabase`, create `LocalAuthService`, and use temporary throwing local service placeholders for non-auth services until later tasks replace them.

- [ ] **Step 5: Run local auth tests**

Run:

```bash
(cd mobile && flutter test test/local/local_auth_service_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add mobile/lib/local mobile/lib/app/app_dependencies.dart mobile/test/local/local_auth_service_test.dart
git commit -m "feat: add local auth service"
```

## Task 4: Local Products Service

**Files:**
- Create: `mobile/lib/local/local_products_service.dart`
- Test: `mobile/test/local/local_products_service_test.dart`

- [ ] **Step 1: Write failing product service tests**

Create tests for create, list, search filter, company/category filter, low stock filter, update, and duplicate rejection.

- [ ] **Step 2: Run red test**

Run:

```bash
(cd mobile && flutter test test/local/local_products_service_test.dart -r expanded)
```

Expected: FAIL because `LocalProductsService` does not exist.

- [ ] **Step 3: Implement local products service**

Implement `ProductsService` with Drift inserts/queries/updates. Generate UUID strings with a small local helper. Preserve decimal values as normalized strings in Drift and convert to `double` at model boundaries.

- [ ] **Step 4: Run green test**

Run:

```bash
(cd mobile && flutter test test/local/local_products_service_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/lib/local mobile/test/local/local_products_service_test.dart
git commit -m "feat: add local products service"
```

## Task 5: Local Sellers And Payments Services

**Files:**
- Create: `mobile/lib/local/local_sellers_service.dart`
- Create: `mobile/lib/local/local_payments_service.dart`
- Test: `mobile/test/local/local_sellers_payments_service_test.dart`

- [ ] **Step 1: Write failing sellers/payments tests**

Create tests for seller creation, list/search, opening balance, payment, balance adjustment, and ledger ordering.

- [ ] **Step 2: Run red test**

Run:

```bash
(cd mobile && flutter test test/local/local_sellers_payments_service_test.dart -r expanded)
```

Expected: FAIL because local services do not exist.

- [ ] **Step 3: Implement local sellers and payments**

Implement `SellersService` and `PaymentsService` using `sellers` and `seller_transactions`. Keep pending balance computed from transactions so imports remain auditable.

- [ ] **Step 4: Run green test**

Run:

```bash
(cd mobile && flutter test test/local/local_sellers_payments_service_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/lib/local mobile/test/local/local_sellers_payments_service_test.dart
git commit -m "feat: add local sellers and payments services"
```

## Task 6: Local Company Profile And Invoice Services

**Files:**
- Create: `mobile/lib/local/local_company_profile_service.dart`
- Create: `mobile/lib/local/local_invoices_service.dart`
- Test: `mobile/test/local/local_company_profile_service_test.dart`
- Test: `mobile/test/local/local_invoices_service_test.dart`

- [ ] **Step 1: Write failing company and invoice tests**

Create company profile tests for upsert/fetch. Create invoice tests for quote, create, list, detail, cancellation, stock reduction, ledger debit, and cancellation reversal.

- [ ] **Step 2: Run red tests**

Run:

```bash
(cd mobile && flutter test test/local/local_company_profile_service_test.dart test/local/local_invoices_service_test.dart -r expanded)
```

Expected: FAIL because local services do not exist.

- [ ] **Step 3: Implement local company profile and invoices**

Port minimal backend rules needed by existing UI: tax calculation, seller/company/product snapshots, invoice numbering, stock movement writes, seller transaction writes, and cancellation reversal.

- [ ] **Step 4: Run green tests**

Run:

```bash
(cd mobile && flutter test test/local/local_company_profile_service_test.dart test/local/local_invoices_service_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/lib/local mobile/test/local/local_company_profile_service_test.dart mobile/test/local/local_invoices_service_test.dart
git commit -m "feat: add local invoices and company profile"
```

## Task 7: Wire Local Mode End-To-End

**Files:**
- Modify: `mobile/lib/app/app_dependencies.dart`
- Modify: `mobile/lib/main.dart`
- Create: `mobile/lib/screens/local_first_user_setup_screen.dart`
- Test: `mobile/test/app/local_mode_app_test.dart`

- [ ] **Step 1: Write failing local mode app test**

Create a widget test that starts `BillingApp` with local dependencies, shows first-user setup when no user exists, creates user, logs in, and reaches inventory.

- [ ] **Step 2: Run red test**

Run:

```bash
(cd mobile && flutter test test/app/local_mode_app_test.dart -r expanded)
```

Expected: FAIL because setup UI and full local dependency wiring do not exist.

- [ ] **Step 3: Implement setup screen and full local dependency wiring**

Add setup screen before login when local mode has no local users. Replace placeholder local services with real implementations.

- [ ] **Step 4: Run green test**

Run:

```bash
(cd mobile && flutter test test/app/local_mode_app_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/lib/app mobile/lib/main.dart mobile/lib/screens/local_first_user_setup_screen.dart mobile/test/app/local_mode_app_test.dart
git commit -m "feat: wire offline local app mode"
```

## Task 8: Backup Export/Import Core

**Files:**
- Create: `mobile/lib/backup/backup_models.dart`
- Create: `mobile/lib/backup/backup_crypto.dart`
- Create: `mobile/lib/backup/local_backup_service.dart`
- Test: `mobile/test/backup/backup_crypto_test.dart`
- Test: `mobile/test/backup/local_backup_service_test.dart`

- [ ] **Step 1: Write failing backup tests**

Create tests for encrypted export package, wrong password rejection, invalid version rejection, export/import round trip with products/sellers/invoices.

- [ ] **Step 2: Run red tests**

Run:

```bash
(cd mobile && flutter test test/backup/backup_crypto_test.dart test/backup/local_backup_service_test.dart -r expanded)
```

Expected: FAIL because backup files do not exist.

- [ ] **Step 3: Implement backup core**

Implement JSON backup payload with `schema_version`, `backend_compatibility_version`, `exported_at`, table payloads, and encrypted payload bytes. Use authenticated encryption from a maintained Dart crypto package or a clear AES-GCM package added to `pubspec.yaml`.

- [ ] **Step 4: Run green tests**

Run:

```bash
(cd mobile && flutter test test/backup/backup_crypto_test.dart test/backup/local_backup_service_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/pubspec.yaml mobile/pubspec.lock mobile/lib/backup mobile/test/backup
git commit -m "feat: add encrypted local backup import export"
```

## Task 9: Backup UI And Scheduled Drive Backup Plumbing

**Files:**
- Create: `mobile/lib/backup/backup_screen.dart`
- Create: `mobile/lib/backup/drive_backup_service.dart`
- Create: `mobile/lib/backup/backup_scheduler.dart`
- Modify: `mobile/lib/widgets/app_navigation_drawer.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/backup/backup_screen_test.dart`
- Test: `mobile/test/backup/backup_scheduler_test.dart`

- [ ] **Step 1: Write failing backup UI/scheduler tests**

Create widget tests for backup screen showing last backup, export/import buttons, and configured daily time. Create scheduler tests that compute due/missed backup behavior around midnight.

- [ ] **Step 2: Run red tests**

Run:

```bash
(cd mobile && flutter test test/backup/backup_screen_test.dart test/backup/backup_scheduler_test.dart -r expanded)
```

Expected: FAIL because UI and scheduler do not exist.

- [ ] **Step 3: Implement backup UI and scheduler interfaces**

Add Backup/Restore drawer destination in local mode. Add export/import buttons. Add settings for daily backup time defaulting to midnight. Add `DriveBackupService` interface plus a real implementation skeleton that requires Google Drive configuration and a fake implementation for tests. Add background scheduling wrapper with catch-up on next app launch.

- [ ] **Step 4: Run green tests**

Run:

```bash
(cd mobile && flutter test test/backup/backup_screen_test.dart test/backup/backup_scheduler_test.dart -r expanded)
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add mobile/lib/backup mobile/lib/widgets/app_navigation_drawer.dart mobile/lib/main.dart mobile/test/backup
git commit -m "feat: add backup restore UI and scheduler"
```

## Task 10: Documentation And Full Verification

**Files:**
- Modify: `README.md`
- Modify: `mobile/agent.md`
- Test: no new test file

- [ ] **Step 1: Update documentation**

Document API/local run commands, local setup flow, backup export/import, automatic Drive backup configuration, and future server migration compatibility.

- [ ] **Step 2: Run full mobile tests**

Run:

```bash
(cd mobile && flutter test test -r expanded)
```

Expected: PASS.

- [ ] **Step 3: Run local mode on emulator smoke check**

Run:

```bash
(cd mobile && flutter run -d emulator-5554 --dart-define=DATA_MODE=local)
```

Expected: app starts without API/backend, shows local setup or login.

- [ ] **Step 4: Commit**

Run:

```bash
git add README.md mobile/agent.md
git commit -m "docs: document offline local mode"
```

## Self-Review Notes

- Spec coverage: The plan covers local Drift schema, local auth, local service implementations, app mode toggle, backup export/import, automatic Drive backup scheduling, and schema compatibility for future server migration.
- Scope note: Direct Google Drive API production OAuth setup may require external Firebase/Google Cloud configuration outside repository control. The code should provide interfaces and documented setup, but real credentials cannot be committed.
- Placeholder scan: No task uses `TBD`, `TODO`, or unspecified code-only instructions as completion criteria.
