import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_analytics_service.dart';
import 'package:internal_billing_khata_mobile/local/local_buyers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/services/buyers_service.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  late LocalDatabase database;
  late LocalCompanyProfileService companyService;
  late LocalBuyersService buyersService;
  late LocalProductsService productsService;
  late LocalCustomersService customersService;
  late LocalInvoicesService invoicesService;
  late LocalPaymentsService paymentsService;
  late LocalAnalyticsService analyticsService;

  setUp(() {
    database = LocalDatabase.memory();
    companyService = LocalCompanyProfileService(database: database);
    buyersService = LocalBuyersService(database: database);
    productsService = LocalProductsService(database: database);
    customersService = LocalCustomersService(database: database);
    invoicesService = LocalInvoicesService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    analyticsService = LocalAnalyticsService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('full wholesaler flow from empty database to verified analytics',
      () async {
    await companyService.upsertCompanyProfile(UpsertCompanyProfileInput(
      name: 'Acme Traders',
      address: 'Main Road',
      city: 'Pune',
      state: 'Maharashtra',
      stateCode: '27',
      gstin: '27ABCDE1234F1Z5',
      gstFlag: true,
      phone: '9999999999',
    ));

    final buyer = await buyersService.createBuyer(CreateBuyerInput(
      name: 'Camlin Distributors',
      address: 'Mumbai',
    ));
    expect(buyer.name, 'Camlin Distributors');

    final product = await productsService.createProduct(CreateProductInput(
      companyName: 'Camlin',
      category: 'Pens',
      itemName: 'Blue Pen',
      itemNumber: 'PEN-001',
      buyingPrice: 80,
      sellingPrice: 118,
      gstRate: 18,
      hsnCode: '960810',
      quantityOnHand: 50,
      lowStockThreshold: 5,
    ));
    expect(product.itemName, 'Blue Pen');
    expect(product.quantityOnHand, 50);
    expect(product.companyName, 'Camlin');

    final customer = await customersService.createCustomer(CreateCustomerInput(
      name: 'ABC Stores',
      address: 'Market Yard',
      phone: '9876543210',
      state: 'Maharashtra',
      stateCode: '27',
    ));
    expect(customer.name, 'ABC Stores');
    expect(customer.pendingBalance, 0);

    final editedPrice = 130.0;
    final draft = InvoiceDraft(
      customer: customer,
      invoiceDate: '2026-05-10',
      paymentState: 'PARTIAL_PAID',
      paidAmount: 150,
      items: [
        InvoiceDraftItem(
          product: product,
          quantity: 3,
          pricingMode: 'TAX_INCLUSIVE',
          unitPrice: editedPrice,
        ),
      ],
    );

    final quote = await invoicesService.quoteInvoice(draft);
    expect(quote.taxRegime, 'INTRA_STATE');
    expect(quote.items, hasLength(1));
    expect(quote.items.single.enteredUnitPrice, editedPrice);
    expect(quote.items.single.gstRate, 18);
    expect(quote.totals.grandTotal, closeTo(390, 0.01));

    final requestId = _uuid();
    final result = await invoicesService.createInvoice(
      draft: draft,
      requestId: requestId,
    );
    final invoice = result.invoice;
    expect(invoice.status, 'ACTIVE');
    expect(invoice.paymentState, 'PARTIAL_PAID');
    expect(invoice.paidAmount, 150);
    expect(invoice.grandTotal, closeTo(390, 0.01));
    expect(invoice.customerName, 'ABC Stores');
    expect(invoice.items, hasLength(1));
    expect(invoice.items.single.productId, product.id);
    expect(invoice.items.single.quantity, 3);

    final updatedProduct = (await productsService.fetchProducts())
        .firstWhere((p) => p.id == product.id);
    expect(updatedProduct.quantityOnHand, 47);

    final ledger = await customersService.fetchCustomerLedger(customer.id);
    expect(ledger.customer.pendingBalance, closeTo(240, 0.01));

    final creditSale =
        ledger.transactions.where((t) => t.entryType == 'CREDIT_SALE').toList();
    expect(creditSale, hasLength(1));
    expect(creditSale.single.amount, closeTo(390, 0.01));

    final collection =
        ledger.transactions.where((t) => t.entryType == 'COLLECTION').toList();
    expect(collection, hasLength(1));
    expect(collection.single.amount, 150);

    final dashboard = await analyticsService.getDashboard();

    expect(dashboard.revenueByCompany, isNotEmpty);
    final camlinRevenue =
        dashboard.revenueByCompany.where((e) => e.name == 'Camlin').toList();
    expect(camlinRevenue, hasLength(1));
    expect(
      camlinRevenue.single.revenue,
      closeTo(quote.totals.taxableTotal, 0.01),
    );

    expect(dashboard.profitByCompany, isNotEmpty);
    final camlinProfit =
        dashboard.profitByCompany.where((e) => e.name == 'Camlin').toList();
    expect(camlinProfit, hasLength(1));
    expect(
      camlinProfit.single.profit,
      closeTo(quote.totals.taxableTotal - (80 * 3), 0.01),
    );

    expect(dashboard.customerKhataBalances, isNotEmpty);
    final abcBalance = dashboard.customerKhataBalances
        .where((b) => b.customerName == 'ABC Stores')
        .toList();
    expect(abcBalance, hasLength(1));
    expect(abcBalance.single.balance, closeTo(240, 0.01));

    final collectionRequestId = _uuid();
    await paymentsService.recordCollection(RecordCollectionInput(
      requestId: collectionRequestId,
      customerId: customer.id,
      amount: 100,
      occurredOn: '2026-05-11',
      notes: 'Cash collection',
    ));

    final ledgerAfterCollection =
        await customersService.fetchCustomerLedger(customer.id);
    expect(ledgerAfterCollection.customer.pendingBalance, closeTo(140, 0.01));

    final entryTypes =
        ledgerAfterCollection.transactions.map((t) => t.entryType).toList();
    expect(entryTypes, contains('CREDIT_SALE'));
    expect(entryTypes.where((t) => t == 'COLLECTION').length, 2);

    final invoiceList = await invoicesService.listInvoices(status: 'ACTIVE');
    expect(invoiceList, hasLength(1));
    expect(invoiceList.single.customerName, 'ABC Stores');
    expect(invoiceList.single.grandTotal, closeTo(390, 0.01));
  });

  test('full flow with buyer pending payable reflects in analytics', () async {
    await companyService.upsertCompanyProfile(UpsertCompanyProfileInput(
      name: 'Test Co',
      address: 'Addr',
      city: 'Mumbai',
      state: 'Maharashtra',
      stateCode: '27',
      gstin: '27ABCDE1234F1Z5',
      gstFlag: true,
    ));

    final buyer = await buyersService.createBuyer(CreateBuyerInput(
      name: 'Supplier Co',
      address: 'Delhi',
    ));

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(),
        amount: '5000.00',
        occurredAt: '2026-05-01T00:00:00.000Z',
      ),
    );

    await buyersService.addPaymentMade(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(),
        amount: '2000.00',
        occurredAt: '2026-05-05T00:00:00.000Z',
      ),
    );

    final dashboard = await analyticsService.getDashboard();
    final supplierPayable = dashboard.buyerPendingPayables
        .where((p) => p.buyerName == 'Supplier Co')
        .toList();
    expect(supplierPayable, hasLength(1));
    expect(supplierPayable.single.payable, closeTo(3000, 0.01));

    final buyerLedger = await buyersService.fetchBuyerLedger(buyer.id);
    expect(buyerLedger.buyer.pendingPayable, closeTo(3000, 0.01));
  });
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
