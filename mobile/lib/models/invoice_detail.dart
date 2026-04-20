class InvoiceDetail {
  const InvoiceDetail({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.paymentMode,
    required this.sellerName,
    required this.invoiceDate,
    required this.grandTotal,
    required this.items,
  });

  final String id;
  final String invoiceNumber;
  final String status;
  final String paymentMode;
  final String sellerName;
  final String invoiceDate;
  final double grandTotal;
  final List<InvoiceDetailItem> items;

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'].toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? '',
      sellerName:
          (json['seller_snapshot'] as Map<String, dynamic>? ?? const <String, dynamic>{})['name'] as String? ??
          json['seller_name'] as String? ??
          '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      grandTotal: _toDouble(json['grand_total']),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceDetailItem.fromJson)
          .toList(),
    );
  }
}

class InvoiceDetailItem {
  const InvoiceDetailItem({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
  });

  final String productName;
  final double quantity;
  final double lineTotal;

  factory InvoiceDetailItem.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailItem(
      productName: json['product_name'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      lineTotal: _toDouble(json['line_total']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
