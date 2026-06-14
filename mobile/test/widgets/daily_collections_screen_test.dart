import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/screens/daily_collections_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  testWidgets('defaults to today and shows existing totals', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 500,
            existingTotals: <String, double>{today: 75.5},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('$today (Today)'), findsOneWidget);
    expect(find.byKey(Key('existingTotal-customer-1-$today')), findsOneWidget);
    expect(find.text('Collected: 75.50'), findsOneWidget);
  });

  testWidgets('search preserves entered values', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 500,
            existingTotals: const <String, double>{},
          ),
          CollectionGridCustomerRow(
            id: 'customer-2',
            name: 'XYZ Traders',
            pendingBalance: 300,
            existingTotals: const <String, double>{},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('additionalAmount-customer-1-$today')), '25');
    await tester.enterText(find.byKey(const Key('dailyCollectionsSearchField')), 'abc');
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsOneWidget);
    expect(find.text('XYZ Traders'), findsNothing);
    expect(find.byKey(Key('additionalAmount-customer-1-$today')), findsOneWidget);
    expect(find.text('1 entries • 25.00 total'), findsOneWidget);
  });

  testWidgets('rejects overpayment before confirmation', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 100,
            existingTotals: const <String, double>{},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('additionalAmount-customer-1-$today')), '150');
    await tester.tap(find.byKey(const Key('saveDailyCollectionsButton')));
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores exceeds pending balance'), findsOneWidget);
    expect(service.batchCalls, isEmpty);
  });

  testWidgets('successful save clears committed inputs and refreshes grid', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 500,
            existingTotals: const <String, double>{},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('additionalAmount-customer-1-$today')), '40');
    await tester.tap(find.byKey(const Key('saveDailyCollectionsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDailyCollectionsButton')));
    await tester.pumpAndSettle();

    expect(service.batchCalls, hasLength(1));
    expect(service.batchCalls.single.entries.single.amount, 40);
    expect(find.byKey(const Key('dailyCollectionsSuccessMessage')), findsOneWidget);
    expect(find.textContaining('Posted 1 entries totaling 40.00'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(Key('additionalAmount-customer-1-$today'))).controller?.text, isEmpty);
    expect(service.loadCount, 2);
  });

  testWidgets('stale balance preserves unsaved values after reload', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 500,
            existingTotals: const <String, double>{},
          ),
        ],
      ),
      batchError: const ApiError(
        code: 'STALE_BALANCE',
        message: 'Collection total exceeds current pending balance',
        statusCode: 409,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('additionalAmount-customer-1-$today')), '40');
    await tester.tap(find.byKey(const Key('saveDailyCollectionsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDailyCollectionsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Collection total exceeds current pending balance'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(Key('additionalAmount-customer-1-$today'))).controller?.text, '40');
  });

  testWidgets('idempotency conflict reloads grid while preserving inputs', (tester) async {
    final today = _todayString();
    final service = _FakePaymentsService(
      grid: CollectionGridData(
        fromDate: today,
        toDate: today,
        dates: <String>[today],
        customers: <CollectionGridCustomerRow>[
          CollectionGridCustomerRow(
            id: 'customer-1',
            name: 'ABC Stores',
            pendingBalance: 500,
            existingTotals: const <String, double>{},
          ),
        ],
      ),
      batchError: const ApiError(
        code: 'IDEMPOTENCY_CONFLICT',
        message: 'Batch request ID already used with different payload',
        statusCode: 409,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyCollectionsScreen(paymentsService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('additionalAmount-customer-1-$today')), '40');
    await tester.tap(find.byKey(const Key('saveDailyCollectionsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDailyCollectionsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Batch request ID already used with different payload'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(Key('additionalAmount-customer-1-$today'))).controller?.text, '40');
    expect(service.loadCount, greaterThan(1));
  });
}

class _FakePaymentsService implements PaymentsService {
  _FakePaymentsService({
    required this.grid,
    this.batchError,
  });

  CollectionGridData grid;
  final ApiError? batchError;
  var loadCount = 0;
  final List<BatchCollectionInput> batchCalls = <BatchCollectionInput>[];

  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) async {}

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) async {}

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {}

  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) async {
    loadCount += 1;
    return grid;
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(BatchCollectionInput input) async {
    if (batchError != null) {
      throw batchError!;
    }
    batchCalls.add(input);
    grid = CollectionGridData(
      fromDate: grid.fromDate,
      toDate: grid.toDate,
      dates: grid.dates,
      customers: grid.customers
          .map(
            (customer) => CollectionGridCustomerRow(
              id: customer.id,
              name: customer.name,
              pendingBalance: customer.pendingBalance - _enteredAmount(input, customer.id),
              existingTotals: customer.existingTotals,
            ),
          )
          .toList(),
    );
    final totalAmount = input.entries.fold<double>(0, (total, entry) => total + entry.amount);
    return BatchCollectionResult(
      requestId: input.requestId,
      entryCount: input.entries.length,
      totalAmount: totalAmount,
      affectedCustomers: input.entries.map((entry) => entry.customerId).toSet().length,
    );
  }

  double _enteredAmount(BatchCollectionInput input, String customerId) {
    return input.entries
        .where((entry) => entry.customerId == customerId)
        .fold<double>(0, (total, entry) => total + entry.amount);
  }
}

String _todayString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
