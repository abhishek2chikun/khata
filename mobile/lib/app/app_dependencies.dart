import 'dart:io';

import 'package:drift/drift.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../auth/session_store.dart';
import '../backup/backup_scheduler.dart';
import '../backup/drive_backup_service.dart';
import '../config/api_base_url.dart';
import '../local/local_auth_service.dart';
import '../local/local_buyers_service.dart';
import '../local/local_company_profile_service.dart';
import '../local/local_database.dart';
import '../local/local_invoices_service.dart';
import '../local/local_payments_service.dart';
import '../local/local_products_service.dart';
import '../local/local_sellers_service.dart';
import '../services/api_client.dart';
import '../services/buyers_service.dart';
import '../services/company_profile_service.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import '../services/sellers_service.dart';
import 'app_mode.dart';

typedef ApiHttpClientsCreated = void Function(
  HttpClient authHttpClient,
  HttpClient apiHttpClient,
);

class AppDependencies {
  AppDependencies({
    required this.mode,
    required this.controller,
    required this.productsService,
    required this.sellersService,
    required this.buyersService,
    required this.companyProfileService,
    required this.paymentsService,
    required this.invoicesService,
    this.localAuthService,
    this.hasLocalUsers,
    this.driveBackupService,
    this.backupScheduler,
    Future<void> Function()? dispose,
  }) : _dispose = dispose;

  final DataMode mode;
  final AuthController controller;
  final ProductsService productsService;
  final SellersService sellersService;
  final BuyersService buyersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;
  final LocalAuthService? localAuthService;
  final Future<bool> Function()? hasLocalUsers;
  final DriveBackupService? driveBackupService;
  final BackupScheduler? backupScheduler;
  final Future<void> Function()? _dispose;

  static Future<AppDependencies> create({
    DataMode? mode,
    Uri? apiBaseUri,
    LocalDatabase? localDatabase,
    SessionStore? sessionStore,
    ApiHttpClientsCreated? onApiHttpClientsCreated,
  }) async {
    final resolvedMode = mode ?? resolveDataMode();
    switch (resolvedMode) {
      case DataMode.api:
        return _createApiDependencies(
          apiBaseUri: apiBaseUri,
          onApiHttpClientsCreated: onApiHttpClientsCreated,
        );
      case DataMode.local:
        return _createLocalDependencies(
          database: localDatabase,
          sessionStore: sessionStore,
        );
    }
  }

  static Future<AppDependencies> _createLocalDependencies({
    LocalDatabase? database,
    SessionStore? sessionStore,
  }) async {
    final localDatabase = database ?? LocalDatabase();
    final authService = LocalAuthService(database: localDatabase);
    final backupService = LocalDriveBackupService(database: localDatabase);
    final controller = AuthController(
      authService: authService,
      sessionStore: sessionStore ?? SecureSessionStore(keyPrefix: 'auth.local'),
    );
    return AppDependencies(
      mode: DataMode.local,
      controller: controller,
      productsService: LocalProductsService(database: localDatabase),
      sellersService: LocalSellersService(database: localDatabase),
      buyersService: LocalBuyersService(database: localDatabase),
      companyProfileService:
          LocalCompanyProfileService(database: localDatabase),
      paymentsService: LocalPaymentsService(database: localDatabase),
      invoicesService: LocalInvoicesService(database: localDatabase),
      localAuthService: authService,
      driveBackupService: backupService,
      backupScheduler: BackupScheduler(
        settingsLoader: backupService.loadSettings,
        runBackup: backupService.exportBackup,
        eventRecorder: LocalBackupEventRecorder(database: localDatabase),
      ),
      hasLocalUsers: () async {
        final users = await (localDatabase.select(localDatabase.localUsers)
              ..limit(1))
            .get();
        return users.isNotEmpty;
      },
      dispose: localDatabase.close,
    );
  }

  static Future<AppDependencies> _createApiDependencies({
    Uri? apiBaseUri,
    ApiHttpClientsCreated? onApiHttpClientsCreated,
  }) async {
    final baseUri = apiBaseUri ?? await resolveApiBaseUri();
    final authHttpClient = HttpClient();
    final apiHttpClient = HttpClient();
    onApiHttpClientsCreated?.call(authHttpClient, apiHttpClient);
    final authService = HttpAuthService(
      baseUri: baseUri,
      httpClient: authHttpClient,
    );
    final sessionStore = SecureSessionStore();
    final controller = AuthController(
      authService: authService,
      sessionStore: sessionStore,
    );
    final apiClient = ApiClient(
      baseUri: baseUri,
      httpClient: apiHttpClient,
      authService: authService,
      sessionStore: sessionStore,
      onAuthorizationFailed: controller.logout,
    );
    return AppDependencies(
      mode: DataMode.api,
      controller: controller,
      productsService: ApiProductsService(apiClient: apiClient),
      sellersService: ApiSellersService(apiClient: apiClient),
      buyersService: ApiBuyersService(apiClient: apiClient),
      companyProfileService: ApiCompanyProfileService(apiClient: apiClient),
      paymentsService: ApiPaymentsService(apiClient: apiClient),
      invoicesService: ApiInvoicesService(apiClient: apiClient),
      dispose: () async {
        authHttpClient.close(force: true);
        apiHttpClient.close(force: true);
      },
    );
  }

  Future<void> dispose() async {
    await _dispose?.call();
  }
}
