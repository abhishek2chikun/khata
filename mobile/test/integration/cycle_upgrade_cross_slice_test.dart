import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_analytics_service.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/invoice_pdf_service.dart';
import 'package:internal_billing_khata_mobile/services/invoice_settlement.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cycle upgrade cross-slice regressions', () {
    test(
        'cached canonical invoice supports hsn, precise prices, pdf and analytics',
        () async {
      final database = db.LocalDatabase.memory();
      addTearDown(database.close);
      await _seedCrossSliceBusinessData(database);

      final cachedProduct =
          await database.select(database.products).getSingle();
      expect(cachedProduct.hsnCode, '96081099');
      final cachedItem =
          await database.select(database.invoiceItems).getSingle();
      expect(cachedItem.productHsnCode, '96081099');
      expect(cachedItem.enteredUnitPrice, '12.008');

      final analytics = LocalAnalyticsService(database: database);
      final dashboard = await analytics.getDashboard(
        fromDate: '2026-06-01',
        toDate: '2026-06-30',
      );
      expect(dashboard.totalRevenue, closeTo(12.01, 0.01));
      expect(dashboard.activeInvoiceCount, 1);

      final invoices = LocalInvoicesService(database: database);
      final detail = await invoices.fetchInvoiceDetail('invoice-cross-0001');
      final pdfDir = Directory.systemTemp.createTempSync('khata-pdf-cross');
      addTearDown(() => pdfDir.deleteSync(recursive: true));
      final pdfPath = await InvoicePdfService.withDirectory(pdfDir.path)
          .generateInvoicePdf(detail);
      expect(File(pdfPath).existsSync(), isTrue);
      expect(
        invoicePdfTableHeaders(gstFlag: true, isInterState: false),
        contains('HSN'),
      );
      expect(detail.items.single.productHsnCode, '96081099');
      expect(invoicePdfFormatUnitPrice(12.008), '12.008');
    });

    test('batch collection immediately reduces receivables kpi', () async {
      final database = db.LocalDatabase.memory();
      addTearDown(database.close);
      final customersService = LocalCustomersService(database: database);
      final paymentsService = LocalPaymentsService(database: database);
      final analytics = LocalAnalyticsService(database: database);
      await _seedLocalUser(database);

      final customer = await customersService.createCustomer(_customerInput());
      final today = _todayString();
      await paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: OpeningBalanceInput(
          requestId: _uuid(1),
          amount: 500,
          occurredOn: today,
        ),
      );

      final before = await analytics.getDashboard();
      expect(before.customerReceivables, closeTo(500, 0.01));

      await paymentsService.recordCollectionBatch(
        BatchCollectionInput(
          requestId: _uuid(2),
          entries: <BatchCollectionEntryInput>[
            BatchCollectionEntryInput(
              customerId: customer.id,
              occurredOn: today,
              amount: 150,
            ),
          ],
        ),
      );

      final after = await analytics.getDashboard();
      expect(after.customerReceivables, closeTo(350, 0.01));
    });

    test('cash and credit invoices affect receivables kpi differently',
        () async {
      final database = db.LocalDatabase.memory();
      addTearDown(database.close);
      await _seedLocalUser(database);
      final companyService = LocalCompanyProfileService(database: database);
      final productsService = LocalProductsService(database: database);
      final customersService = LocalCustomersService(database: database);
      final invoicesService = LocalInvoicesService(database: database);
      final analytics = LocalAnalyticsService(database: database);

      await companyService.upsertCompanyProfile(_companyInput());
      final product = await productsService.createProduct(_productInput());
      final creditCustomer = await customersService
          .createCustomer(_customerInput(name: 'Credit Shop'));
      final cashCustomer = await customersService.createCustomer(_customerInput(
        name: 'Cash Shop',
        phone: '8888888888',
      ));

      await invoicesService.createInvoice(
        draft: _draft(
          customer: creditCustomer,
          product: product,
          quantity: 1,
          paymentState: 'CREDIT',
        ),
        requestId: _uuid(10),
      );
      await invoicesService.createInvoice(
        draft: _draft(
          customer: cashCustomer,
          product: product,
          quantity: 1,
          paymentState: 'TOTAL_PAID',
          paymentMode: settlementModeCash,
        ),
        requestId: _uuid(11),
      );

      final dashboard = await analytics.getDashboard(
        fromDate: '2026-01-01',
        toDate: '2026-12-31',
      );
      expect(dashboard.totalRevenue, closeTo(200, 0.01));
      expect(dashboard.customerReceivables, closeTo(118, 0.01));
    });

    test('catalog product missing hsn blocked only in gst mode', () async {
      final database = db.LocalDatabase.memory();
      addTearDown(database.close);
      await _seedLocalUser(database);
      final companyService = LocalCompanyProfileService(database: database);
      final productsService = LocalProductsService(database: database);
      final customersService = LocalCustomersService(database: database);
      final invoicesService = LocalInvoicesService(database: database);

      await companyService.upsertCompanyProfile(_companyInput(gstFlag: true));
      final customer = await customersService.createCustomer(_customerInput());
      final noHsn = await productsService.createProduct(
        _productInput(itemNumber: 'NO-HSN-1', hsnCode: null),
      );

      await expectLater(
        invoicesService.quoteInvoice(
          _draft(
              customer: customer, product: noHsn, quantity: 1, gstFlag: true),
        ),
        throwsA(_apiError(code: 'MISSING_PRODUCT_HSN', statusCode: 400)),
      );

      await companyService.upsertCompanyProfile(
        _companyInput(gstFlag: false, gstin: null),
      );
      final nonGstQuote = await invoicesService.quoteInvoice(
        _draft(
          customer: customer,
          product: noHsn,
          quantity: 1,
          gstFlag: false,
        ),
      );
      expect(nonGstQuote.totals.gstTotal, 0);
    });
  });
}

Future<void> _seedCrossSliceBusinessData(db.LocalDatabase database) async {
  await _seedLocalUser(database);
  await database.into(database.companyProfiles).insert(
        db.CompanyProfilesCompanion.insert(
          id: 'company-cross-0001',
          name: 'Khata Traders',
          address: '10 Market Road',
          city: 'Mumbai',
          state: 'Maharashtra',
          stateCode: '27',
          gstin: const Value('27ABCDE1234F1Z5'),
          gstFlag: const Value(true),
          phone: const Value('9000000000'),
          createdAt: '2026-06-01T00:00:00.000Z',
          updatedAt: '2026-06-01T00:00:00.000Z',
        ),
      );
  await database.into(database.products).insert(
        db.ProductsCompanion.insert(
          id: 'product-cross-0001',
          companyName: 'Precision Co',
          category: 'Tools',
          itemName: 'Fine Ruler',
          itemNumber: 'RUL-0001',
          hsnCode: const Value('96081099'),
          buyingPrice: '8.0040',
          sellingPrice: '12.0080',
          gstRate: '18.000',
          quantityOnHand: '10.000',
          lowStockThreshold: '2.00',
          createdAt: '2026-06-01T00:00:00.000Z',
          updatedAt: '2026-06-01T00:00:00.000Z',
        ),
      );
  await database.into(database.customers).insert(
        db.CustomersCompanion.insert(
          id: 'customer-cross-0001',
          name: 'Cross Slice Shop',
          address: '1 Market Road',
          phone: const Value('9999999999'),
          createdAt: '2026-06-01T00:00:00.000Z',
          updatedAt: '2026-06-01T00:00:00.000Z',
        ),
      );
  await database.into(database.invoices).insert(
        db.InvoicesCompanion.insert(
          id: 'invoice-cross-0001',
          requestId: 'request-cross-0001',
          requestHash: 'request-hash-cross',
          invoiceNumber: 42,
          customerId: 'customer-cross-0001',
          customerName: 'Cross Slice Shop',
          customerAddress: '1 Market Road',
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Khata Traders',
          companyAddress: '10 Market Road',
          companyCity: 'Mumbai',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: '2026-06-14',
          taxRegime: 'INTRA_STATE',
          status: 'ACTIVE',
          gstFlag: const Value(true),
          paymentMode: 'CREDIT',
          paymentState: const Value('CREDIT'),
          paidAmount: const Value('0'),
          subtotal: '12.0080',
          discountTotal: '0.0000',
          taxableTotal: '12.0080',
          gstTotal: '2.1614',
          grandTotal: '14.1694',
          createdByUserId: 'local-system-user',
          createdAt: '2026-06-14T00:00:00.000Z',
        ),
      );
  await database.into(database.invoiceItems).insert(
        db.InvoiceItemsCompanion.insert(
          id: 'invoice-item-cross-0001',
          invoiceId: 'invoice-cross-0001',
          productId: 'product-cross-0001',
          lineNumber: 1,
          productName: 'Fine Ruler',
          productCode: 'RUL-0001',
          productItemNumber: const Value('RUL-0001'),
          productItemName: const Value('Fine Ruler'),
          productHsnCode: const Value('96081099'),
          company: 'Precision Co',
          category: 'Tools',
          quantity: '1',
          pricingMode: 'PRE_TAX',
          enteredUnitPrice: '12.008',
          unitPriceExclTax: '12.0080',
          unitPriceInclTax: '14.1694',
          gstRate: '18.000',
          cgstRate: '9.000',
          sgstRate: '9.000',
          igstRate: '0.000',
          discountPercent: '0.000',
          discountAmount: '0.0000',
          taxableAmount: '12.0080',
          gstAmount: '2.1614',
          cgstAmount: '1.0807',
          sgstAmount: '1.0807',
          igstAmount: '0.0000',
          lineTotal: '14.1694',
          revenueAmount: const Value('12.0080'),
          buyingAmount: const Value('8.0040'),
          profitAmount: const Value('4.0040'),
          buyingPrice: const Value('8.0040'),
          sellingPrice: const Value('12.0080'),
        ),
      );
}

Future<void> _seedLocalUser(db.LocalDatabase database) {
  final now = DateTime.now().toUtc().toIso8601String();
  return database.into(database.localUsers).insert(
        db.LocalUsersCompanion.insert(
          id: 'local-system-user',
          username: 'system',
          passwordHash: 'hash',
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

UpsertCompanyProfileInput _companyInput({
  bool gstFlag = true,
  String? gstin = '27ABCDE1234F1Z5',
}) {
  return UpsertCompanyProfileInput(
    name: 'Khata Traders',
    address: '10 Market Road',
    city: 'Mumbai',
    state: 'Maharashtra',
    stateCode: '27',
    gstin: gstin,
    gstFlag: gstFlag,
  );
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String phone = '9999999999',
}) {
  return CreateCustomerInput(
    name: name,
    address: '1 Market Road',
    phone: phone,
    gstin: '27ABCDE1234F1Z5',
    state: 'Maharashtra',
    stateCode: '27',
  );
}

CreateProductInput _productInput({
  String itemNumber = 'PEN-1',
  String? hsnCode = '960810',
}) {
  return CreateProductInput(
    companyName: 'Acme',
    category: 'Pens',
    itemName: 'Blue Pen',
    itemNumber: itemNumber,
    buyingPrice: 80,
    sellingPrice: 118,
    gstRate: 18,
    hsnCode: hsnCode,
    quantityOnHand: 5,
    lowStockThreshold: 2,
  );
}

InvoiceDraft _draft({
  required Customer customer,
  required Product product,
  required double quantity,
  String paymentState = 'CREDIT',
  String? paymentMode,
  bool? gstFlag,
}) {
  return InvoiceDraft(
    customer: customer,
    invoiceDate: '2026-01-10',
    paymentState: paymentState,
    paidAmount: 0,
    paymentMode: paymentMode,
    gstFlag: gstFlag,
    items: <InvoiceDraftItem>[
      InvoiceDraftItem(
        product: product,
        quantity: quantity,
        unitPrice: 118,
      ),
    ],
  );
}

Matcher _apiError({required String code, required int statusCode}) {
  return predicate<ApiError>(
    (error) => error.code == code && error.statusCode == statusCode,
    'ApiError(code: $code, statusCode: $statusCode)',
  );
}

String _uuid(int seed) {
  final hex = seed.toRadixString(16).padLeft(12, '0');
  return '00000000-0000-4000-8000-$hex';
}

String _todayString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
