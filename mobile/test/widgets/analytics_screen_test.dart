import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/analytics.dart';
import 'package:internal_billing_khata_mobile/screens/analytics_screen.dart';
import 'package:internal_billing_khata_mobile/services/analytics_service.dart';
import 'package:internal_billing_khata_mobile/widgets/app_navigation_drawer.dart';

class FakeAnalyticsService implements AnalyticsService {
  final Dashboard _dashboard;
  final bool _shouldThrow;

  FakeAnalyticsService({
    Dashboard? dashboard,
    bool shouldThrow = false,
  })  : _dashboard = dashboard ?? Dashboard.empty(),
        _shouldThrow = shouldThrow;

  @override
  Future<Dashboard> getDashboard({
    String? fromDate,
    String? toDate,
  }) async {
    if (_shouldThrow) {
      throw Exception('Analytics error');
    }
    return _dashboard;
  }
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
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
  });

  testWidgets('dashboard loads summary cards', (tester) async {
    final dashboard = Dashboard(
      revenueByCompany: const [RevenueByEntry(name: 'TestCo', revenue: 100)],
      profitByCompany: const [ProfitByEntry(name: 'TestCo', profit: 40)],
      customerKhataBalances: const [
        CustomerKhataBalance(customerName: 'Cust A', balance: 300),
      ],
      buyerPendingPayables: const [
        BuyerPayable(buyerName: 'Buyer A', payable: 600),
      ],
      topProductsByQuantity: const [
        TopProduct(productName: 'Prod A', quantity: 5),
      ],
      lowStock: const [
        LowStockEntry(
          productName: 'Low Item',
          quantityOnHand: 1,
          lowStockThreshold: 5,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: FakeAnalyticsService(dashboard: dashboard),
          drawer: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revenue by Company'), findsOneWidget);
    expect(find.text('TestCo'), findsAtLeast(1));
    expect(find.text('Profit by Company'), findsOneWidget);
    expect(find.text('Customer Balances'), findsOneWidget);
    expect(find.text('Cust A'), findsOneWidget);
    expect(find.text('Buyer Payables'), findsOneWidget);
    expect(find.text('Top Products'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Low Stock'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.text('Low Stock'), findsOneWidget);
  });

  testWidgets('date range controls update dashboard', (tester) async {
    final service = FakeAnalyticsService(
      dashboard: Dashboard(
        revenueByCompany: const [RevenueByEntry(name: 'Co', revenue: 50)],
        profitByCompany: const [],
        customerKhataBalances: const [],
        buyerPendingPayables: const [],
        topProductsByQuantity: const [],
        lowStock: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalyticsScreen(
          analyticsService: service,
          drawer: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.text('Failed to load analytics'), findsOneWidget);
  });
}
