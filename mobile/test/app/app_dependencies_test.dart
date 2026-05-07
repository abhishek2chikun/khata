import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/app/app_dependencies.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/local/local_sellers_service.dart';
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
    expect(dependencies.sellersService, isA<ApiSellersService>());
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
    final dependencies = await AppDependencies.create(mode: DataMode.local);

    expect(dependencies.mode, DataMode.local);
    expect(dependencies.controller, isA<AuthController>());
    expect(dependencies.productsService, isA<LocalProductsService>());
    expect(dependencies.sellersService, isA<LocalSellersService>());
    expect(dependencies.paymentsService, isA<LocalPaymentsService>());
    await dependencies.dispose();
  });

  test('default dependencies resolve to api mode', () async {
    final dependencies =
        await AppDependencies.create(apiBaseUri: testApiBaseUri);
    expect(dependencies.mode, DataMode.api);
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
      sellersService: _FakeSellersService(),
      companyProfileService: _FakeCompanyProfileService(),
      paymentsService: _FakePaymentsService(),
      invoicesService: _FakeInvoicesService(),
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
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
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
