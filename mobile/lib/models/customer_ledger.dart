import 'customer.dart';

class CustomerLedger {
  const CustomerLedger({
    required this.customer,
    required this.transactions,
    required this.invoices,
  });

  final Customer customer;
  final List<CustomerLedgerTransaction> transactions;
  final List<CustomerInvoiceHistoryEntry> invoices;

  factory CustomerLedger.fromJson(Map<String, dynamic> json) {
    return CustomerLedger(
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      transactions: (json['transactions'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(CustomerLedgerTransaction.fromJson)
          .toList(),
      invoices: (json['invoices'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(CustomerInvoiceHistoryEntry.fromJson)
          .toList(),
    );
  }
}

class CustomerLedgerTransaction {
  const CustomerLedgerTransaction({
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

  factory CustomerLedgerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerTransaction(
      id: json['id'].toString(),
      entryType: json['entry_type'] as String? ?? '',
      amount: _toDouble(json['amount']),
      occurredOn: json['occurred_on'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class CustomerInvoiceHistoryEntry {
  const CustomerInvoiceHistoryEntry({
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

  factory CustomerInvoiceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceHistoryEntry(
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
