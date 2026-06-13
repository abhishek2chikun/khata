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
    this.customerAddress = '',
    this.customerState,
    this.customerStateCode,
    this.customerPhone,
    this.customerWhatsappNumber,
    this.customerGstin,
    required this.invoiceDate,
    this.invoiceDatetime = '',
    this.subtotal = 0,
    this.discountTotal = 0,
    this.taxableTotal = 0,
    this.gstTotal = 0,
    required this.grandTotal,
    this.taxRegime = '',
    this.placeOfSupplyState = '',
    this.placeOfSupplyStateCode = '',
    this.companyName = '',
    this.companyAddress = '',
    this.companyCity = '',
    this.companyState = '',
    this.companyStateCode = '',
    this.companyGstin,
    this.gstFlag = true,
    this.companyPhone,
    this.companyEmail,
    this.companyBankName,
    this.companyBankAccount,
    this.companyBankIfsc,
    this.companyBankBranch,
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
  final String customerAddress;
  final String? customerState;
  final String? customerStateCode;
  final String? customerPhone;
  final String? customerWhatsappNumber;
  final String? customerGstin;
  final String invoiceDate;
  final String invoiceDatetime;
  final double subtotal;
  final double discountTotal;
  final double taxableTotal;
  final double gstTotal;
  final double grandTotal;
  final String taxRegime;
  final String placeOfSupplyState;
  final String placeOfSupplyStateCode;
  final String companyName;
  final String companyAddress;
  final String companyCity;
  final String companyState;
  final String companyStateCode;
  final String? companyGstin;
  final bool gstFlag;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyBankName;
  final String? companyBankAccount;
  final String? companyBankIfsc;
  final String? companyBankBranch;
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
      customerAddress: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['address'] as String? ??
          json['customer_address'] as String? ??
          '',
      customerState: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['state'] as String? ??
          json['customer_state'] as String?,
      customerStateCode: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['state_code'] as String? ??
          json['customer_state_code'] as String?,
      customerPhone: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['phone'] as String? ??
          json['customer_phone'] as String?,
      customerWhatsappNumber: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['whatsapp_number'] as String? ??
          json['customer_whatsapp_number'] as String?,
      customerGstin: (json['customer_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['gstin'] as String? ??
          json['customer_gstin'] as String?,
      invoiceDate: json['invoice_date'] as String? ?? '',
      invoiceDatetime: json['invoice_datetime'] as String? ?? '',
      subtotal: _toDouble(json['subtotal']),
      discountTotal: _toDouble(json['discount_total']),
      taxableTotal: _toDouble(json['taxable_total']),
      gstTotal: _toDouble(json['gst_total']),
      grandTotal: _toDouble(json['grand_total']),
      taxRegime: json['tax_regime'] as String? ?? '',
      gstFlag: json['gst_flag'] as bool? ?? true,
      placeOfSupplyState: json['place_of_supply_state'] as String? ?? '',
      placeOfSupplyStateCode:
          json['place_of_supply_state_code'] as String? ?? '',
      companyName: (json['company_snapshot'] as Map<String, dynamic>? ??
              const <String, dynamic>{})['name'] as String? ??
          json['company_name'] as String? ??
          '',
      companyAddress: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['address'] as String? ??
          json['company_address'] as String? ??
          '',
      companyCity: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['city'] as String? ??
          json['company_city'] as String? ??
          '',
      companyState: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['state'] as String? ??
          json['company_state'] as String? ??
          '',
      companyStateCode: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['state_code'] as String? ??
          json['company_state_code'] as String? ??
          '',
      companyGstin: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['gstin'] as String? ??
          json['company_gstin'] as String?,
      companyPhone: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['phone'] as String? ??
          json['company_phone'] as String?,
      companyEmail: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['email'] as String? ??
          json['company_email'] as String?,
      companyBankName: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['bank_name'] as String? ??
          json['company_bank_name'] as String?,
      companyBankAccount: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['bank_account'] as String? ??
          json['company_bank_account'] as String?,
      companyBankIfsc: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['bank_ifsc'] as String? ??
          json['company_bank_ifsc'] as String?,
      companyBankBranch: (json['company_snapshot']
                  as Map<String, dynamic>? ??
              const <String, dynamic>{})['bank_branch'] as String? ??
          json['company_bank_branch'] as String?,
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
    this.pricingMode = '',
    this.unitPriceExclTax = 0,
    this.unitPriceInclTax = 0,
    this.gstRate = 0,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.gstAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
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
  final String pricingMode;
  final double unitPriceExclTax;
  final double unitPriceInclTax;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double discountPercent;
  final double discountAmount;
  final double taxableAmount;

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
      pricingMode: json['pricing_mode'] as String? ?? '',
      unitPriceExclTax: _toDouble(json['unit_price_excl_tax']),
      unitPriceInclTax: _toDouble(json['unit_price_incl_tax']),
      gstRate: _toDouble(json['gst_rate']),
      cgstRate: _toDouble(json['cgst_rate']),
      sgstRate: _toDouble(json['sgst_rate']),
      igstRate: _toDouble(json['igst_rate']),
      gstAmount: _toDouble(json['gst_amount']),
      cgstAmount: _toDouble(json['cgst_amount']),
      sgstAmount: _toDouble(json['sgst_amount']),
      igstAmount: _toDouble(json['igst_amount']),
      discountPercent: _toDouble(json['discount_percent']),
      discountAmount: _toDouble(json['discount_amount']),
      taxableAmount: _toDouble(json['taxable_amount']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
