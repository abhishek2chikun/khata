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
    Future<void> Function()? dispose,
  }) : _dispose = dispose;

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
