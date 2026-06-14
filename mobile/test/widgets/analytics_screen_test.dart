import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/analytics.dart';
import 'package:internal_billing_khata_mobile/screens/analytics_screen.dart';
import 'package:internal_billing_khata_mobile/services/analytics_service.dart';
import 'package:internal_billing_khata_mobile/widgets/app_navigation_drawer.dart';

Future<void> _settleAnalytics(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class FakeAnalyticsService implements AnalyticsService {
  FakeAnalyticsService({
    Dashboard? dashboard,
    this.shouldThrow = false,
    List<(String?, String?)>? loadedRanges,
  })  : _dashboard = dashboard ?? Dashboard.empty(),
        loadedRanges = loadedRanges ?? [];

  final Dashboard _dashboard;
  final bool shouldThrow;
  final List<(String?, String?)> loadedRanges;
  int loadCount = 0;

  @override
  Future<Dashboard> getDashboard({
    String? fromDate,
    String? toDate,
  }) async {
    loadCount += 1;
    loadedRanges.add((fromDate, toDate));
    if (shouldThrow) {
      throw Exception('Analytics error');
    }
    return _dashboard;
  }
}

Dashboard _sampleDashboard() {
  return Dashboard(
    totalRevenue: 350,
    totalProfit: 140,
    customerReceivables: 150,
    buyerPayables: 500,
    activeInvoiceCount: 2,
    averageInvoiceValue: 175,
    dailyTrend: const [
      DailyTrendPoint(date: '2026-04-01', revenue: 0, profit: 0),
      DailyTrendPoint(date: '2026-04-02', revenue: 200, profit: 80),
      DailyTrendPoint(date: '2026-04-03', revenue: 150, profit: 60),
    ],
    revenueByCompany: const [RevenueByEntry(name: 'ParityCo', revenue: 350)],
    profitByCompany: const [ProfitByEntry(name: 'ParityCo', profit: 140)],
    revenueByCustomer: const [
      RevenueByEntry(name: 'Parity Customer', revenue: 350),
    ],
    customerKhataBalances: const [
      CustomerKhataBalance(customerName: 'Parity Customer', balance: 150),
    ],
    buyerPendingPayables: const [
      BuyerPayable(buyerName: 'Parity Buyer', payable: 500),
    ],
    topProductsByQuantity: const [
      TopProduct(productName: 'Plain Widget', quantity: 3),
    ],
    topProductsByRevenue: const [
      TopProductRevenue(productName: 'Plain Widget', revenue: 250),
    ],
    topProductsByProfit: const [
      TopProductProfit(productName: 'Plain Widget', profit: 130),
    ],
    lowStock: const [
      LowStockEntry(
        productName: 'Hidden Low Item',
        quantityOnHand: 1,
        lowStockThreshold: 5,
      ),
    ],
  );
}

void main() {
  testWidgets('drawer shows Analytics destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNavigationDrawer(
            selected: AppDestination.analytics,
            onSelect: (_) {},
            onLogout: () async {},
          ),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.text('Analytics'), findsOneWidget);
  });

  testWidgets('dashboard shows owner KPI cards and ranked sections',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(dashboard: _sampleDashboard()),
          drawer: const SizedBox(),
          now: DateTime(2026, 4, 3),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.text('Revenue'), findsAtLeast(1));
    expect(find.text('350.00'), findsWidgets);
    expect(find.text('Profit'), findsAtLeast(1));
    expect(find.text('140.00'), findsWidgets);
    expect(find.text('Receivables'), findsOneWidget);
    expect(find.text('Payables'), findsOneWidget);
    expect(find.text('Active invoices'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Avg invoice'), findsOneWidget);
    expect(find.text('175.00'), findsWidgets);
    expect(find.text('Revenue & profit trend'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Top products by revenue'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Top products by revenue'), findsOneWidget);
    expect(find.text('Plain Widget'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Top customers by revenue'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Top customers by revenue'), findsOneWidget);
    expect(find.text('Low Stock'), findsNothing);
  });

  testWidgets('preset chips reload dashboard with expected ranges',
      (tester) async {
    final service = FakeAnalyticsService(dashboard: _sampleDashboard());

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: service,
          drawer: const SizedBox(),
          now: DateTime(2026, 4, 3),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(service.loadCount, 1);
    expect(service.loadedRanges.last, ('2026-03-05', '2026-04-03'));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await _settleAnalytics(tester);
    expect(service.loadedRanges.last, ('2026-04-03', '2026-04-03'));

    await tester.tap(find.widgetWithText(ChoiceChip, '7d'));
    await _settleAnalytics(tester);
    expect(service.loadedRanges.last, ('2026-03-28', '2026-04-03'));
  });

  testWidgets('custom preset shows from and to pickers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(dashboard: _sampleDashboard()),
          drawer: const SizedBox(),
          initialPreset: AnalyticsDatePreset.custom,
          now: DateTime(2026, 4, 3),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.textContaining('From:'), findsOneWidget);
    expect(find.textContaining('To:'), findsOneWidget);
  });

  testWidgets('only low-stock data shows analytics empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(
            dashboard: Dashboard(
              totalRevenue: 0,
              totalProfit: 0,
              customerReceivables: 0,
              buyerPayables: 0,
              activeInvoiceCount: 0,
              averageInvoiceValue: 0,
              dailyTrend: const [],
              revenueByCompany: const [],
              profitByCompany: const [],
              revenueByCustomer: const [],
              customerKhataBalances: const [],
              buyerPendingPayables: const [],
              topProductsByQuantity: const [],
              topProductsByRevenue: const [],
              topProductsByProfit: const [],
              lowStock: const [
                LowStockEntry(
                  productName: 'Only Low',
                  quantityOnHand: 1,
                  lowStockThreshold: 5,
                ),
              ],
            ),
          ),
          drawer: const SizedBox(),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.text('No analytics data available'), findsOneWidget);
    expect(find.text('Low Stock'), findsNothing);
  });

  testWidgets('empty state shows message when no data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(
            dashboard: Dashboard.empty(),
          ),
          drawer: const SizedBox(),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.text('No analytics data available'), findsOneWidget);
  });

  testWidgets('error state shows error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(shouldThrow: true),
          drawer: const SizedBox(),
        ),
      ),
    );
    await _settleAnalytics(tester);

    expect(find.text('Failed to load analytics'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
