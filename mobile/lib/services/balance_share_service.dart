import 'package:share_plus/share_plus.dart';

import '../models/customer.dart';

String formatIndividualBalanceShareMessage({
  required String sellerName,
  required String customerName,
  required double pendingBalance,
  required String asOfDate,
}) {
  return [
    sellerName,
    customerName,
    'Pending balance: ${pendingBalance.toStringAsFixed(2)}',
    'As of: $asOfDate',
    'Please settle at your earliest convenience.',
  ].join('\n');
}

String formatDailyBalanceShareMessage({
  required String sellerName,
  required String asOfDate,
  required List<Customer> customers,
}) {
  final dueCustomers = customers
      .where((customer) => customer.isActive && customer.pendingBalance > 0)
      .toList()
    ..sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

  if (dueCustomers.isEmpty) {
    return 'No pending customer balances as of $asOfDate.';
  }

  final lines = <String>[
    sellerName,
    'Pending balances as of $asOfDate:',
  ];
  var total = 0.0;
  for (final customer in dueCustomers) {
    lines
        .add('${customer.name}: ${customer.pendingBalance.toStringAsFixed(2)}');
    total += customer.pendingBalance;
  }
  lines.add('Total: ${total.toStringAsFixed(2)}');
  return lines.join('\n');
}

abstract class BalanceShareService {
  Future<void> shareText(String message);

  factory BalanceShareService.production() = _ProductionBalanceShareService;

  factory BalanceShareService.withHandler({
    required Future<void> Function(String message) shareText,
  }) = _HandlerBalanceShareService;
}

class _ProductionBalanceShareService implements BalanceShareService {
  @override
  Future<void> shareText(String message) async {
    await Share.share(message);
  }
}

class _HandlerBalanceShareService implements BalanceShareService {
  _HandlerBalanceShareService(
      {required Future<void> Function(String) shareText})
      : _shareText = shareText;

  final Future<void> Function(String message) _shareText;

  @override
  Future<void> shareText(String message) async {
    await _shareText(message);
  }
}
