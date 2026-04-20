class InvoiceQuote {
  const InvoiceQuote({
    required this.placeOfSupplyState,
    required this.placeOfSupplyStateCode,
    required this.taxRegime,
    required this.items,
    required this.totals,
    required this.warnings,
  });

  final String placeOfSupplyState;
  final String placeOfSupplyStateCode;
  final String taxRegime;
  final List<InvoiceQuoteItem> items;
  final InvoiceTotals totals;
  final List<InvoiceWarning> warnings;

  factory InvoiceQuote.fromJson(Map<String, dynamic> json) {
    return InvoiceQuote(
      placeOfSupplyState: json['place_of_supply_state'] as String? ?? '',
      placeOfSupplyStateCode: json['place_of_supply_state_code'] as String? ?? '',
      taxRegime: json['tax_regime'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceQuoteItem.fromJson)
          .toList(),
      totals: InvoiceTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
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
    required this.quantity,
    required this.unitPriceExclTax,
    required this.lineTotal,
  });

  final String productId;
  final double quantity;
  final double unitPriceExclTax;
  final double lineTotal;

  factory InvoiceQuoteItem.fromJson(Map<String, dynamic> json) {
    return InvoiceQuoteItem(
      productId: json['product_id']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      unitPriceExclTax: _toDouble(json['unit_price_excl_tax']),
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
