import 'package:drift/drift.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';
import 'local_database.dart';

class LocalAnalyticsService implements AnalyticsService {
  LocalAnalyticsService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

  @override
  Future<Dashboard> getDashboard({String? fromDate, String? toDate}) async {
    final activeInvoiceIds = await _activeInvoiceIds(
      fromDate: fromDate,
      toDate: toDate,
    );
    final activeInvoices = await _activeInvoices(
      invoiceIds: activeInvoiceIds,
    );
    final items = await _invoiceItems(activeInvoiceIds);
    final customerKhataBalances = await _customerKhataBalances();
    final buyerPendingPayables = await _buyerPendingPayables();

    final totalRevenue = _sumItemField(items, (item) => item.revenueAmount);
    final totalProfit = _sumItemField(items, (item) => item.profitAmount);
    final activeInvoiceCount = activeInvoices.length;
    final grandTotal = activeInvoices.fold<double>(
      0,
      (sum, invoice) => sum + (double.tryParse(invoice.grandTotal) ?? 0.0),
    );
    final averageInvoiceValue =
        activeInvoiceCount == 0 ? 0.0 : grandTotal / activeInvoiceCount;

    return Dashboard(
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      customerReceivables: customerKhataBalances.fold(
        0.0,
        (sum, entry) => sum + entry.balance,
      ),
      buyerPayables: buyerPendingPayables.fold(
        0.0,
        (sum, entry) => sum + entry.payable,
      ),
      activeInvoiceCount: activeInvoiceCount,
      averageInvoiceValue: averageInvoiceValue,
      dailyTrend: _dailyTrend(
        activeInvoices: activeInvoices,
        items: items,
        fromDate: fromDate,
        toDate: toDate,
      ),
      revenueByCompany: _revenueByCompany(items),
      profitByCompany: _profitByCompany(items),
      revenueByCustomer: _revenueByCustomer(activeInvoices),
      customerKhataBalances: customerKhataBalances,
      buyerPendingPayables: buyerPendingPayables,
      topProductsByQuantity: _topProductsByQuantity(items),
      topProductsByRevenue: _topProductsByRevenue(items),
      topProductsByProfit: _topProductsByProfit(items),
      lowStock: await _lowStock(),
    );
  }

  Future<Set<String>> _activeInvoiceIds({
    String? fromDate,
    String? toDate,
  }) async {
    final query = _database.select(_database.invoices)
      ..where((invoice) => invoice.status.equals('ACTIVE'));
    if (fromDate != null) {
      query.where(
          (invoice) => invoice.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(
          (invoice) => invoice.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    final invoices = await query.get();
    return invoices.map((invoice) => invoice.id).toSet();
  }

  Future<List<Invoice>> _activeInvoices({required Set<String> invoiceIds}) async {
    if (invoiceIds.isEmpty) return [];
    return (_database.select(_database.invoices)
          ..where((invoice) => invoice.id.isIn(invoiceIds.toList())))
        .get();
  }

  Future<List<InvoiceItem>> _invoiceItems(Set<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    return (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.isIn(invoiceIds.toList())))
        .get();
  }

  double _sumItemField(
    List<InvoiceItem> items,
    String? Function(InvoiceItem item) field,
  ) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(field(item) ?? '') ?? 0.0),
    );
  }

  List<DailyTrendPoint> _dailyTrend({
    required List<Invoice> activeInvoices,
    required List<InvoiceItem> items,
    String? fromDate,
    String? toDate,
  }) {
    final revenueByDate = <String, double>{};
    final profitByDate = <String, double>{};
    final invoiceDates = {
      for (final invoice in activeInvoices) invoice.id: invoice.invoiceDate,
    };

    for (final item in items) {
      final date = invoiceDates[item.invoiceId];
      if (date == null) continue;
      revenueByDate[date] = (revenueByDate[date] ?? 0.0) +
          (double.tryParse(item.revenueAmount) ?? 0.0);
      profitByDate[date] = (profitByDate[date] ?? 0.0) +
          (double.tryParse(item.profitAmount) ?? 0.0);
    }

    if (fromDate != null && toDate != null) {
      final points = <DailyTrendPoint>[];
      var current = DateTime.parse(fromDate);
      final end = DateTime.parse(toDate);
      while (!current.isAfter(end)) {
        final key = _formatDate(current);
        points.add(
          DailyTrendPoint(
            date: key,
            revenue: revenueByDate[key] ?? 0.0,
            profit: profitByDate[key] ?? 0.0,
          ),
        );
        current = current.add(const Duration(days: 1));
      }
      return points;
    }

    final dates = revenueByDate.keys.toList()..sort();
    return dates
        .map(
          (date) => DailyTrendPoint(
            date: date,
            revenue: revenueByDate[date] ?? 0.0,
            profit: profitByDate[date] ?? 0.0,
          ),
        )
        .toList();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<RevenueByEntry> _revenueByCompany(List<InvoiceItem> items) {
    if (items.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final item in items) {
      final company = item.productCompanyName;
      aggregated[company] = (aggregated[company] ?? 0.0) +
          (double.tryParse(item.revenueAmount) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => RevenueByEntry(name: e.key, revenue: e.value))
        .toList();
  }

  List<ProfitByEntry> _profitByCompany(List<InvoiceItem> items) {
    if (items.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final item in items) {
      final company = item.productCompanyName;
      final profit = double.tryParse(item.profitAmount) ?? 0.0;
      aggregated[company] = (aggregated[company] ?? 0.0) + profit;
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => ProfitByEntry(name: e.key, profit: e.value))
        .toList();
  }

  List<RevenueByEntry> _revenueByCustomer(List<Invoice> invoices) {
    if (invoices.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final invoice in invoices) {
      aggregated[invoice.customerName] =
          (aggregated[invoice.customerName] ?? 0.0) +
              (double.tryParse(invoice.grandTotal) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => RevenueByEntry(name: e.key, revenue: e.value))
        .toList();
  }

  Future<List<CustomerKhataBalance>> _customerKhataBalances() async {
    const creditTypes = {
      'OPENING_BALANCE',
      'CREDIT_SALE',
      'BALANCE_INCREASE_ADJUSTMENT',
      'COLLECTION_REVERSAL',
    };
    final transactions =
        await _database.select(_database.customerTransactions).get();
    final customers = await _database.select(_database.customers).get();
    final customerNames = <String, String>{
      for (final customer in customers) customer.id: customer.name,
    };
    final balances = <String, double>{};
    for (final txn in transactions) {
      final isCredit = creditTypes.contains(txn.entryType);
      final amount = double.tryParse(txn.amount) ?? 0.0;
      final customerId = txn.customerId;
      balances[customerId] =
          (balances[customerId] ?? 0.0) + (isCredit ? amount : -amount);
    }
    final entries = balances.entries.toList()
      ..sort((a, b) =>
          (customerNames[a.key] ?? '').compareTo(customerNames[b.key] ?? ''));
    return entries
        .map((e) => CustomerKhataBalance(
              customerName: customerNames[e.key] ?? e.key,
              balance: e.value,
            ))
        .toList();
  }

  Future<List<BuyerPayable>> _buyerPendingPayables() async {
    const increaseTypes = {
      'OPENING_PAYABLE',
      'PURCHASE_AMOUNT',
      'PAYABLE_INCREASE_ADJUSTMENT',
    };
    final transactions =
        await _database.select(_database.buyerTransactions).get();
    final buyers = await _database.select(_database.buyers).get();
    final buyerNames = <String, String>{
      for (final buyer in buyers) buyer.id: buyer.name,
    };
    final payables = <String, double>{};
    for (final txn in transactions) {
      final isIncrease = increaseTypes.contains(txn.entryType);
      final amount = double.tryParse(txn.amount) ?? 0.0;
      final buyerId = txn.buyerId;
      payables[buyerId] =
          (payables[buyerId] ?? 0.0) + (isIncrease ? amount : -amount);
    }
    final entries = payables.entries.toList()
      ..sort((a, b) =>
          (buyerNames[a.key] ?? '').compareTo(buyerNames[b.key] ?? ''));
    return entries
        .map((e) => BuyerPayable(
              buyerName: buyerNames[e.key] ?? e.key,
              payable: e.value,
            ))
        .toList();
  }

  List<TopProduct> _topProductsByQuantity(List<InvoiceItem> items) {
    if (items.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final item in items) {
      final name = item.productItemName;
      aggregated[name] =
          (aggregated[name] ?? 0.0) + (double.tryParse(item.quantity) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => TopProduct(productName: e.key, quantity: e.value))
        .toList();
  }

  List<TopProductRevenue> _topProductsByRevenue(List<InvoiceItem> items) {
    if (items.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final item in items) {
      final name = item.productItemName;
      aggregated[name] = (aggregated[name] ?? 0.0) +
          (double.tryParse(item.revenueAmount) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => TopProductRevenue(productName: e.key, revenue: e.value))
        .toList();
  }

  List<TopProductProfit> _topProductsByProfit(List<InvoiceItem> items) {
    if (items.isEmpty) return [];
    final aggregated = <String, double>{};
    for (final item in items) {
      final name = item.productItemName;
      aggregated[name] = (aggregated[name] ?? 0.0) +
          (double.tryParse(item.profitAmount) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => TopProductProfit(productName: e.key, profit: e.value))
        .toList();
  }

  Future<List<LowStockEntry>> _lowStock() async {
    final products = await (_database.select(_database.products)
          ..where((product) => product.isActive.equals(true)))
        .get();
    return products
        .where((product) {
          final qty = double.tryParse(product.quantityOnHand) ?? 0.0;
          final threshold = double.tryParse(product.lowStockThreshold) ?? 0.0;
          return qty <= threshold;
        })
        .map((product) => LowStockEntry(
              productName: product.itemName,
              quantityOnHand: double.tryParse(product.quantityOnHand) ?? 0.0,
              lowStockThreshold:
                  double.tryParse(product.lowStockThreshold) ?? 0.0,
            ))
        .toList()
      ..sort((a, b) => a.productName.compareTo(b.productName));
  }
}
