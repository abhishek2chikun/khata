import 'product.dart';
import 'seller.dart';

class InvoiceDraft {
  const InvoiceDraft({
    this.seller,
    this.invoiceDate = '',
    this.paymentMode = 'CREDIT',
    this.placeOfSupplyStateCode,
    this.notes,
    this.items = const <InvoiceDraftItem>[InvoiceDraftItem()],
  });

  final Seller? seller;
  final String invoiceDate;
  final String paymentMode;
  final String? placeOfSupplyStateCode;
  final String? notes;
  final List<InvoiceDraftItem> items;

  InvoiceDraft copyWith({
    Seller? seller,
    bool clearSeller = false,
    String? invoiceDate,
    String? paymentMode,
    String? placeOfSupplyStateCode,
    bool clearPlaceOfSupplyStateCode = false,
    String? notes,
    bool clearNotes = false,
    List<InvoiceDraftItem>? items,
  }) {
    return InvoiceDraft(
      seller: clearSeller ? null : seller ?? this.seller,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      paymentMode: paymentMode ?? this.paymentMode,
      placeOfSupplyStateCode: clearPlaceOfSupplyStateCode
          ? null
          : placeOfSupplyStateCode ?? this.placeOfSupplyStateCode,
      notes: clearNotes ? null : notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'seller_id': seller?.id,
      'invoice_date': invoiceDate,
      'payment_mode': paymentMode,
      'place_of_supply_state_code': _emptyToNull(placeOfSupplyStateCode),
      'notes': _emptyToNull(notes),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class InvoiceDraftItem {
  const InvoiceDraftItem({
    this.product,
    this.quantity = 1,
    this.pricingMode = 'PRE_TAX',
    this.unitPrice,
    this.gstRate,
    this.discountPercent = 0,
  });

  final Product? product;
  final double quantity;
  final String pricingMode;
  final double? unitPrice;
  final double? gstRate;
  final double discountPercent;

  InvoiceDraftItem copyWith({
    Product? product,
    bool clearProduct = false,
    double? quantity,
    String? pricingMode,
    double? unitPrice,
    bool clearUnitPrice = false,
    double? gstRate,
    bool clearGstRate = false,
    double? discountPercent,
  }) {
    return InvoiceDraftItem(
      product: clearProduct ? null : product ?? this.product,
      quantity: quantity ?? this.quantity,
      pricingMode: pricingMode ?? this.pricingMode,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      gstRate: clearGstRate ? null : gstRate ?? this.gstRate,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': product?.id,
      'quantity': quantity,
      'pricing_mode': pricingMode,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
      'discount_percent': discountPercent,
    };
  }
}

String? _emptyToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
