import 'product.dart';
import 'customer.dart';

class InvoiceDraft {
  const InvoiceDraft({
    this.customer,
    this.invoiceDatetime,
    this.invoiceDate = '',
    String paymentState = 'CREDIT',
    this.paidAmount = 0,
    String? paymentMode,
    this.placeOfSupplyStateCode,
    this.notes,
    this.items = const <InvoiceDraftItem>[InvoiceDraftItem()],
  })  : paymentState = paymentState,
        paymentMode = paymentMode ?? paymentState;

  final Customer? customer;
  final String? invoiceDatetime;
  final String invoiceDate;
  final String paymentState;
  final double paidAmount;
  final String paymentMode;
  final String? placeOfSupplyStateCode;
  final String? notes;
  final List<InvoiceDraftItem> items;

  InvoiceDraft copyWith({
    Customer? customer,
    bool clearCustomer = false,
    String? invoiceDatetime,
    bool clearInvoiceDatetime = false,
    String? invoiceDate,
    String? paymentState,
    double? paidAmount,
    String? paymentMode,
    String? placeOfSupplyStateCode,
    bool clearPlaceOfSupplyStateCode = false,
    String? notes,
    bool clearNotes = false,
    List<InvoiceDraftItem>? items,
  }) {
    return InvoiceDraft(
      customer: clearCustomer ? null : customer ?? this.customer,
      invoiceDatetime:
          clearInvoiceDatetime ? null : invoiceDatetime ?? this.invoiceDatetime,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      paymentState: paymentState ?? this.paymentState,
      paidAmount: paidAmount ?? this.paidAmount,
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
      'customer_id': customer?.id,
      'invoice_datetime': _emptyToNull(invoiceDatetime),
      'invoice_date': invoiceDate,
      'payment_state': paymentState,
      'paid_amount': paidAmount,
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
    this.pricingMode = 'TAX_INCLUSIVE',
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
