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

    return Dashboard(
      revenueByCompany: await _revenueByCompany(activeInvoiceIds),
      profitByCompany: await _profitByCompany(activeInvoiceIds),
      customerKhataBalances: await _customerKhataBalances(),
      buyerPendingPayables: await _buyerPendingPayables(),
      topProductsByQuantity: await _topProductsByQuantity(activeInvoiceIds),
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
      query.where((invoice) => invoice.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((invoice) => invoice.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    final invoices = await query.get();
    return invoices.map((invoice) => invoice.id).toSet();
  }

  Future<List<RevenueByEntry>> _revenueByCompany(
      Set<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    final items = await (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.isIn(invoiceIds.toList())))
        .get();
    final aggregated = <String, double>{};
    for (final item in items) {
      final company = item.productCompanyName;
      aggregated[company] =
          (aggregated[company] ?? 0.0) + (double.tryParse(item.lineTotal) ?? 0.0);
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => RevenueByEntry(name: e.key, revenue: e.value))
        .toList();
  }

  Future<List<ProfitByEntry>> _profitByCompany(
      Set<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    final items = await (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.isIn(invoiceIds.toList())))
        .get();
    final aggregated = <String, double>{};
    for (final item in items) {
      final company = item.productCompanyName;
      final revenue = double.tryParse(item.lineTotal) ?? 0.0;
      final qty = double.tryParse(item.quantity) ?? 0.0;
      final buying = double.tryParse(item.buyingPrice) ?? 0.0;
      final profit = revenue - (buying * qty);
      aggregated[company] = (aggregated[company] ?? 0.0) + profit;
    }
    final entries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => ProfitByEntry(name: e.key, profit: e.value))
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
    final customerNames = <String, String>{};
    for (final c in customers) {
      customerNames[c.id] = c.name;
    }
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
    final buyerNames = <String, String>{};
    for (final b in buyers) {
      buyerNames[b.id] = b.name;
    }
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

  Future<List<TopProduct>> _topProductsByQuantity(
      Set<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return [];
    final items = await (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.isIn(invoiceIds.toList())))
        .get();
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
