class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.invoiceDate,
    required this.status,
    this.paymentState = 'CREDIT',
    required this.paymentMode,
    required this.grandTotal,
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String invoiceDate;
  final String status;
  final String paymentState;
  final String paymentMode;
  final double grandTotal;

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      id: json['id'].toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerId: json['customer_id'].toString(),
      customerName: json['customer_name'] as String? ?? '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      paymentState: json['payment_state'] as String? ??
          json['payment_mode'] as String? ??
          '',
      paymentMode: json['payment_mode'] as String? ?? '',
      grandTotal: _toDouble(json['grand_total']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
