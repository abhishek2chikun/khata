import 'dart:io';

import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'auth/session_store.dart';
import 'config/api_base_url.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_form_screen.dart';
import 'models/product.dart';
import 'screens/seller_list_screen.dart';
import 'services/api_client.dart';
import 'services/invoices_service.dart';
import 'services/payments_service.dart';
import 'services/products_service.dart';
import 'services/sellers_service.dart';

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
    required this.paymentsService,
    required this.invoicesService,
  });

  final AuthController controller;
  final ProductsService productsService;
  final SellersService sellersService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;

  @override
  State<BillingApp> createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> {
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
          home: Scaffold(
            body: _buildBody(),
          ),
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
      return InventoryListScreen(
        productsService: widget.productsService,
        onViewSellers: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => SellerListScreen(
                sellersService: widget.sellersService,
                paymentsService: widget.paymentsService,
                onCreateInvoice: (seller) async {
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
                },
              ),
            ),
          );
        },
        onLogout: widget.controller.logout,
        onAddProduct: () async {
          final result = await Navigator.of(context).push<Product>(
            MaterialPageRoute<Product>(
              builder: (_) =>
                  ProductFormScreen(productsService: widget.productsService),
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
    }

    return LoginScreen(controller: widget.controller);
  }
}
