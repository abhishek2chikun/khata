import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/backup/backup_scheduler.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart'
    hide CompanyProfile, Product, Seller;
import 'package:internal_billing_khata_mobile/main.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/models/seller_ledger.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  testWidgets(
      'local mode sets up first user and creates product from inventory',
      (tester) async {
    final database = LocalDatabase.memory();
    final dependencies = await AppDependencies.create(
      mode: DataMode.local,
      localDatabase: database,
      sessionStore: _MemorySessionStore(),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up local user'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Username'), 'owner');
    await tester.enterText(find.bySemanticsLabel('Display name'), 'Owner');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.tap(find.text('Create user'));
    await tester.pumpAndSettle();

    expect(
        find.text('Sign in with your username and password.'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Username'), 'owner');
    await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('No products found'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add product'), findsWidgets);

    await tester.enterText(find.bySemanticsLabel('Company / buyer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item number'), 'PEN-1');
    await tester.enterText(find.bySemanticsLabel('Buying price'), '8');
    await tester.enterText(
      find.bySemanticsLabel('Selling price'),
      '10.5',
    );
    await tester.enterText(find.bySemanticsLabel('GST rate'), '18');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Pens'), findsOneWidget);
    expect(find.text('PEN-1'), findsOneWidget);
  });

  testWidgets('BillingApp disposes provided app dependencies when removed',
      (tester) async {
    var disposed = false;
    final dependencies = AppDependencies(
      mode: DataMode.local,
      controller: AuthController(
        authService: _FakeAuthService(),
        sessionStore: _MemorySessionStore(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
      dispose: () async {
        disposed = true;
      },
    );

    await tester.pumpWidget(BillingApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(disposed, isTrue);
  });

  testWidgets(
      'local mode runs backup catch-up once after authenticated startup',
      (tester) async {
    final scheduler = _FakeBackupScheduler();
    final dependencies = AppDependencies(
      mode: DataMode.local,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _AuthenticatedSessionStore(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
      hasLocalUsers: () async => true,
    );

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
        backupScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.catchUpRuns, 1);
    expect(scheduler.registerRuns, 1);
  });

  testWidgets('local mode runs catch-up when schedule registration fails',
      (tester) async {
    final scheduler = _FakeBackupScheduler(throwOnRegister: true);
    final dependencies = AppDependencies(
      mode: DataMode.local,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _AuthenticatedSessionStore(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
      hasLocalUsers: () async => true,
    );

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
        backupScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
    expect(scheduler.registerRuns, 1);
    expect(scheduler.catchUpRuns, 1);
  });

  testWidgets('local mode keeps app shell open when catch-up fails',
      (tester) async {
    final scheduler = _FakeBackupScheduler(throwOnCatchUp: true);
    final dependencies = AppDependencies(
      mode: DataMode.local,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _AuthenticatedSessionStore(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
      hasLocalUsers: () async => true,
    );

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
        backupScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsWidgets);
    expect(scheduler.catchUpRuns, 1);
  });

  testWidgets('api mode does not run local backup scheduling', (tester) async {
    final scheduler = _FakeBackupScheduler();
    final dependencies = AppDependencies(
      mode: DataMode.api,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _AuthenticatedSessionStore(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
    );

    await tester.pumpWidget(
      BillingApp(
        dependencies: dependencies,
        backupScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.catchUpRuns, 0);
    expect(scheduler.registerRuns, 0);
  });
}

class _FakeBackupScheduler implements BackupScheduler {
  _FakeBackupScheduler({
    this.throwOnRegister = false,
    this.throwOnCatchUp = false,
  });

  final bool throwOnRegister;
  final bool throwOnCatchUp;
  int catchUpRuns = 0;
  int registerRuns = 0;

  @override
  Future<bool> runCatchUpIfDue({DateTime? now}) async {
    catchUpRuns += 1;
    if (throwOnCatchUp) {
      throw StateError('catch-up failed');
    }
    return true;
  }

  @override
  Future<void> registerPlatformSchedule() async {
    registerRuns += 1;
    if (throwOnRegister) {
      throw StateError('schedule failed');
    }
  }
}

class _AuthenticatedSessionStore implements SessionStore {
  StoredSession? _session = const StoredSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'Bearer',
  );

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<StoredSession?> readSession() async => _session;

  @override
  Future<void> writeSession(StoredSession session) async {
    _session = session;
  }
}

class _AuthenticatedAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    return _tokens;
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthUser> me({required String accessToken}) async {
    return const AuthUser(
        id: 'user-1', username: 'owner', displayName: 'Owner');
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) async {
    return _tokens;
  }

  static const _tokens = AuthSessionTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    tokenType: 'Bearer',
  );
}

class _MemorySessionStore implements SessionStore {
  StoredSession? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<StoredSession?> readSession() async => _session;

  @override
  Future<void> writeSession(StoredSession session) async {
    _session = session;
  }
}

class _FakeAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> me({required String accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) {
    throw UnimplementedError();
  }
}

class _FakeProductsService implements ProductsService {
  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> adjustQuantity({required String id, required double delta}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async => [];

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductInput input,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSellersService implements SellersService {
  @override
  Future<Seller> createSeller(CreateSellerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Seller>> fetchSellers({String search = ''}) {
    throw UnimplementedError();
  }
}

class _FakeCompanyProfileService implements CompanyProfileService {
  @override
  Future<CompanyProfile> fetchCompanyProfile() {
    throw UnimplementedError();
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(UpsertCompanyProfileInput input) {
    throw UnimplementedError();
  }
}

class _FakePaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordPayment(RecordPaymentInput input) {
    throw UnimplementedError();
  }
}

class _FakeInvoicesService implements InvoicesService {
  @override
  Future<InvoiceDetail> cancelInvoice({
    required String invoiceId,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) {
    throw UnimplementedError();
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) {
    throw UnimplementedError();
  }
}
