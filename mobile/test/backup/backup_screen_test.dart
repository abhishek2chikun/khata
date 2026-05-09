import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/backup/backup_screen.dart';
import 'package:internal_billing_khata_mobile/backup/backup_scheduler.dart';
import 'package:internal_billing_khata_mobile/backup/drive_backup_service.dart';
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
  testWidgets('backup screen shows last backup, actions, and daily time',
      (tester) async {
    final service = FakeDriveBackupService(
      settings: BackupScheduleSettings(
        automaticBackupsEnabled: true,
        dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
        lastBackupAt: DateTime(2026, 5, 7, 22, 30),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(driveBackupService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Last backup: 2026-05-07 22:30'), findsOneWidget);
    expect(find.text('Daily backup time: 00:00'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);

    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(service.exportCount, 1);
    expect(service.importCount, 1);
  });

  testWidgets('backup screen persists automatic backup settings and daily time',
      (tester) async {
    final service = FakeDriveBackupService();

    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(driveBackupService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automatic backups'));
    await tester.enterText(find.bySemanticsLabel('Daily backup hour'), '2');
    await tester.enterText(find.bySemanticsLabel('Daily backup minute'), '45');
    await tester.tap(find.text('Save backup schedule'));
    await tester.pumpAndSettle();

    final settings = await service.loadSettings();
    expect(settings.automaticBackupsEnabled, isTrue);
    expect(
        settings.dailyBackupTime, const BackupTimeOfDay(hour: 2, minute: 45));
    expect(find.text('Daily backup time: 02:45'), findsOneWidget);
  });

  testWidgets('local mode drawer shows backup destination and opens screen',
      (tester) async {
    final dependencies = AppDependencies(
      mode: DataMode.local,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _MemorySessionStore.authenticated(),
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
        driveBackupService: FakeDriveBackupService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsOneWidget);

    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Last backup: Never'), findsOneWidget);
  });

  testWidgets('api mode drawer hides backup destination', (tester) async {
    final dependencies = AppDependencies(
      mode: DataMode.api,
      controller: AuthController(
        authService: _AuthenticatedAuthService(),
        sessionStore: _MemorySessionStore.authenticated(),
      ),
      productsService: _FakeProductsService(),
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
    );

    await tester.pumpWidget(BillingApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsNothing);
  });
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
  _MemorySessionStore.authenticated()
      : _session = const StoredSession(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          tokenType: 'Bearer',
        );

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
  Future<List<Seller>> fetchSellers({String search = ''}) async => [];
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
