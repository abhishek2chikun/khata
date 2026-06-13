class InvoiceQuote {
  const InvoiceQuote({
    required this.placeOfSupplyState,
    required this.placeOfSupplyStateCode,
    required this.taxRegime,
    this.gstFlag = true,
    required this.items,
    required this.totals,
    required this.warnings,
  });

  final String placeOfSupplyState;
  final String placeOfSupplyStateCode;
  final String taxRegime;
  final bool gstFlag;
  final List<InvoiceQuoteItem> items;
  final InvoiceTotals totals;
  final List<InvoiceWarning> warnings;

  factory InvoiceQuote.fromJson(Map<String, dynamic> json) {
    return InvoiceQuote(
      placeOfSupplyState: json['place_of_supply_state'] as String? ?? '',
      placeOfSupplyStateCode:
          json['place_of_supply_state_code'] as String? ?? '',
      taxRegime: json['tax_regime'] as String? ?? '',
      gstFlag: json['gst_flag'] as bool? ?? true,
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceQuoteItem.fromJson)
          .toList(),
      totals: InvoiceTotals.fromJson(
          json['totals'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceWarning.fromJson)
          .toList(),
    );
  }
}

class InvoiceQuoteItem {
  const InvoiceQuoteItem({
    required this.productId,
    this.productItemNumber = '',
    this.productItemName = '',
    this.productCategory = '',
    this.productBuyerId,
    this.productCompanyName = '',
    this.buyingPrice = 0,
    this.sellingPrice = 0,
    this.unit,
    required this.quantity,
    this.pricingMode = 'TAX_INCLUSIVE',
    this.enteredUnitPrice = 0,
    required this.unitPriceExclTax,
    this.unitPriceInclTax = 0,
    this.gstRate = 0,
    this.gstAmount = 0,
    required this.lineTotal,
  });

  final String productId;
  final String productItemNumber;
  final String productItemName;
  final String productCategory;
  final String? productBuyerId;
  final String productCompanyName;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double quantity;
  final String pricingMode;
  final double enteredUnitPrice;
  final double unitPriceExclTax;
  final double unitPriceInclTax;
  final double gstRate;
  final double gstAmount;
  final double lineTotal;

  factory InvoiceQuoteItem.fromJson(Map<String, dynamic> json) {
    return InvoiceQuoteItem(
      productId: json['product_id']?.toString() ?? '',
      productItemNumber: json['product_item_number'] as String? ?? '',
      productItemName: json['product_item_name'] as String? ?? '',
      productCategory: json['product_category'] as String? ?? '',
      productBuyerId: json['product_buyer_id']?.toString(),
      productCompanyName: json['product_company_name'] as String? ?? '',
      buyingPrice: _toDouble(json['buying_price']),
      sellingPrice: _toDouble(json['selling_price']),
      unit: json['unit'] as String?,
      quantity: _toDouble(json['quantity']),
      pricingMode: json['pricing_mode'] as String? ?? '',
      enteredUnitPrice: _toDouble(json['entered_unit_price']),
      unitPriceExclTax: _toDouble(json['unit_price_excl_tax']),
      unitPriceInclTax: _toDouble(json['unit_price_incl_tax']),
      gstRate: _toDouble(json['gst_rate']),
      gstAmount: _toDouble(json['gst_amount']),
      lineTotal: _toDouble(json['line_total']),
    );
  }
}

class InvoiceTotals {
  const InvoiceTotals({
    required this.subtotal,
    required this.discountTotal,
    required this.taxableTotal,
    required this.gstTotal,
    required this.grandTotal,
  });

  final double subtotal;
  final double discountTotal;
  final double taxableTotal;
  final double gstTotal;
  final double grandTotal;

  factory InvoiceTotals.fromJson(Map<String, dynamic> json) {
    return InvoiceTotals(
      subtotal: _toDouble(json['subtotal']),
      discountTotal: _toDouble(json['discount_total']),
      taxableTotal: _toDouble(json['taxable_total']),
      gstTotal: _toDouble(json['gst_total']),
      grandTotal: _toDouble(json['grand_total']),
    );
  }
}

class InvoiceWarning {
  const InvoiceWarning({required this.code, required this.message});

  final String code;
  final String message;

  factory InvoiceWarning.fromJson(Map<String, dynamic> json) {
    return InvoiceWarning(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
