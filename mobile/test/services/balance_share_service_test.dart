import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/services/balance_share_service.dart';

Customer _customer({
  required String id,
  required String name,
  required double pendingBalance,
  bool isActive = true,
}) {
  return Customer(
    id: id,
    name: name,
    address: 'Address',
    phone: null,
    gstin: null,
    state: null,
    stateCode: null,
    isActive: isActive,
    pendingBalance: pendingBalance,
  );
}

void main() {
  test('formats individual current balance without sensitive fields', () {
    final message = formatIndividualBalanceShareMessage(
      sellerName: 'Khata Traders',
      customerName: 'Acme Stores',
      pendingBalance: 500,
      asOfDate: '2026-06-13',
    );

    expect(message, contains('Khata Traders'));
    expect(message, contains('Acme Stores'));
    expect(message, contains('Pending balance: 500.00'));
    expect(message, contains('As of: 2026-06-13'));
    expect(message, isNot(contains('GSTIN')));
    expect(message, isNot(contains('Phone')));
    expect(message, isNot(contains('Bank')));
    expect(message, isNot(contains('customer-1')));
  });

  test('daily summary filters non-positive sorts and totals', () {
    final message = formatDailyBalanceShareMessage(
      sellerName: 'Khata Traders',
      asOfDate: '2026-06-13',
      customers: <Customer>[
        _customer(id: 'c-2', name: 'Zed Stores', pendingBalance: 200),
        _customer(id: 'c-1', name: 'alpha shop', pendingBalance: 100),
        _customer(id: 'c-3', name: 'Zero Balance', pendingBalance: 0),
        _customer(id: 'c-4', name: 'Negative', pendingBalance: -50),
        _customer(
          id: 'c-5',
          name: 'Archived Due',
          pendingBalance: 300,
          isActive: false,
        ),
      ],
    );

    expect(message, contains('alpha shop: 100.00'));
    expect(message, contains('Zed Stores: 200.00'));
    expect(
        message.indexOf('alpha shop'), lessThan(message.indexOf('Zed Stores')));
    expect(message, contains('Total: 300.00'));
    expect(message, isNot(contains('Zero Balance')));
    expect(message, isNot(contains('Negative')));
    expect(message, isNot(contains('Archived Due')));
  });

  test('daily summary empty is shareable', () {
    final message = formatDailyBalanceShareMessage(
      sellerName: 'Khata Traders',
      asOfDate: '2026-06-13',
      customers: const <Customer>[],
    );

    expect(message, 'No pending customer balances as of 2026-06-13.');
  });

  test('shareText delegates to injected handler', () async {
    final calls = <String>[];
    final service = BalanceShareService.withHandler(
      shareText: (message) async {
        calls.add(message);
      },
    );

    await service.shareText('Hello balance');

    expect(calls, <String>['Hello balance']);
  });
}
