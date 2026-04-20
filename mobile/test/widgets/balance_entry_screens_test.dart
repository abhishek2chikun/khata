import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/screens/balance_adjustment_screen.dart';
import 'package:internal_billing_khata_mobile/screens/opening_balance_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  testWidgets('opening balance submits generated request id', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: OpeningBalanceScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('openingBalanceAmountField')), '300');
    await tester.enterText(find.byKey(const Key('openingBalanceOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();

    expect(service.openingBalances, hasLength(1));
    final openingBalance = service.openingBalances.single;
    expect(openingBalance.sellerId, 'seller-1');
    expect(openingBalance.input.amount, 300);
    expect(openingBalance.input.occurredOn, '2026-04-20');
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(openingBalance.input.requestId),
      isTrue,
    );
  });

  testWidgets('opening balance shows error banner on failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpeningBalanceScreen(
          paymentsService: FakePaymentsService(
            openingBalanceError: const ApiError(message: 'Unable to save opening balance'),
          ),
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('openingBalanceAmountField')), '300');
    await tester.enterText(find.byKey(const Key('openingBalanceOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to save opening balance'), findsOneWidget);
  });

  testWidgets('opening balance requires valid amount and occurred on', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: OpeningBalanceScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('openingBalanceAmountField')), '');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.openingBalances, isEmpty);

    await tester.enterText(find.byKey(const Key('openingBalanceAmountField')), '250');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();
    expect(find.text('Occurred on is required'), findsOneWidget);
    expect(service.openingBalances, isEmpty);
  });

  testWidgets('balance adjustment submits generated request id', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: BalanceAdjustmentScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('balanceAdjustmentDirectionField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decrease').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('balanceAdjustmentAmountField')), '75');
    await tester.enterText(find.byKey(const Key('balanceAdjustmentOccurredOnField')), '2026-04-20');
    await tester.enterText(find.byKey(const Key('balanceAdjustmentNotesField')), 'Correction');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();

    expect(service.adjustments, hasLength(1));
    final adjustment = service.adjustments.single;
    expect(adjustment.sellerId, 'seller-1');
    expect(adjustment.input.direction, 'DECREASE');
    expect(adjustment.input.amount, 75);
    expect(adjustment.input.occurredOn, '2026-04-20');
    expect(adjustment.input.notes, 'Correction');
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(adjustment.input.requestId),
      isTrue,
    );
  });

  testWidgets('balance adjustment shows error banner on failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BalanceAdjustmentScreen(
          paymentsService: FakePaymentsService(
            adjustmentError: const ApiError(message: 'Unable to save adjustment'),
          ),
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('balanceAdjustmentAmountField')), '75');
    await tester.enterText(find.byKey(const Key('balanceAdjustmentOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to save adjustment'), findsOneWidget);
  });

  testWidgets('balance adjustment requires valid amount and occurred on', (tester) async {
    final service = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: BalanceAdjustmentScreen(
          paymentsService: service,
          seller: _seller,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('balanceAdjustmentAmountField')), 'oops');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid amount'), findsOneWidget);
    expect(service.adjustments, isEmpty);

    await tester.enterText(find.byKey(const Key('balanceAdjustmentAmountField')), '50');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();
    expect(find.text('Occurred on is required'), findsOneWidget);
    expect(service.adjustments, isEmpty);
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
  FakePaymentsService({
    this.paymentError,
    this.openingBalanceError,
    this.adjustmentError,
  });

  final ApiError? paymentError;
  final ApiError? openingBalanceError;
  final ApiError? adjustmentError;
  final List<_OpeningBalanceCall> openingBalances = <_OpeningBalanceCall>[];
  final List<_BalanceAdjustmentCall> adjustments = <_BalanceAdjustmentCall>[];

  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) async {
    if (adjustmentError != null) {
      throw adjustmentError!;
    }
    adjustments.add(_BalanceAdjustmentCall(sellerId: sellerId, input: input));
  }

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) async {
    if (openingBalanceError != null) {
      throw openingBalanceError!;
    }
    openingBalances.add(_OpeningBalanceCall(sellerId: sellerId, input: input));
  }

  @override
  Future<void> recordPayment(RecordPaymentInput input) async {
    if (paymentError != null) {
      throw paymentError!;
    }
  }
}

class _OpeningBalanceCall {
  const _OpeningBalanceCall({required this.sellerId, required this.input});

  final String sellerId;
  final OpeningBalanceInput input;
}

class _BalanceAdjustmentCall {
  const _BalanceAdjustmentCall({required this.sellerId, required this.input});

  final String sellerId;
  final BalanceAdjustmentInput input;
}
