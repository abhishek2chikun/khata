import 'seller.dart';

class SellerLedger {
  const SellerLedger({
    required this.seller,
    required this.transactions,
    required this.invoices,
  });

  final Seller seller;
  final List<SellerLedgerTransaction> transactions;
  final List<SellerInvoiceHistoryEntry> invoices;

  factory SellerLedger.fromJson(Map<String, dynamic> json) {
    return SellerLedger(
      seller: Seller.fromJson(json['seller'] as Map<String, dynamic>),
      transactions: (json['transactions'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(SellerLedgerTransaction.fromJson)
          .toList(),
      invoices: (json['invoices'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(SellerInvoiceHistoryEntry.fromJson)
          .toList(),
    );
  }
}

class SellerLedgerTransaction {
  const SellerLedgerTransaction({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.occurredOn,
    required this.notes,
  });

  final String id;
  final String entryType;
  final double amount;
  final String occurredOn;
  final String? notes;

  factory SellerLedgerTransaction.fromJson(Map<String, dynamic> json) {
    return SellerLedgerTransaction(
      id: json['id'].toString(),
      entryType: json['entry_type'] as String? ?? '',
      amount: _toDouble(json['amount']),
      occurredOn: json['occurred_on'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class SellerInvoiceHistoryEntry {
  const SellerInvoiceHistoryEntry({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.grandTotal,
    required this.paymentMode,
    required this.status,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String invoiceDate;
  final double grandTotal;
  final String paymentMode;
  final String status;

  factory SellerInvoiceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SellerInvoiceHistoryEntry(
      invoiceId: json['invoice_id'].toString(),
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      grandTotal: _toDouble(json['grand_total']),
      paymentMode: json['payment_mode'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
