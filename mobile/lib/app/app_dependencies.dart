import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../auth/session_store.dart';
import '../hybrid/hybrid_auth_service.dart';
import '../hybrid/hybrid_invoices_service.dart';
import '../hybrid/hybrid_rpc_client.dart';
import '../hybrid/hybrid_sync_service.dart';
import '../hybrid/hybrid_write_services.dart';
import '../hybrid/supabase_config.dart';
import '../local/local_analytics_service.dart';
import '../local/local_buyers_service.dart';
import '../local/local_company_profile_service.dart';
import '../local/local_database.dart';
import '../local/local_invoices_service.dart';
import '../local/local_product_catalog_seeder.dart';
import '../local/local_payments_service.dart';
import '../local/local_products_service.dart';
import '../local/local_customers_service.dart';
import '../services/analytics_service.dart';
import '../services/buyers_service.dart';
import '../services/company_profile_service.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import '../services/customers_service.dart';
import 'app_mode.dart';

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
    this.syncService,
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
  final HybridSyncService? syncService;
  final Future<void> Function()? _dispose;

  static Future<AppDependencies> create({
    LocalDatabase? localDatabase,
    SessionStore? sessionStore,
    CatalogJsonLoader? loadCatalogJson,
  }) async {
    final config = SupabaseConfig.fromEnvironment();
    if (config == null || !config.isConfigured) {
      throw StateError(
        'Hybrid mode requires SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.',
      );
    }

    final database =
        localDatabase ?? await LocalDatabase.openWithRecovery();
    if (loadCatalogJson != null || localDatabase == null) {
      await LocalProductCatalogSeeder(
        database: database,
        loadCatalogJson: loadCatalogJson ??
            () => rootBundle.loadString(
                  LocalProductCatalogSeeder.catalogAssetPath,
                ),
      ).seedIfNeeded();
    }

    final client = Supabase.instance.client;
    final authService = HybridAuthService(client);
    final controller = AuthController(
      authService: authService,
      sessionStore:
          sessionStore ?? SecureSessionStore(keyPrefix: 'auth.hybrid'),
    );
    final cacheRepository = HybridCacheRepository(database);
    final syncService = HybridSyncService(
      client: client,
      cacheRepository: cacheRepository,
    );
    final rpcClient = HybridRpcClient(client: client);
    final localProductsService = LocalProductsService(database: database);
    final localCustomersService = LocalCustomersService(database: database);
    final localBuyersService = LocalBuyersService(database: database);
    final localCompanyProfileService =
        LocalCompanyProfileService(database: database);
    final localPaymentsService = LocalPaymentsService(database: database);
    final localInvoicesService = LocalInvoicesService(database: database);

    Future<void> refreshAfterWrite(
      String functionName,
      Map<String, dynamic> result,
    ) async {
      await syncService.applyRpcResult(functionName, result);
      syncService.scheduleBackgroundSync();
    }

    return AppDependencies(
      mode: DataMode.hybrid,
      controller: controller,
      productsService: HybridProductsService(
        localProductsService: localProductsService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      customersService: HybridCustomersService(
        localCustomersService: localCustomersService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      buyersService: HybridBuyersService(
        localBuyersService: localBuyersService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      companyProfileService: HybridCompanyProfileService(
        localCompanyProfileService: localCompanyProfileService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      paymentsService: HybridPaymentsService(
        localPaymentsService: localPaymentsService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      invoicesService: HybridInvoicesService(
        localInvoicesService: localInvoicesService,
        rpcClient: rpcClient,
        refreshAfterWrite: refreshAfterWrite,
      ),
      analyticsService: LocalAnalyticsService(database: database),
      syncService: syncService,
      dispose: () async {
        syncService.dispose();
        await database.close();
      },
    );
  }

  Future<void> dispose() async {
    await _dispose?.call();
  }
}
