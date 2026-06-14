import '../services/invoice_settlement.dart';
import 'product.dart';
import 'customer.dart';

class InvoiceDraft {
  const InvoiceDraft({
    this.customer,
    this.invoiceDate = '',
    String paymentState = 'CREDIT',
    this.paidAmount = 0,
    String? paymentMode,
    this.placeOfSupplyStateCode,
    this.notes,
    this.gstFlag,
    this.items = const <InvoiceDraftItem>[InvoiceDraftItem()],
  })  : paymentState = paymentState,
        paymentMode = paymentMode ?? settlementModeCredit;

  final Customer? customer;
  final String invoiceDate;
  final String paymentState;
  final double paidAmount;
  final String paymentMode;
  final String? placeOfSupplyStateCode;
  final String? notes;
  final bool? gstFlag;
  final List<InvoiceDraftItem> items;

  InvoiceDraft copyWith({
    Customer? customer,
    bool clearCustomer = false,
    String? invoiceDate,
    String? paymentState,
    double? paidAmount,
    String? paymentMode,
    String? placeOfSupplyStateCode,
    bool clearPlaceOfSupplyStateCode = false,
    String? notes,
    bool clearNotes = false,
    bool? gstFlag,
    bool clearGstFlag = false,
    List<InvoiceDraftItem>? items,
  }) {
    return InvoiceDraft(
      customer: clearCustomer ? null : customer ?? this.customer,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      paymentState: paymentState ?? this.paymentState,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      placeOfSupplyStateCode: clearPlaceOfSupplyStateCode
          ? null
          : placeOfSupplyStateCode ?? this.placeOfSupplyStateCode,
      notes: clearNotes ? null : notes ?? this.notes,
      gstFlag: clearGstFlag ? null : gstFlag ?? this.gstFlag,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    final resolvedPaymentState = _resolvedPaymentState();
    return <String, dynamic>{
      'customer_id': customer?.id,
      'invoice_date': invoiceDate,
      'payment_state': resolvedPaymentState,
      'payment_mode': paymentMode,
      'paid_amount': paidAmount,
      'place_of_supply_state_code': _emptyToNull(placeOfSupplyStateCode),
      'notes': _emptyToNull(notes),
      if (gstFlag != null) 'gst_flag': gstFlag,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String _resolvedPaymentState() {
    if (paymentMode == settlementModeCash) {
      return 'TOTAL_PAID';
    }
    if (paymentMode == settlementModeCredit) {
      return resolveSettlementPaymentState(
        settlementMode: paymentMode,
        amountReceived: paidAmount,
      );
    }
    if (paymentMode == 'PAID') {
      return 'TOTAL_PAID';
    }
    if (paymentMode != paymentState) {
      return paymentMode;
    }
    return paymentState;
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
