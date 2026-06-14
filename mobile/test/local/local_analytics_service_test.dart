import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_analytics_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

const parityFromDate = '2026-04-01';
const parityToDate = '2026-04-03';

void main() {
  late LocalDatabase database;
  late LocalAnalyticsService service;

  setUp(() {
    database = LocalDatabase.memory();
    service = LocalAnalyticsService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('revenue by company aggregates invoice item line totals', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    final byCompany = {for (final e in dashboard.revenueByCompany) e.name: e};
    expect(byCompany['TestCo']!.revenue, closeTo(200, 0.01));
    expect(byCompany['Acme Corp']!.revenue, closeTo(80, 0.01));
  });

  test('profit by company uses invoice item buying price snapshots', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    final byCompany = {for (final e in dashboard.profitByCompany) e.name: e};
    expect(byCompany['TestCo']!.profit, closeTo(110, 0.01));
    expect(byCompany['Acme Corp']!.profit, closeTo(40, 0.01));
  });

  test('customer khata balances reflect transactions', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    final balances = {
      for (final b in dashboard.customerKhataBalances) b.customerName: b,
    };
    expect(balances['Khata Customer']!.balance, closeTo(300, 0.01));
  });

  test('buyer pending payables reflect transactions', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    final payables = {
      for (final p in dashboard.buyerPendingPayables) p.buyerName: p,
    };
    expect(payables['Payable Buyer']!.payable, closeTo(600, 0.01));
  });

  test('top products by quantity ranks items', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    expect(dashboard.topProductsByQuantity, isNotEmpty);
    final names =
        dashboard.topProductsByQuantity.map((p) => p.productName).toList();
    expect(names, containsAll(['Prod A', 'Prod B']));
  });

  test('low stock returns products at or below threshold', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard();

    final lowNames = dashboard.lowStock.map((p) => p.productName).toList();
    expect(lowNames, contains('Low Stock Item'));
    expect(lowNames, isNot(contains('OK Stock Item')));
  });

  test('date range filters invoices', () async {
    await _seedFullSetup(database);

    final dashboard = await service.getDashboard(
      fromDate: '2026-04-01',
      toDate: '2026-04-15',
    );

    final totalRevenue =
        dashboard.revenueByCompany.fold(0.0, (sum, e) => sum + e.revenue);
    expect(totalRevenue, closeTo(200, 0.01));
  });

  test('kpis and zero-filled daily trend match backend parity fixture', () async {
    await _seedOwnerParity(database);

    final dashboard = await service.getDashboard(
      fromDate: parityFromDate,
      toDate: parityToDate,
    );

    expect(dashboard.totalRevenue, closeTo(350, 0.01));
    expect(dashboard.totalProfit, closeTo(140, 0.01));
    expect(dashboard.activeInvoiceCount, 2);
    expect(dashboard.averageInvoiceValue, closeTo(175, 0.01));
    expect(dashboard.customerReceivables, closeTo(150, 0.01));
    expect(dashboard.buyerPayables, closeTo(500, 0.01));

    expect(dashboard.dailyTrend, hasLength(3));
    expect(dashboard.dailyTrend[0].date, '2026-04-01');
    expect(dashboard.dailyTrend[0].revenue, closeTo(0, 0.01));
    expect(dashboard.dailyTrend[1].revenue, closeTo(200, 0.01));
    expect(dashboard.dailyTrend[1].profit, closeTo(80, 0.01));
    expect(dashboard.dailyTrend[2].revenue, closeTo(150, 0.01));

    final trendRevenue = dashboard.dailyTrend.fold<double>(
      0,
      (sum, point) => sum + point.revenue,
    );
    expect(trendRevenue, closeTo(dashboard.totalRevenue, 0.01));

    expect(dashboard.topProductsByRevenue.first.productName, 'Plain Widget');
    expect(dashboard.topProductsByRevenue.first.revenue, closeTo(250, 0.01));
  });

  test('empty database returns empty dashboard', () async {
    final dashboard = await service.getDashboard();

    expect(dashboard.revenueByCompany, isEmpty);
    expect(dashboard.profitByCompany, isEmpty);
    expect(dashboard.customerKhataBalances, isEmpty);
    expect(dashboard.buyerPendingPayables, isEmpty);
    expect(dashboard.topProductsByQuantity, isEmpty);
    expect(dashboard.lowStock, isEmpty);
    expect(dashboard.totalRevenue, 0);
    expect(dashboard.activeInvoiceCount, 0);
    expect(dashboard.dailyTrend, isEmpty);
  });
}

Future<void> _seedOwnerParity(LocalDatabase db) async {
  final now = DateTime.now().toUtc().toIso8601String();
  const systemUser = 'local-system-user';

  await db.into(db.localUsers).insert(
        LocalUsersCompanion.insert(
          id: systemUser,
          username: 'system',
          passwordHash: 'x',
          salt: 'x',
          passwordHashVersion: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: 'parity-customer',
          name: 'Parity Customer',
          address: 'Market',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.buyers).insert(
        BuyersCompanion.insert(
          id: 'parity-buyer',
          name: 'Parity Buyer',
          address: 'Market',
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-gst',
          itemNumber: 'GST-1',
          itemName: 'GST Widget',
          category: 'Cat',
          companyName: 'ParityCo',
          buyingPrice: '40',
          sellingPrice: '100',
          gstRate: '18',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          buyerId: const Value('parity-buyer'),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-plain',
          itemNumber: 'NG-1',
          itemName: 'Plain Widget',
          category: 'Cat',
          companyName: 'ParityCo',
          buyingPrice: '30',
          sellingPrice: '75',
          gstRate: '0',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          buyerId: const Value('parity-buyer'),
          createdAt: now,
          updatedAt: now,
        ),
      );

  await _insertParityInvoice(
    db,
    id: 'inv-active-1',
    invoiceNumber: 5001,
    invoiceDate: '2026-04-02',
    grandTotal: '200',
    status: 'ACTIVE',
    items: const [
      _ParityItem(
        id: 'ii-1',
        productId: 'prod-plain',
        itemName: 'Plain Widget',
        quantity: '1',
        revenue: '100',
        buying: '30',
        profit: '70',
      ),
      _ParityItem(
        id: 'ii-2',
        productId: 'prod-gst',
        itemName: 'GST Widget',
        lineNumber: 2,
        quantity: '1',
        revenue: '100',
        buying: '40',
        profit: '10',
      ),
    ],
    now: now,
    systemUser: systemUser,
  );
  await _insertParityInvoice(
    db,
    id: 'inv-active-2',
    invoiceNumber: 5002,
    invoiceDate: '2026-04-03',
    grandTotal: '150',
    status: 'ACTIVE',
    items: const [
      _ParityItem(
        id: 'ii-3',
        productId: 'prod-plain',
        itemName: 'Plain Widget',
        quantity: '2',
        revenue: '150',
        buying: '60',
        profit: '60',
      ),
    ],
    now: now,
    systemUser: systemUser,
  );
  await _insertParityInvoice(
    db,
    id: 'inv-canceled',
    invoiceNumber: 5003,
    invoiceDate: '2026-04-02',
    grandTotal: '80',
    status: 'CANCELED',
    items: const [
      _ParityItem(
        id: 'ii-4',
        productId: 'prod-plain',
        itemName: 'Plain Widget',
        quantity: '1',
        revenue: '80',
        buying: '30',
        profit: '50',
      ),
    ],
    now: now,
    systemUser: systemUser,
  );

  await db.into(db.customerTransactions).insert(
        CustomerTransactionsCompanion.insert(
          id: 'ct-open',
          customerId: 'parity-customer',
          entryType: 'OPENING_BALANCE',
          amount: '200',
          occurredOn: '2026-04-01',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.customerTransactions).insert(
        CustomerTransactionsCompanion.insert(
          id: 'ct-collect',
          customerId: 'parity-customer',
          entryType: 'COLLECTION',
          amount: '50',
          occurredOn: '2026-04-02',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.buyerTransactions).insert(
        BuyerTransactionsCompanion.insert(
          id: 'bt-open',
          buyerId: 'parity-buyer',
          requestId: const Value('req-bt-open'),
          requestHash: const Value('rh-bt-open'),
          entryType: 'OPENING_PAYABLE',
          amount: '700',
          occurredAt: '2026-04-01T00:00:00.000Z',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.buyerTransactions).insert(
        BuyerTransactionsCompanion.insert(
          id: 'bt-pay',
          buyerId: 'parity-buyer',
          requestId: const Value('req-bt-pay'),
          requestHash: const Value('rh-bt-pay'),
          entryType: 'PAYMENT_MADE',
          amount: '200',
          occurredAt: '2026-04-02T00:00:00.000Z',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
}

class _ParityItem {
  const _ParityItem({
    required this.id,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.revenue,
    required this.buying,
    required this.profit,
    this.lineNumber = 1,
  });

  final String id;
  final String productId;
  final String itemName;
  final String quantity;
  final String revenue;
  final String buying;
  final String profit;
  final int lineNumber;
}

Future<void> _insertParityInvoice(
  LocalDatabase db, {
  required String id,
  required int invoiceNumber,
  required String invoiceDate,
  required String grandTotal,
  required String status,
  required List<_ParityItem> items,
  required String now,
  required String systemUser,
}) async {
  await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: id,
          requestId: 'req-$id',
          requestHash: 'hash-$id',
          invoiceNumber: invoiceNumber,
          customerId: 'parity-customer',
          customerName: 'Parity Customer',
          customerAddress: 'Market',
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Parity Co',
          companyAddress: 'Addr',
          companyCity: 'Mumbai',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: invoiceDate,
          invoiceDatetime: Value('${invoiceDate}T00:00:00.000Z'),
          taxRegime: 'INTRA_STATE',
          status: status,
          paymentMode: '',
          subtotal: grandTotal,
          discountTotal: '0',
          taxableTotal: grandTotal,
          gstTotal: '0',
          grandTotal: grandTotal,
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );

  for (final item in items) {
    await db.into(db.invoiceItems).insert(
          InvoiceItemsCompanion.insert(
            id: item.id,
            invoiceId: id,
            productId: item.productId,
            lineNumber: item.lineNumber,
            productName: item.itemName,
            productCode: item.productId,
            productItemNumber: Value(item.productId),
            productItemName: Value(item.itemName),
            productCategory: const Value('Cat'),
            productCompanyName: const Value('ParityCo'),
            productBuyerId: const Value('parity-buyer'),
            buyingPrice: Value(item.buying),
            sellingPrice: const Value('100'),
            company: 'ParityCo',
            category: 'Cat',
            quantity: item.quantity,
            pricingMode: 'TAX_INCLUSIVE',
            enteredUnitPrice: '100',
            unitPriceExclTax: '100',
            unitPriceInclTax: '100',
            gstRate: '0',
            cgstRate: '0',
            sgstRate: '0',
            igstRate: '0',
            discountPercent: '0',
            discountAmount: '0',
            taxableAmount: item.revenue,
            gstAmount: '0',
            cgstAmount: '0',
            sgstAmount: '0',
            igstAmount: '0',
            lineTotal: item.revenue,
            revenueAmount: Value(item.revenue),
            buyingAmount: Value(item.buying),
            profitAmount: Value(item.profit),
          ),
        );
  }
}

Future<void> _seedFullSetup(LocalDatabase db) async {
  final now = DateTime.now().toUtc().toIso8601String();
  const systemUser = 'local-system-user';

  await db.into(db.localUsers).insert(
        LocalUsersCompanion.insert(
          id: systemUser,
          username: 'system',
          passwordHash: 'x',
          salt: 'x',
          passwordHashVersion: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.buyers).insert(
        BuyersCompanion.insert(
          id: 'buyer-1',
          name: 'Buyer A',
          address: 'Market',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.buyers).insert(
        BuyersCompanion.insert(
          id: 'buyer-payable',
          name: 'Payable Buyer',
          address: 'Market',
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: 'customer-1',
          name: 'Cust A',
          address: 'Addr A',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: 'customer-khata',
          name: 'Khata Customer',
          address: 'Market',
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-a',
          itemNumber: 'PA-1',
          itemName: 'Prod A',
          category: 'Cat',
          companyName: 'TestCo',
          buyingPrice: '50',
          sellingPrice: '100',
          gstRate: '0',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-b',
          itemNumber: 'PB-1',
          itemName: 'Prod B',
          category: 'Cat',
          companyName: 'TestCo',
          buyingPrice: '40',
          sellingPrice: '80',
          gstRate: '0',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-acme',
          itemNumber: 'PC-1',
          itemName: 'Prod PC',
          category: 'Cat',
          companyName: 'Acme Corp',
          buyingPrice: '40',
          sellingPrice: '80',
          gstRate: '0',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          buyerId: const Value('buyer-1'),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-low',
          itemNumber: 'LS-1',
          itemName: 'Low Stock Item',
          category: 'Cat',
          companyName: 'TestCo',
          buyingPrice: '10',
          sellingPrice: '20',
          gstRate: '0',
          quantityOnHand: '1',
          lowStockThreshold: '5',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'prod-ok',
          itemNumber: 'OK-1',
          itemName: 'OK Stock Item',
          category: 'Cat',
          companyName: 'TestCo',
          buyingPrice: '10',
          sellingPrice: '20',
          gstRate: '0',
          quantityOnHand: '10',
          lowStockThreshold: '5',
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: 'inv-1',
          requestId: 'req-1',
          requestHash: 'hash-1',
          invoiceNumber: 1001,
          customerId: 'customer-1',
          customerName: 'Cust A',
          customerAddress: 'Addr A',
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Test Co',
          companyAddress: 'Addr',
          companyCity: 'Mumbai',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: '2026-04-10',
          invoiceDatetime: const Value('2026-04-10T00:00:00.000Z'),
          taxRegime: 'INTRA_STATE',
          status: 'ACTIVE',
          paymentMode: '',
          subtotal: '200',
          discountTotal: '0',
          taxableTotal: '200',
          gstTotal: '0',
          grandTotal: '200',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          id: 'inv-2',
          requestId: 'req-2',
          requestHash: 'hash-2',
          invoiceNumber: 1002,
          customerId: 'customer-1',
          customerName: 'Cust A',
          customerAddress: 'Addr A',
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Test Co',
          companyAddress: 'Addr',
          companyCity: 'Mumbai',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: '2026-04-25',
          invoiceDatetime: const Value('2026-04-25T00:00:00.000Z'),
          taxRegime: 'INTRA_STATE',
          status: 'ACTIVE',
          paymentMode: '',
          subtotal: '80',
          discountTotal: '0',
          taxableTotal: '80',
          gstTotal: '0',
          grandTotal: '80',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );

  await db.into(db.invoiceItems).insert(
        InvoiceItemsCompanion.insert(
          id: 'ii-1',
          invoiceId: 'inv-1',
          productId: 'prod-a',
          lineNumber: 1,
          productName: 'Prod A',
          productCode: 'PA-1',
          productItemNumber: const Value('PA-1'),
          productItemName: const Value('Prod A'),
          productCategory: const Value('Cat'),
          productCompanyName: const Value('TestCo'),
          buyingPrice: const Value('50'),
          sellingPrice: const Value('100'),
          company: 'TestCo',
          category: 'Cat',
          quantity: '1',
          pricingMode: 'TAX_INCLUSIVE',
          enteredUnitPrice: '100',
          unitPriceExclTax: '100',
          unitPriceInclTax: '100',
          gstRate: '0',
          cgstRate: '0',
          sgstRate: '0',
          igstRate: '0',
          discountPercent: '0',
          discountAmount: '0',
          taxableAmount: '100',
          gstAmount: '0',
          cgstAmount: '0',
          sgstAmount: '0',
          igstAmount: '0',
          lineTotal: '100',
          revenueAmount: const Value('100'),
          buyingAmount: const Value('50'),
          profitAmount: const Value('50'),
        ),
      );
  await db.into(db.invoiceItems).insert(
        InvoiceItemsCompanion.insert(
          id: 'ii-2',
          invoiceId: 'inv-1',
          productId: 'prod-b',
          lineNumber: 2,
          productName: 'Prod B',
          productCode: 'PB-1',
          productItemNumber: const Value('PB-1'),
          productItemName: const Value('Prod B'),
          productCategory: const Value('Cat'),
          productCompanyName: const Value('TestCo'),
          buyingPrice: const Value('40'),
          sellingPrice: const Value('80'),
          company: 'TestCo',
          category: 'Cat',
          quantity: '1',
          pricingMode: 'TAX_INCLUSIVE',
          enteredUnitPrice: '80',
          unitPriceExclTax: '80',
          unitPriceInclTax: '80',
          gstRate: '0',
          cgstRate: '0',
          sgstRate: '0',
          igstRate: '0',
          discountPercent: '0',
          discountAmount: '0',
          taxableAmount: '100',
          gstAmount: '0',
          cgstAmount: '0',
          sgstAmount: '0',
          igstAmount: '0',
          lineTotal: '100',
          revenueAmount: const Value('100'),
          buyingAmount: const Value('40'),
          profitAmount: const Value('60'),
        ),
      );
  await db.into(db.invoiceItems).insert(
        InvoiceItemsCompanion.insert(
          id: 'ii-3',
          invoiceId: 'inv-2',
          productId: 'prod-acme',
          lineNumber: 1,
          productName: 'Prod PC',
          productCode: 'PC-1',
          productItemNumber: const Value('PC-1'),
          productItemName: const Value('Prod PC'),
          productCategory: const Value('Cat'),
          productCompanyName: const Value('Acme Corp'),
          buyingPrice: const Value('40'),
          sellingPrice: const Value('80'),
          productBuyerId: const Value('buyer-1'),
          company: 'Acme Corp',
          category: 'Cat',
          quantity: '1',
          pricingMode: 'TAX_INCLUSIVE',
          enteredUnitPrice: '80',
          unitPriceExclTax: '80',
          unitPriceInclTax: '80',
          gstRate: '0',
          cgstRate: '0',
          sgstRate: '0',
          igstRate: '0',
          discountPercent: '0',
          discountAmount: '0',
          taxableAmount: '80',
          gstAmount: '0',
          cgstAmount: '0',
          sgstAmount: '0',
          igstAmount: '0',
          lineTotal: '80',
          revenueAmount: const Value('80'),
          buyingAmount: const Value('40'),
          profitAmount: const Value('40'),
        ),
      );

  await db.into(db.customerTransactions).insert(
        CustomerTransactionsCompanion.insert(
          id: 'ct-1',
          customerId: 'customer-khata',
          invoiceId: const Value('inv-1'),
          entryType: 'CREDIT_SALE',
          amount: '500',
          occurredOn: '2026-04-20',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.customerTransactions).insert(
        CustomerTransactionsCompanion.insert(
          id: 'ct-2',
          customerId: 'customer-khata',
          requestId: const Value('req-ct-2'),
          requestHash: const Value('rh-ct-2'),
          entryType: 'COLLECTION',
          amount: '200',
          occurredOn: '2026-04-21',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );

  await db.into(db.buyerTransactions).insert(
        BuyerTransactionsCompanion.insert(
          id: 'bt-1',
          buyerId: 'buyer-payable',
          requestId: const Value('req-bt-1'),
          requestHash: const Value('rh-bt-1'),
          entryType: 'OPENING_PAYABLE',
          amount: '1000',
          occurredAt: '2026-04-01T00:00:00.000Z',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
  await db.into(db.buyerTransactions).insert(
        BuyerTransactionsCompanion.insert(
          id: 'bt-2',
          buyerId: 'buyer-payable',
          requestId: const Value('req-bt-2'),
          requestHash: const Value('rh-bt-2'),
          entryType: 'PAYMENT_MADE',
          amount: '400',
          occurredAt: '2026-04-15T00:00:00.000Z',
          createdByUserId: systemUser,
          createdAt: now,
        ),
      );
}
