import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/screens/record_payment_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  testWidgets('record collection submits generated request id', (tester) async {
    final service = FakePaymentsService();
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RecordCollectionScreen(
          paymentsService: service,
          customer: _customer,
          onSubmitted: () {
            submitted = true;
          },
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('collectionAmountField')), '125.50');
    await tester.enterText(
        find.byKey(const Key('collectionOccurredOnField')), '2026-04-20');
    await tester.enterText(
        find.byKey(const Key('collectionNotesField')), 'Cash');

    await tester.tap(find.byKey(const Key('submitCollectionButton')));
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(service.recordedCollections, hasLength(1));
    final collection = service.recordedCollections.single;
    expect(collection.customerId, 'customer-1');
    expect(collection.amount, 125.50);
    expect(collection.occurredOn, '2026-04-20');
    expect(collection.notes, 'Cash');
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(collection.requestId),
      isTrue,
    );
  });

  testWidgets('record collection shows error banner on failure',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecordCollectionScreen(
          paymentsService: FakePaymentsService(
            error: const ApiError(message: 'Unable to record collection'),
          ),
          customer: _customer,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('collectionAmountField')), '125.50');
    await tester.enterText(
        find.byKey(const Key('collectionOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitCollectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to record collection'), findsOneWidget);
  });

  testWidgets('record collection requires a valid amount before calling api',
      (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RecordCollectionScreen(
          paymentsService: service,
          customer: _customer,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('collectionAmountField')), 'abc');
    await tester.enterText(
        find.byKey(const Key('collectionOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitCollectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.recordedCollections, isEmpty);
  });

  testWidgets('record collection requires occurred on before calling api',
      (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RecordCollectionScreen(
          paymentsService: service,
          customer: _customer,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('collectionAmountField')), '125.50');
    await tester.enterText(
        find.byKey(const Key('collectionOccurredOnField')), '');
    await tester.tap(find.byKey(const Key('submitCollectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Occurred on is required'), findsOneWidget);
    expect(service.recordedCollections, isEmpty);
  });
}

const _customer = Customer(
  id: 'customer-1',
  name: 'ABC Stores',
  address: 'Market Yard',
  phone: '9999999999',
  gstin: '27BBBBB0000B1Z5',
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 500,
);

class FakePaymentsService implements PaymentsService {
  FakePaymentsService({this.error});

  final ApiError? error;
  final List<RecordCollectionInput> recordedCollections =
      <RecordCollectionInput>[];

  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {
    if (error != null) {
      throw error!;
    }
    recordedCollections.add(input);
  }
  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(BatchCollectionInput input) {
    throw UnimplementedError();
  }

}
