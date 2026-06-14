import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/analytics.dart';

void main() {
  test('dashboard hasData ignores low stock only payloads', () {
    const dashboard = Dashboard(
      totalRevenue: 0,
      totalProfit: 0,
      customerReceivables: 0,
      buyerPayables: 0,
      activeInvoiceCount: 0,
      averageInvoiceValue: 0,
      dailyTrend: [],
      revenueByCompany: [],
      profitByCompany: [],
      revenueByCustomer: [],
      customerKhataBalances: [],
      buyerPendingPayables: [],
      topProductsByQuantity: [],
      topProductsByRevenue: [],
      topProductsByProfit: [],
      lowStock: [
        LowStockEntry(
          productName: 'Only Low',
          quantityOnHand: 1,
          lowStockThreshold: 5,
        ),
      ],
    );

    expect(dashboard.hasData, isFalse);
    expect(dashboard.lowStock, isNotEmpty);
  });

  test('dashboard hasData is true when KPI totals exist', () {
    const dashboard = Dashboard(
      totalRevenue: 100,
      totalProfit: 0,
      customerReceivables: 0,
      buyerPayables: 0,
      activeInvoiceCount: 1,
      averageInvoiceValue: 100,
      dailyTrend: [],
      revenueByCompany: [],
      profitByCompany: [],
      revenueByCustomer: [],
      customerKhataBalances: [],
      buyerPendingPayables: [],
      topProductsByQuantity: [],
      topProductsByRevenue: [],
      topProductsByProfit: [],
      lowStock: [],
    );

    expect(dashboard.hasData, isTrue);
  });
}
