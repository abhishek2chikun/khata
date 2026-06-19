import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_controller.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/main.dart' as app;
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
  testWidgets('BillingApp builds the login shell on startup', (tester) async {
    final controller = AuthController(
      authService: FakeAuthService(),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: app.BillingApp(
          controller: controller,
          productsService: FakeProductsService(),
          customersService: FakeCustomersService(),
          buyersService: FakeBuyersService(),
          companyProfileService: FakeCompanyProfileService(),
          paymentsService: FakePaymentsService(),
          invoicesService: FakeInvoicesService(),
          analyticsService: FakeAnalyticsService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Internal Billing'), findsOneWidget);
    expect(
      find.text('Sign in with your Supabase email and password.'),
      findsOneWidget,
    );
  });
}

class FakeAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login(
      {required String username, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> me({required String accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) {
    throw UnimplementedError();
  }
}

class MemorySessionStore implements SessionStore {
  StoredSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession session) async {
    this.session = session;
  }
}

class FakeProductsService implements ProductsService {
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

class FakeCustomersService implements CustomersService {
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

class FakeBuyersService implements BuyersService {
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

class FakePaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment(
      {required String customerId, required BalanceAdjustmentInput input}) {
    throw UnimplementedError();
  }

  @override
  Future<void> addOpeningBalance(
      {required String customerId, required OpeningBalanceInput input}) {
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

class FakeInvoicesService implements InvoicesService {
  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) {
    throw UnimplementedError();
  }

  @override
  Future<CreateInvoiceResult> createInvoice(
      {required InvoiceDraft draft, required String requestId}) {
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

class FakeCompanyProfileService implements CompanyProfileService {
  @override
  Future<CompanyProfile> fetchCompanyProfile() {
    throw UnimplementedError();
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(UpsertCompanyProfileInput input) {
    throw UnimplementedError();
  }
}

class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<Dashboard> getDashboard({String? fromDate, String? toDate}) async {
    return Dashboard.empty();
  }
}
