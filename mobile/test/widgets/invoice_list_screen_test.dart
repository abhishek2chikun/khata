import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/invoice_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets('invoice list shows Cash/Credit settlement label', (tester) async {
    final invoices = _InvoicesService();
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceListScreen(
          invoicesService: invoices,
          productsService: _ProductsService(),
          customersService: _CustomersService(),
          drawer: const Drawer(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Credit'), findsOneWidget);
    expect(find.textContaining('PARTIAL_PAID'), findsNothing);
    await tester.tap(find.text('Canceled'));
    await tester.pumpAndSettle();
    expect(invoices.statusRequests.last, 'CANCELED');
  });

  testWidgets('new invoice route receives GST company profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceListScreen(
          invoicesService: _InvoicesService(),
          productsService: _ProductsService(),
          customersService: _CustomersService(),
          companyProfileService: _CompanyService(),
          drawer: const Drawer(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('newInvoiceButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoiceGstFlagSwitch')), findsOneWidget);
    expect(find.text('GST invoice'), findsOneWidget);
  });
}

class _InvoicesService implements InvoicesService {
  final List<String?> statusRequests = [];

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) async {
    statusRequests.add(status);
    return const <InvoiceSummary>[
      InvoiceSummary(
        id: 'invoice-1',
        invoiceNumber: '42',
        customerId: 'customer-1',
        customerName: 'ABC Stores',
        invoiceDate: '2026-06-13',
        status: 'ACTIVE',
        paymentState: 'PARTIAL_PAID',
        paymentMode: 'CREDIT',
        grandTotal: 118,
      ),
    ];
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) =>
      throw UnimplementedError();

  @override
  Future<CreateInvoiceResult> createInvoice(
          {required InvoiceDraft draft, required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) =>
      throw UnimplementedError();

  @override
  Future<InvoiceDetail> cancelInvoice(
          {required String invoiceId, required String reason}) =>
      throw UnimplementedError();
}

class _ProductsService implements ProductsService {
  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async => [];

  @override
  Future<Product> createProduct(CreateProductInput input) =>
      throw UnimplementedError();

  @override
  Future<Product> updateProduct(
          {required String id, required UpdateProductInput input}) =>
      throw UnimplementedError();

  @override
  Future<Product> archiveProduct({required String id}) =>
      throw UnimplementedError();

  @override
  Future<Product> reactivateProduct({required String id}) =>
      throw UnimplementedError();

  @override
  Future<Product> adjustStock(
          {required String id, required AdjustStockInput input}) =>
      throw UnimplementedError();
}

class _CustomersService implements CustomersService {
  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async => [];

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) =>
      throw UnimplementedError();

  @override
  Future<Customer> updateCustomer(
          {required String id, required UpdateCustomerInput input}) =>
      throw UnimplementedError();

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
          {String? onDate}) =>
      throw UnimplementedError();
}

class _CompanyService implements CompanyProfileService {
  @override
  Future<CompanyProfile> fetchCompanyProfile() async => _company;

  @override
  Future<CompanyProfile> upsertCompanyProfile(
          UpsertCompanyProfileInput input) =>
      throw UnimplementedError();
}

const _company = CompanyProfile(
  id: 'company-1',
  name: 'Khata Co',
  address: 'Main Road',
  city: 'Mumbai',
  state: 'Maharashtra',
  stateCode: '27',
  gstin: '27ABCDE1234F1Z5',
  gstFlag: true,
  phone: null,
  email: null,
  bankName: null,
  bankAccount: null,
  bankIfsc: null,
  bankBranch: null,
  jurisdiction: null,
  isActive: true,
);
