import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/screens/record_payment_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  testWidgets('record payment submits generated request id', (tester) async {
    final service = FakePaymentsService();
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RecordPaymentScreen(
          paymentsService: service,
          seller: _seller,
          onSubmitted: () {
            submitted = true;
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '125.50');
    await tester.enterText(find.byKey(const Key('paymentOccurredOnField')), '2026-04-20');
    await tester.enterText(find.byKey(const Key('paymentNotesField')), 'Cash');

    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(service.recordedPayments, hasLength(1));
    final payment = service.recordedPayments.single;
    expect(payment.sellerId, 'seller-1');
    expect(payment.amount, 125.50);
    expect(payment.occurredOn, '2026-04-20');
    expect(payment.notes, 'Cash');
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(payment.requestId),
      isTrue,
    );
  });

  testWidgets('record payment shows error banner on failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecordPaymentScreen(
          paymentsService: FakePaymentsService(
            error: const ApiError(message: 'Unable to record payment'),
          ),
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '125.50');
    await tester.enterText(find.byKey(const Key('paymentOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to record payment'), findsOneWidget);
  });

  testWidgets('record payment requires a valid amount before calling api', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RecordPaymentScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('paymentAmountField')), 'abc');
    await tester.enterText(find.byKey(const Key('paymentOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.recordedPayments, isEmpty);
  });

  testWidgets('record payment requires occurred on before calling api', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RecordPaymentScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '125.50');
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Occurred on is required'), findsOneWidget);
    expect(service.recordedPayments, isEmpty);
  });
}

const _seller = Seller(
  id: 'seller-1',
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
  final List<RecordPaymentInput> recordedPayments = <RecordPaymentInput>[];

  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> recordPayment(RecordPaymentInput input) async {
    if (error != null) {
      throw error!;
    }
    recordedPayments.add(input);
  }
}
