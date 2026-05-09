import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'app/app_dependencies.dart';
import 'app/app_mode.dart';
import 'backup/backup_scheduler.dart';
import 'backup/backup_screen.dart';
import 'backup/drive_backup_service.dart';
import 'models/seller.dart';
import 'screens/buyer_list_screen.dart';
import 'screens/company_profile_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/local_first_user_setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
import 'models/product.dart';
import 'screens/seller_list_screen.dart';
import 'services/company_profile_service.dart';
import 'services/buyers_service.dart';
import 'services/invoices_service.dart';
import 'services/payments_service.dart';
import 'services/products_service.dart';
import 'services/sellers_service.dart';
import 'widgets/app_navigation_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.create();
  runApp(
    BillingApp(
      dependencies: dependencies,
    ),
  );
}

class BillingApp extends StatefulWidget {
  BillingApp({
    super.key,
    AppDependencies? dependencies,
    AuthController? controller,
    ProductsService? productsService,
    SellersService? sellersService,
    BuyersService? buyersService,
    CompanyProfileService? companyProfileService,
    PaymentsService? paymentsService,
    InvoicesService? invoicesService,
    DriveBackupService? driveBackupService,
    BackupScheduler? backupScheduler,
  })  : dependencies = dependencies,
        controller = controller ?? dependencies!.controller,
        productsService = productsService ?? dependencies!.productsService,
        sellersService = sellersService ?? dependencies!.sellersService,
        buyersService = buyersService ?? dependencies!.buyersService,
        companyProfileService =
            companyProfileService ?? dependencies!.companyProfileService,
        paymentsService = paymentsService ?? dependencies!.paymentsService,
        invoicesService = invoicesService ?? dependencies!.invoicesService,
        driveBackupService =
            driveBackupService ?? dependencies?.driveBackupService,
        backupScheduler = backupScheduler ?? dependencies?.backupScheduler;

  final AppDependencies? dependencies;
  final AuthController controller;
  final ProductsService productsService;
  final SellersService sellersService;
  final BuyersService buyersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;
  final DriveBackupService? driveBackupService;
  final BackupScheduler? backupScheduler;

  @override
  State<BillingApp> createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> {
  AppDestination _selectedDestination = AppDestination.inventory;
  bool _isCheckingLocalUsers = false;
  bool _needsLocalFirstUserSetup = false;
  bool _didStartLocalBackupScheduling = false;

  @override
  void initState() {
    super.initState();
    _checkLocalUsers();
    widget.controller.restoreSession();
  }

  @override
  void dispose() {
    final dependencies = widget.dependencies;
    if (dependencies != null) {
      Future<void>.microtask(dependencies.dispose);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Internal Billing',
          home: Builder(builder: _buildBody),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isCheckingLocalUsers || widget.controller.isRestoringSession) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final localAuthService = widget.dependencies?.localAuthService;
    if (!widget.controller.isAuthenticated &&
        _needsLocalFirstUserSetup &&
        localAuthService != null) {
      return LocalFirstUserSetupScreen(
        authService: localAuthService,
        onUserCreated: () {
          setState(() {
            _needsLocalFirstUserSetup = false;
          });
        },
      );
    }

    if (widget.controller.isAuthenticated) {
      _startLocalBackupSchedulingOnce();

      final drawer = AppNavigationDrawer(
        selected: _selectedDestination,
        onSelect: (destination) {
          setState(() {
            _selectedDestination = destination;
          });
        },
        onLogout: widget.controller.logout,
        showLocalBackup: widget.dependencies?.mode == DataMode.local,
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
            onProductSelected: (product) async {
              final result = await Navigator.of(context).push<Product>(
                MaterialPageRoute<Product>(
                  builder: (_) => ProductDetailScreen(
                    productsService: widget.productsService,
                    product: product,
                    onEditProduct: _openProductForm,
                    supportsProductReactivation:
                        widget.dependencies?.mode == DataMode.local,
                  ),
                ),
              );
              return result;
            },
          );
        case AppDestination.sellers:
          return SellerListScreen(
            drawer: drawer,
            sellersService: widget.sellersService,
            paymentsService: widget.paymentsService,
            onCreateInvoice: _openCreateInvoiceForSeller,
          );
        case AppDestination.buyers:
          return BuyerListScreen(
            drawer: drawer,
            buyersService: widget.buyersService,
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
        case AppDestination.backup:
          return BackupScreen(
            drawer: drawer,
            driveBackupService:
                widget.driveBackupService ?? const GoogleDriveBackupService(),
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

  Future<Product?> _openProductForm(Product product) async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute<Product>(
        builder: (_) => ProductFormScreen(
          productsService: widget.productsService,
          product: product,
        ),
      ),
    );
    return result;
  }

  Future<void> _checkLocalUsers() async {
    final hasLocalUsers = widget.dependencies?.hasLocalUsers;
    if (hasLocalUsers == null) {
      return;
    }

    setState(() {
      _isCheckingLocalUsers = true;
    });

    final hasUsers = await hasLocalUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      _needsLocalFirstUserSetup = !hasUsers;
      _isCheckingLocalUsers = false;
    });
  }

  void _startLocalBackupSchedulingOnce() {
    if (_didStartLocalBackupScheduling ||
        widget.dependencies?.mode != DataMode.local) {
      return;
    }
    _didStartLocalBackupScheduling = true;

    final scheduler = _backupScheduler();
    Future<void>.microtask(() async {
      try {
        await scheduler.registerPlatformSchedule();
      } on Object {
        // Backup scheduling must not block opening the local app shell.
      }
      try {
        await scheduler.runCatchUpIfDue();
      } on Object {
        // Catch-up failures are recorded by the scheduler and should not block startup.
      }
    });
  }

  BackupScheduler _backupScheduler() {
    final backupScheduler = widget.backupScheduler;
    if (backupScheduler != null) {
      return backupScheduler;
    }

    final driveBackupService =
        widget.driveBackupService ?? const GoogleDriveBackupService();
    return BackupScheduler(
      settingsLoader: driveBackupService.loadSettings,
      runBackup: driveBackupService.exportBackup,
    );
  }
}
