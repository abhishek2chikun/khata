import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:workmanager/workmanager.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../auth/session_store.dart';
import '../backup/backup_background_callback.dart';
import '../backup/backup_scheduler.dart';
import '../backup/drive_backup_service.dart';
import '../backup/drive_platform.dart';
import '../backup/encrypted_drive_backup_orchestrator.dart';
import '../backup/google_auth_gateway.dart';
import '../backup/google_drive_gateway.dart';
import '../backup/local_backup_transfer_service.dart';
import '../backup/secure_backup_secret_store.dart';
import '../backup/workmanager_schedule_adapter.dart';
import '../config/api_base_url.dart';
import '../local/local_analytics_service.dart';
import '../local/local_auth_service.dart';
import '../local/local_buyers_service.dart';
import '../local/local_company_profile_service.dart';
import '../local/local_database.dart';
import '../local/local_invoices_service.dart';
import '../local/local_product_catalog_seeder.dart';
import '../local/local_payments_service.dart';
import '../local/local_products_service.dart';
import '../local/local_customers_service.dart';
import '../services/api_analytics_service.dart';
import '../services/api_client.dart';
import '../services/analytics_service.dart';
import '../services/buyers_service.dart';
import '../services/company_profile_service.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import '../services/customers_service.dart';
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
    required this.customersService,
    required this.buyersService,
    required this.companyProfileService,
    required this.paymentsService,
    required this.invoicesService,
    required this.analyticsService,
    this.localAuthService,
    this.hasLocalUsers,
    this.driveBackupService,
    this.backupTransferService,
    this.backupScheduler,
    Future<void> Function()? dispose,
  }) : _dispose = dispose;

  final DataMode mode;
  final AuthController controller;
  final ProductsService productsService;
  final CustomersService customersService;
  final BuyersService buyersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;
  final AnalyticsService analyticsService;
  final LocalAuthService? localAuthService;
  final Future<bool> Function()? hasLocalUsers;
  final DriveBackupService? driveBackupService;
  final BackupTransferService? backupTransferService;
  final BackupScheduler? backupScheduler;
  final Future<void> Function()? _dispose;

  static Future<AppDependencies> create({
    DataMode? mode,
    Uri? apiBaseUri,
    LocalDatabase? localDatabase,
    SessionStore? sessionStore,
    ApiHttpClientsCreated? onApiHttpClientsCreated,
    CatalogJsonLoader? loadCatalogJson,
    GoogleAuthGateway? authGateway,
    BackupSecretStore? backupSecretStore,
    BackupScheduleAdapter? backupScheduleAdapter,
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
          loadCatalogJson: loadCatalogJson,
          authGateway: authGateway,
          backupSecretStore: backupSecretStore,
          backupScheduleAdapter: backupScheduleAdapter,
        );
    }
  }

  static Future<AppDependencies> _createLocalDependencies({
    LocalDatabase? database,
    SessionStore? sessionStore,
    CatalogJsonLoader? loadCatalogJson,
    GoogleAuthGateway? authGateway,
    BackupSecretStore? backupSecretStore,
    BackupScheduleAdapter? backupScheduleAdapter,
  }) async {
    final localDatabase = database ?? LocalDatabase();
    if (loadCatalogJson != null || database == null) {
      await LocalProductCatalogSeeder(
        database: localDatabase,
        loadCatalogJson: loadCatalogJson ??
            () => rootBundle.loadString(
                  LocalProductCatalogSeeder.catalogAssetPath,
                ),
      ).seedIfNeeded();
    }
    final authService = LocalAuthService(database: localDatabase);
    final backupTransferService =
        LocalBackupTransferService(database: localDatabase);
    final googleAuthGateway =
        authGateway is GoogleSignInAuthGateway
            ? authGateway
            : GoogleSignInAuthGateway();
    final resolvedSecretStore =
        backupSecretStore ?? FlutterSecureBackupSecretStore();
    final scheduleAdapter =
        backupScheduleAdapter ?? WorkManagerBackupScheduleAdapter();
    auth.AuthClient? foregroundAuthClient;
    final orchestrator = EncryptedDriveBackupOrchestrator(
      database: localDatabase,
      authGateway: googleAuthGateway,
      secretStore: resolvedSecretStore,
      driveGatewayFactory: () async {
        foregroundAuthClient?.close();
        foregroundAuthClient = await googleAuthGateway.createDriveAuthClient(
          promptIfUnauthorized: true,
        );
        if (foregroundAuthClient == null) {
          throw const DriveBackupConfigurationException(
            'Google Drive authorization is required.',
          );
        }
        return GoogleApisDriveGateway(client: foregroundAuthClient!);
      },
    );
    final backupService = EncryptedDriveBackupService(
      database: localDatabase,
      authGateway: googleAuthGateway,
      orchestrator: orchestrator,
      scheduleAdapter: scheduleAdapter,
      secretStore: resolvedSecretStore,
    );
    final backupScheduler = BackupScheduler(
      settingsLoader: backupService.loadSettings,
      runBackup: backupService.backupToDriveNow,
      scheduleAdapter: scheduleAdapter,
      eventRecorder: LocalBackupEventRecorder(database: localDatabase),
    );
    final controller = AuthController(
      authService: authService,
      sessionStore: sessionStore ?? SecureSessionStore(keyPrefix: 'auth.local'),
    );
    return AppDependencies(
      mode: DataMode.local,
      controller: controller,
      productsService: LocalProductsService(database: localDatabase),
      customersService: LocalCustomersService(database: localDatabase),
      buyersService: LocalBuyersService(database: localDatabase),
      companyProfileService:
          LocalCompanyProfileService(database: localDatabase),
      paymentsService: LocalPaymentsService(database: localDatabase),
      invoicesService: LocalInvoicesService(database: localDatabase),
      analyticsService: LocalAnalyticsService(database: localDatabase),
      localAuthService: authService,
      driveBackupService: backupService,
      backupTransferService: backupTransferService,
      backupScheduler: backupScheduler,
      hasLocalUsers: () async {
        final users = await (localDatabase.select(localDatabase.localUsers)
              ..limit(1))
            .get();
        return users.isNotEmpty;
      },
      dispose: () async {
        foregroundAuthClient?.close();
        await localDatabase.close();
      },
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
      customersService: ApiCustomersService(apiClient: apiClient),
      buyersService: ApiBuyersService(apiClient: apiClient),
      companyProfileService: ApiCompanyProfileService(apiClient: apiClient),
      paymentsService: ApiPaymentsService(apiClient: apiClient),
      invoicesService: ApiInvoicesService(apiClient: apiClient),
      analyticsService: ApiAnalyticsService(apiClient: apiClient),
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

Future<void> initializeLocalBackupPlatformServices() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return;
  }
  await Workmanager().initialize(
    backupWorkmanagerCallbackDispatcher,
    isInDebugMode: kDebugMode,
  );
}
