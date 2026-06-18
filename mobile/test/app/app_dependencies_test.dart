import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:internal_billing_khata_mobile/local/local_buyers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/models/buyer.dart';
import 'package:internal_billing_khata_mobile/models/buyer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/services/analytics_service.dart';
import 'package:internal_billing_khata_mobile/models/analytics.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/buyers_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  final testApiBaseUri = Uri.parse('http://example.invalid/');

  test('API dependencies preserve api mode label', () async {
    final dependencies = await AppDependencies.create(
      mode: DataMode.api,
      apiBaseUri: testApiBaseUri,
    );
    expect(dependencies.mode, DataMode.api);
    await dependencies.dispose();
  });

  test('API dependencies use expected service types', () async {
    final dependencies = await AppDependencies.create(
      mode: DataMode.api,
      apiBaseUri: testApiBaseUri,
    );

    expect(dependencies.controller, isA<AuthController>());
    expect(dependencies.productsService, isA<ApiProductsService>());
    expect(dependencies.customersService, isA<ApiCustomersService>());
    expect(dependencies.buyersService, isA<ApiBuyersService>());
    expect(dependencies.companyProfileService, isA<ApiCompanyProfileService>());
    expect(dependencies.paymentsService, isA<ApiPaymentsService>());
    expect(dependencies.invoicesService, isA<ApiInvoicesService>());
    await dependencies.dispose();
  });

  test('API dependencies close created http clients on dispose', () async {
    HttpClient? authHttpClient;
    HttpClient? apiHttpClient;
    final dependencies = await AppDependencies.create(
      mode: DataMode.api,
      apiBaseUri: testApiBaseUri,
      onApiHttpClientsCreated: (authClient, apiClient) {
        authHttpClient = authClient;
        apiHttpClient = apiClient;
      },
    );

    expect(authHttpClient, isNotNull);
    expect(apiHttpClient, isNotNull);

    await dependencies.dispose();

    await expectLater(
      _openUrl(authHttpClient!, testApiBaseUri),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      _openUrl(apiHttpClient!, testApiBaseUri),
      throwsA(isA<StateError>()),
    );
  });

  test('local dependencies create local auth and local data services',
      () async {
    final database = db.LocalDatabase.memory();
    final dependencies = await AppDependencies.create(
      mode: DataMode.local,
      localDatabase: database,
      loadCatalogJson: () async =>
          '{"catalog_version":1,"buyers":[],"products":[]}',
    );

    expect(dependencies.mode, DataMode.local);
    expect(dependencies.controller, isA<AuthController>());
    expect(dependencies.productsService, isA<LocalProductsService>());
    expect(dependencies.customersService, isA<LocalCustomersService>());
    expect(dependencies.buyersService, isA<LocalBuyersService>());
    expect(dependencies.paymentsService, isA<LocalPaymentsService>());
    await dependencies.dispose();
  });

  test('local hasLocalUsers returns true when multiple users exist', () async {
    final database = db.LocalDatabase.memory();
    await database.into(database.localUsers).insert(
          db.LocalUsersCompanion.insert(
            id: 'local-user-1',
            username: 'owner',
            passwordHash: 'hash-1',
            salt: 'salt-1',
            passwordHashVersion: 1,
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
            displayName: const Value('Owner'),
          ),
        );
    await database.into(database.localUsers).insert(
          db.LocalUsersCompanion.insert(
            id: 'local-user-2',
            username: 'system',
            passwordHash: 'hash-2',
            salt: 'salt-2',
            passwordHashVersion: 1,
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
            displayName: const Value('System'),
          ),
        );
    final dependencies = await AppDependencies.create(
      mode: DataMode.local,
      localDatabase: database,
      sessionStore: _FakeSessionStore(),
    );

    await expectLater(dependencies.hasLocalUsers!(), completion(isTrue));

    await dependencies.dispose();
  });

  test('default dependencies resolve to local mode when DATA_MODE=local', () async {
    final dependencies = await AppDependencies.create(
      mode: DataMode.local,
      localDatabase: db.LocalDatabase.memory(),
    );
    expect(dependencies.mode, DataMode.local);
    await dependencies.dispose();
  });

  test('dispose invokes optional dispose callback', () async {
    var disposed = false;
    final dependencies = AppDependencies(
      mode: DataMode.api,
      controller: AuthController(
        authService: _FakeAuthService(),
        sessionStore: _FakeSessionStore(),
      ),
      productsService: _FakeProductsService(),
      customersService: _FakeCustomersService(),
      buyersService: _FakeBuyersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
      analyticsService: _FakeAnalyticsService(),
      dispose: () async {
        disposed = true;
      },
    );

    await dependencies.dispose();

    expect(disposed, isTrue);
  });
}

Future<void> _openUrl(HttpClient client, Uri uri) async {
  await client.getUrl(uri);
}

class _FakeAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login(
      {required String username, required String password}) {
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

class _FakeSessionStore implements SessionStore {
  @override
  Future<void> clearSession() async {}

  @override
  Future<StoredSession?> readSession() async => null;

  @override
  Future<void> writeSession(StoredSession session) async {}
}

class _FakeProductsService implements ProductsService {
  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> archiveProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> reactivateProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
    throw UnimplementedError();
  }
}

class _FakeCustomersService implements CustomersService {
  @override
  Future<Customer> createCustomer(CreateCustomerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) {
    throw UnimplementedError();
  }
}

class _FakeBuyersService implements BuyersService {
  @override
  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Buyer> createBuyer(CreateBuyerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Buyer> updateBuyer({
    required String id,
    required UpdateBuyerInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Buyer>> fetchBuyers({String search = ''}) {
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
    required String customerId,
    required BalanceAdjustmentInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) {
    throw UnimplementedError();
  }
  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(BatchCollectionInput input) {
    throw UnimplementedError();
  }

}

class _FakeInvoicesService implements InvoicesService {
  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) {
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

class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<Dashboard> getDashboard({String? fromDate, String? toDate}) async {
    return Dashboard.empty();
  }
}
