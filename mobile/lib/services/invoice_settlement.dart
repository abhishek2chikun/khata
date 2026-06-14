const settlementModeCash = 'CASH';
const settlementModeCredit = 'CREDIT';

String invoiceSettlementLabel({
  required String paymentMode,
  required String paymentState,
}) {
  if (paymentMode == settlementModeCash || paymentState == 'TOTAL_PAID') {
    return 'Cash';
  }
  return 'Credit';
}

String resolveSettlementPaymentState({
  required String settlementMode,
  required double amountReceived,
}) {
  if (settlementMode == settlementModeCash) {
    return 'TOTAL_PAID';
  }
  if (amountReceived <= 0) {
    return 'CREDIT';
  }
  return 'PARTIAL_PAID';
}

String? validateCreditAmountReceived({
  required double amount,
  double? grandTotal,
}) {
  if (amount < 0) {
    return 'Amount received cannot be negative';
  }
  if (amount == 0) {
    return null;
  }
  if (grandTotal != null && amount >= grandTotal) {
    return 'Use Cash when the full amount is received';
  }
  return null;
}

String formatInvoiceQuantity(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  final text = value.toStringAsFixed(3);
  return text
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
