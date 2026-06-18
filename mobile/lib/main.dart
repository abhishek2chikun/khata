import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_controller.dart';
import 'app/app_dependencies.dart';
import 'app/app_mode.dart';
import 'hybrid/supabase_config.dart';
import 'debug/agent_debug_log.dart';
import 'backup/backup_scheduler.dart';
import 'backup/backup_screen.dart';
import 'backup/drive_backup_service.dart';
import 'backup/local_backup_transfer_service.dart';
import 'models/customer.dart';
import 'screens/buyer_list_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/company_profile_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/local_first_user_setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
import 'models/product.dart';
import 'screens/customer_list_screen.dart';
import 'services/analytics_service.dart';
import 'services/company_profile_service.dart';
import 'services/buyers_service.dart';
import 'services/invoices_service.dart';
import 'services/invoice_share_service.dart';
import 'services/balance_share_service.dart';
import 'services/payments_service.dart';
import 'services/products_service.dart';
import 'services/customers_service.dart';
import 'widgets/app_navigation_drawer.dart';
import 'widgets/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mode = resolveDataMode();
  if (mode == DataMode.local) {
    await initializeLocalBackupPlatformServices();
  }
  if (mode == DataMode.hybrid) {
    final config = SupabaseConfig.fromEnvironment();
    // #region agent log
    AgentDebugLog.write(
      location: 'main.dart:main',
      message: 'hybrid startup config',
      hypothesisId: 'H3',
      data: {
        'configPresent': config != null,
        'urlConfigured': config?.url.isNotEmpty ?? false,
        'anonConfigured': config?.anonKey.isNotEmpty ?? false,
      },
    );
    // #endregion
    if (config != null) {
      await Supabase.initialize(
        url: config.url,
        anonKey: config.anonKey,
      );
    }
  }

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
    CustomersService? customersService,
    BuyersService? buyersService,
    CompanyProfileService? companyProfileService,
    PaymentsService? paymentsService,
    InvoicesService? invoicesService,
    AnalyticsService? analyticsService,
    DriveBackupService? driveBackupService,
    BackupScheduler? backupScheduler,
    BackupTransferService? backupTransferService,
  })  : dependencies = dependencies,
        controller = controller ?? dependencies!.controller,
        productsService = productsService ?? dependencies!.productsService,
        customersService = customersService ?? dependencies!.customersService,
        buyersService = buyersService ?? dependencies!.buyersService,
        companyProfileService =
            companyProfileService ?? dependencies!.companyProfileService,
        paymentsService = paymentsService ?? dependencies!.paymentsService,
        invoicesService = invoicesService ?? dependencies!.invoicesService,
        analyticsService = analyticsService ?? dependencies!.analyticsService,
        driveBackupService =
            driveBackupService ?? dependencies?.driveBackupService,
        backupScheduler = backupScheduler ?? dependencies?.backupScheduler,
        backupTransferService =
            backupTransferService ?? dependencies?.backupTransferService;

  final AppDependencies? dependencies;
  final AuthController controller;
  final ProductsService productsService;
  final CustomersService customersService;
  final BuyersService buyersService;
  final CompanyProfileService companyProfileService;
  final PaymentsService paymentsService;
  final InvoicesService invoicesService;
  final AnalyticsService analyticsService;
  final DriveBackupService? driveBackupService;
  final BackupScheduler? backupScheduler;
  final BackupTransferService? backupTransferService;

  @override
  State<BillingApp> createState() => _BillingAppState();
}

class _BillingAppState extends State<BillingApp> with WidgetsBindingObserver {
  AppDestination _selectedDestination = AppDestination.inventory;
  bool _isCheckingLocalUsers = false;
  bool _needsLocalFirstUserSetup = false;
  bool _didStartLocalBackupScheduling = false;
  bool _hybridBootstrapStarted = false;
  bool _hybridBootstrapInFlight = false;
  String? _hybridSyncError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_maybeBootstrapHybrid);
    _checkLocalUsers();
    unawaited(widget.controller.restoreSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_maybeBootstrapHybrid);
    final dependencies = widget.dependencies;
    if (dependencies != null) {
      Future<void>.microtask(dependencies.dispose);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncHybridIfAuthenticated());
    }
  }

  void _maybeBootstrapHybrid() {
    if (!mounted || widget.dependencies?.mode != DataMode.hybrid) {
      return;
    }
    if (!widget.controller.isAuthenticated ||
        _hybridBootstrapStarted ||
        _hybridBootstrapInFlight) {
      return;
    }
    unawaited(_bootstrapHybridCache());
  }

  Future<void> _bootstrapHybridCache() async {
    final syncService = widget.dependencies?.syncService;
    if (syncService == null) {
      return;
    }
    _hybridBootstrapInFlight = true;
    _hybridSyncError = null;
    try {
      await syncService.initializeHybridCacheIfNeeded();
      _hybridBootstrapStarted = true;
      if (mounted) {
        setState(() {});
      }
    } on Object catch (error) {
      _hybridSyncError = error.toString();
      // #region agent log
      AgentDebugLog.write(
        location: 'main.dart:_bootstrapHybridCache',
        message: 'hybrid bootstrap failed',
        hypothesisId: 'H-sync',
        data: {'error': _hybridSyncError},
        runId: 'post-fix',
      );
      // #endregion
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not sync from Supabase. Pull to refresh or sign in again.',
            ),
          ),
        );
      }
    } finally {
      _hybridBootstrapInFlight = false;
    }
  }

  Future<void> _syncHybridIfAuthenticated() async {
    if (widget.dependencies?.mode != DataMode.hybrid ||
        !widget.controller.isAuthenticated) {
      return;
    }
    final syncService = widget.dependencies?.syncService;
    if (syncService == null) {
      return;
    }
    try {
      await syncService.syncAll();
      _hybridSyncError = null;
      if (!_hybridBootstrapStarted) {
        _hybridBootstrapStarted = true;
      }
      if (mounted) {
        setState(() {});
      }
    } on Object catch (error) {
      _hybridSyncError = error.toString();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Internal Billing',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
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
      _maybeBootstrapHybrid();

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

      Widget screen;
      switch (_selectedDestination) {
        case AppDestination.inventory:
          screen = InventoryListScreen(
            drawer: drawer,
            productsService: widget.productsService,
            onAddProduct: () async {
              final result = await Navigator.of(context).push<Product>(
                MaterialPageRoute<Product>(
                  builder: (_) => ProductFormScreen(
                      productsService: widget.productsService,
                      buyersService: widget.buyersService),
                ),
              );
              return result != null;
            },
            onProductSelected: (product) async {
              final result = await Navigator.of(context).push<Product>(
                MaterialPageRoute<Product>(
                  builder: (_) => ProductDetailScreen(
                    productsService: widget.productsService,
                    buyersService: widget.buyersService,
                    product: product,
                    supportsProductReactivation:
                        widget.dependencies?.mode == DataMode.local,
                  ),
                ),
              );
              return result;
            },
          );
          break;
        case AppDestination.customers:
          screen = CustomerListScreen(
            drawer: drawer,
            customersService: widget.customersService,
            paymentsService: widget.paymentsService,
            onCreateInvoice: _openCreateInvoiceForCustomer,
            companyProfileService: widget.companyProfileService,
            balanceShareService: BalanceShareService.production(),
          );
          break;
        case AppDestination.buyers:
          screen = BuyerListScreen(
            drawer: drawer,
            buyersService: widget.buyersService,
            productsService: widget.productsService,
          );
          break;
        case AppDestination.invoices:
          screen = InvoiceListScreen(
            drawer: drawer,
            invoicesService: widget.invoicesService,
            productsService: widget.productsService,
            customersService: widget.customersService,
            companyProfileService: widget.companyProfileService,
            shareService: InvoiceShareService.production(),
          );
          break;
        case AppDestination.analytics:
          screen = AnalyticsScreen(
            analyticsService: widget.analyticsService,
            drawer: drawer,
          );
          break;
        case AppDestination.companyProfile:
          screen = CompanyProfileScreen(
            drawer: drawer,
            companyProfileService: widget.companyProfileService,
          );
          break;
        case AppDestination.backup:
          screen = BackupScreen(
            drawer: drawer,
            driveBackupService:
                widget.driveBackupService ?? const GoogleDriveBackupService(),
            backupTransferService: widget.backupTransferService,
            onRestoreCompleted: widget.controller.logout,
          );
          break;
      }

      return screen;
    }

    return Scaffold(
      body: LoginScreen(controller: widget.controller),
    );
  }

  Future<bool> _openCreateInvoiceForCustomer(Customer customer) async {
    final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CreateInvoiceScreen(
              invoicesService: widget.invoicesService,
              productsService: widget.productsService,
              customersService: widget.customersService,
              companyProfileService: widget.companyProfileService,
              initialCustomer: customer,
              shareService: InvoiceShareService.production(),
            ),
          ),
        ) ??
        false;
    return created;
  }

  Future<void> _checkLocalUsers() async {
    if (widget.dependencies?.mode != DataMode.local) {
      return;
    }
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

    final scheduler = widget.backupScheduler;
    if (scheduler == null) {
      return;
    }
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
}
