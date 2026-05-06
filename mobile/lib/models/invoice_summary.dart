class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.sellerId,
    required this.sellerName,
    required this.invoiceDate,
    required this.status,
    required this.paymentMode,
    required this.grandTotal,
  });

  final String id;
  final String invoiceNumber;
  final String sellerId;
  final String sellerName;
  final String invoiceDate;
  final String status;
  final String paymentMode;
  final double grandTotal;

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      id: json['id'].toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      sellerId: json['seller_id'].toString(),
      sellerName: json['seller_name'] as String? ?? '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
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
