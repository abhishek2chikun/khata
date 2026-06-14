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
      totalRevenue: _toDouble(json['total_revenue']),
      totalProfit: _toDouble(json['total_profit']),
      customerReceivables: _toDouble(json['customer_receivables']),
      buyerPayables: _toDouble(json['buyer_payables']),
      activeInvoiceCount: (json['active_invoice_count'] as num?)?.toInt() ?? 0,
      averageInvoiceValue: _toDouble(json['average_invoice_value']),
      dailyTrend: _parseDailyTrend(json['daily_trend']),
      revenueByCompany: _parseRevenueList(json['revenue_by_company']),
      profitByCompany: _parseProfitList(json['profit_by_company']),
      revenueByCustomer: _parseRevenueList(json['revenue_by_customer']),
      customerKhataBalances:
          _parseCustomerBalances(json['customer_khata_balances']),
      buyerPendingPayables:
          _parseBuyerPayables(json['buyer_pending_payables']),
      topProductsByQuantity:
          _parseTopProducts(json['top_products_by_quantity']),
      topProductsByRevenue:
          _parseTopProductsByRevenue(json['top_products_by_revenue']),
      topProductsByProfit:
          _parseTopProductsByProfit(json['top_products_by_profit']),
      lowStock: _parseLowStock(json['low_stock']),
    );
  }

  List<DailyTrendPoint> _parseDailyTrend(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (item) => DailyTrendPoint(
            date: item['date'] as String,
            revenue: _toDouble(item['revenue']),
            profit: _toDouble(item['profit']),
          ),
        )
        .toList();
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

  List<TopProductRevenue> _parseTopProductsByRevenue(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => TopProductRevenue(
              productName: item['product_name'] as String,
              revenue: _toDouble(item['revenue']),
            ))
        .toList();
  }

  List<TopProductProfit> _parseTopProductsByProfit(List<dynamic>? items) {
    return (items ?? const [])
        .cast<Map<String, dynamic>>()
        .map((item) => TopProductProfit(
              productName: item['product_name'] as String,
              profit: _toDouble(item['profit']),
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
