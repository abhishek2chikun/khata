import 'dart:convert';

import '../models/analytics.dart';
import 'analytics_service.dart';
import 'api_client.dart';

class ApiAnalyticsService implements AnalyticsService {
  ApiAnalyticsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Dashboard> getDashboard({String? fromDate, String? toDate}) async {
    final queryParams = <String, String?>{
      'from_date': fromDate,
      'to_date': toDate,
    };
    final response = await _apiClient.get(
      '/analytics/dashboard',
      queryParameters: queryParams,
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseDashboard(decoded);
  }

  Dashboard _parseDashboard(Map<String, dynamic> json) {
    return Dashboard(
      revenueByCompany: _parseRevenueList(json['revenue_by_company']),
      profitByCompany: _parseProfitList(json['profit_by_company']),
      customerKhataBalances:
          _parseCustomerBalances(json['customer_khata_balances']),
      buyerPendingPayables:
          _parseBuyerPayables(json['buyer_pending_payables']),
      topProductsByQuantity:
          _parseTopProducts(json['top_products_by_quantity']),
      lowStock: _parseLowStock(json['low_stock']),
    );
  }

  List<RevenueByEntry> _parseRevenueList(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => RevenueByEntry(
              name: item['name'] as String,
              revenue: _toDouble(item['revenue']),
            ))
        .toList();
  }

  List<ProfitByEntry> _parseProfitList(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => ProfitByEntry(
              name: item['name'] as String,
              profit: _toDouble(item['profit']),
            ))
        .toList();
  }

  List<CustomerKhataBalance> _parseCustomerBalances(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => CustomerKhataBalance(
              customerName: item['customer_name'] as String,
              balance: _toDouble(item['balance']),
            ))
        .toList();
  }

  List<BuyerPayable> _parseBuyerPayables(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => BuyerPayable(
              buyerName: item['buyer_name'] as String,
              payable: _toDouble(item['payable']),
            ))
        .toList();
  }

  List<TopProduct> _parseTopProducts(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => TopProduct(
              productName: item['product_name'] as String,
              quantity: _toDouble(item['quantity']),
            ))
        .toList();
  }

  List<LowStockEntry> _parseLowStock(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => LowStockEntry(
              productName: item['product_name'] as String,
              quantityOnHand: _toDouble(item['quantity_on_hand']),
              lowStockThreshold: _toDouble(item['low_stock_threshold']),
            ))
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
