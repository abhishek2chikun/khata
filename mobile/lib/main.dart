import 'dart:io';

import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'auth/session_store.dart';
import 'config/api_base_url.dart';
import 'models/seller.dart';
import 'screens/company_profile_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_form_screen.dart';
import 'models/product.dart';
import 'screens/seller_list_screen.dart';
import 'services/api_client.dart';
import 'services/company_profile_service.dart';
import 'services/invoices_service.dart';
import 'services/payments_service.dart';
import 'services/products_service.dart';
import 'services/sellers_service.dart';
import 'widgets/app_navigation_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  runApp(
    BillingApp(
      controller: controller,
      productsService: ApiProductsService(apiClient: apiClient),
      sellersService: ApiSellersService(apiClient: apiClient),
      companyProfileService: ApiCompanyProfileService(apiClient: apiClient),
      paymentsService: ApiPaymentsService(apiClient: apiClient),
      invoicesService: ApiInvoicesService(apiClient: apiClient),
    ),
  );
}

class BillingApp extends StatefulWidget {
  const BillingApp({
    super.key,
    required this.controller,
    required this.productsService,
    required this.sellersService,
    required this.companyProfileService,
    required this.paymentsService,
    required this.invoicesService,
  });

  final AuthController controller;
  final ProductsService productsService;
  final SellersService sellersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;

  @override
  State<BillingApp> createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> {
  AppDestination _selectedDestination = AppDestination.inventory;

  @override
  void initState() {
    super.initState();
    widget.controller.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Internal Billing',
          home: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (widget.controller.isRestoringSession) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.controller.isAuthenticated) {
      final drawer = AppNavigationDrawer(
        selected: _selectedDestination,
        onSelect: (destination) {
          setState(() {
            _selectedDestination = destination;
          });
        },
        onLogout: widget.controller.logout,
      );

      switch (_selectedDestination) {
        case AppDestination.inventory:
          return InventoryListScreen(
            drawer: drawer,
            productsService: widget.productsService,
            onAddProduct: () async {
              final result = await Navigator.of(context).push<Product>(
                MaterialPageRoute<Product>(
                  builder: (_) => ProductFormScreen(
                      productsService: widget.productsService),
                ),
              );
              return result != null;
            },
            onEditProduct: (product) async {
              final result = await Navigator.of(context).push<Product>(
                MaterialPageRoute<Product>(
                  builder: (_) => ProductFormScreen(
                    productsService: widget.productsService,
                    product: product,
                  ),
                ),
              );
              return result != null;
            },
          );
        case AppDestination.sellers:
          return SellerListScreen(
            drawer: drawer,
            sellersService: widget.sellersService,
            paymentsService: widget.paymentsService,
            onCreateInvoice: _openCreateInvoiceForSeller,
          );
        case AppDestination.invoices:
          return InvoiceListScreen(
            drawer: drawer,
            invoicesService: widget.invoicesService,
            productsService: widget.productsService,
            sellersService: widget.sellersService,
          );
        case AppDestination.companyProfile:
          return CompanyProfileScreen(
            drawer: drawer,
            companyProfileService: widget.companyProfileService,
          );
      }
    }

    return Scaffold(
      body: LoginScreen(controller: widget.controller),
    );
  }

  Future<bool> _openCreateInvoiceForSeller(Seller seller) async {
    final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CreateInvoiceScreen(
              invoicesService: widget.invoicesService,
              productsService: widget.productsService,
              sellersService: widget.sellersService,
              initialSeller: seller,
            ),
          ),
        ) ??
        false;
    return created;
  }
}
