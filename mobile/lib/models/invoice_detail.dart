class InvoiceDetail {
  const InvoiceDetail({
    required this.id,
    required this.customerId,
    required this.invoiceNumber,
    required this.status,
    this.paymentState = 'CREDIT',
    required this.paymentMode,
    this.paidAmount = 0,
    required this.customerName,
    required this.invoiceDate,
    this.invoiceDatetime = '',
    required this.grandTotal,
    required this.notes,
    required this.cancelReason,
    required this.items,
  });

  final String id;
  final String customerId;
  final String invoiceNumber;
  final String status;
  final String paymentState;
  final String paymentMode;
  final double paidAmount;
  final String customerName;
  final String invoiceDate;
  final String invoiceDatetime;
  final double grandTotal;
  final String? notes;
  final String? cancelReason;
  final List<InvoiceDetailItem> items;

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'].toString(),
      customerId: json['customer_id'].toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      paymentState: json['payment_state'] as String? ??
          json['payment_mode'] as String? ??
          '',
      paymentMode: json['payment_mode'] as String? ?? '',
      paidAmount: _toDouble(json['paid_amount']),
      customerName: (json['customer_snapshot'] as Map<String, dynamic>? ??
              const <String, dynamic>{})['name'] as String? ??
          json['customer_name'] as String? ??
          '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      invoiceDatetime: json['invoice_datetime'] as String? ?? '',
      grandTotal: _toDouble(json['grand_total']),
      notes: json['notes'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceDetailItem.fromJson)
          .toList(),
    );
  }
}

class InvoiceDetailItem {
  const InvoiceDetailItem({
    required this.productId,
    required this.productName,
    this.productItemNumber = '',
    this.productItemName = '',
    this.productCategory = '',
    this.productBuyerId,
    this.productCompanyName = '',
    this.buyingPrice = 0,
    this.sellingPrice = 0,
    this.unit,
    required this.quantity,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final String productItemNumber;
  final String productItemName;
  final String productCategory;
  final String? productBuyerId;
  final String productCompanyName;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double quantity;
  final double lineTotal;

  factory InvoiceDetailItem.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailItem(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      productItemNumber: json['product_item_number'] as String? ?? '',
      productItemName: json['product_item_name'] as String? ?? '',
      productCategory: json['product_category'] as String? ?? '',
      productBuyerId: json['product_buyer_id']?.toString(),
      productCompanyName: json['product_company_name'] as String? ?? '',
      buyingPrice: _toDouble(json['buying_price']),
      sellingPrice: _toDouble(json['selling_price']),
      unit: json['unit'] as String?,
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
