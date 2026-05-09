import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/screens/invoice_preview_screen.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/state/invoice_draft_controller.dart';

void main() {
  testWidgets('preview shows item name item number category unit quantity price per unit line total',
      (tester) async {
    final controller = await _makeController(quote: _quote);

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.textContaining('PEN-1'), findsOneWidget);
    expect(find.textContaining('Pens'), findsOneWidget);
    expect(find.textContaining('PCS'), findsOneWidget);
    expect(find.byKey(const Key('quantity-0')), findsOneWidget);
    expect(find.byKey(const Key('pricePerUnit-0')), findsOneWidget);
    expect(find.byKey(const Key('lineTotal-0')), findsOneWidget);
  });

  testWidgets('preview shows inclusive GST totals', (tester) async {
    final controller = await _makeController(quote: _quote);

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gstTotal')), findsOneWidget);
    expect(find.byKey(const Key('grandTotal')), findsOneWidget);
  });

  testWidgets('preview shows payment state and paid amount', (tester) async {
    final controller = await _makeController(
      quote: _quote,
      paymentState: 'PARTIAL_PAID',
      paidAmount: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentStateLabel')), findsOneWidget);
    expect(find.byKey(const Key('paidAmountLabel')), findsOneWidget);
  });

  testWidgets('preview hides internal cost buying price from invoice view',
      (tester) async {
    final controller = await _makeController(quote: _quote);

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buyingPrice-0')), findsNothing);
    expect(find.text('Cost'), findsNothing);
    expect(find.text('Buying price'), findsNothing);
  });

  testWidgets('preview shows Credit payment state label', (tester) async {
    final controller = await _makeController(quote: _quote, paymentState: 'CREDIT');

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentStateLabel')), findsOneWidget);
    expect(find.textContaining('Credit'), findsOneWidget);
  });

  testWidgets('preview shows Total Paid payment state without paid amount field',
      (tester) async {
    final controller = await _makeController(
      quote: _quote,
      paymentState: 'TOTAL_PAID',
      paidAmount: 236,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentStateLabel')), findsOneWidget);
    expect(find.byKey(const Key('paidAmountLabel')), findsOneWidget);
  });
}

Future<InvoiceDraftController> _makeController({
  required InvoiceQuote quote,
  String paymentState = 'CREDIT',
  double paidAmount = 0,
}) async {
  final service = _StaticInvoicesService(quoteResponse: quote);
  final customer = const Customer(
    id: 'customer-1',
    name: 'ABC Stores',
    address: 'Market Yard',
    phone: '9999999999',
    gstin: '27BBBBB0000B1Z5',
    state: 'Maharashtra',
    stateCode: '27',
    isActive: true,
    pendingBalance: 0,
  );
  final controller = InvoiceDraftController(
    invoicesService: service,
    initialCustomer: customer,
  );
  controller.updatePaymentState(paymentState);
  if (paidAmount > 0) {
    controller.updatePaidAmount(paidAmount);
  }
  controller.updateItemProduct(0, _product);
  await controller.requestQuote();
  return controller;
}

const _product = Product(
  id: 'product-1',
  companyName: 'Acme',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemNumber: 'PEN-1',
  buyingPrice: 50,
  sellingPrice: 100,
  unit: 'PCS',
  gstRate: 18,
  quantityOnHand: 10,
  lowStockThreshold: 2,
  isActive: true,
);

const _quote = InvoiceQuote(
  placeOfSupplyState: 'Maharashtra',
  placeOfSupplyStateCode: '27',
  taxRegime: 'INTRA_STATE',
  items: <InvoiceQuoteItem>[
    InvoiceQuoteItem(
      productId: 'product-1',
      productItemName: 'Blue Pen',
      productItemNumber: 'PEN-1',
      productCategory: 'Pens',
      unit: 'PCS',
      quantity: 2,
      sellingPrice: 100,
      enteredUnitPrice: 100,
      unitPriceExclTax: 100,
      unitPriceInclTax: 118,
      gstRate: 18,
      gstAmount: 36,
      lineTotal: 236,
    ),
  ],
  totals: InvoiceTotals(
    subtotal: 200,
    discountTotal: 0,
    taxableTotal: 200,
    gstTotal: 36,
    grandTotal: 236,
  ),
  warnings: <InvoiceWarning>[],
);

class _StaticInvoicesService implements InvoicesService {
  _StaticInvoicesService({required this.quoteResponse});

  final InvoiceQuote quoteResponse;

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async =>
      quoteResponse;

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) {
    throw UnimplementedError();
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) {
    throw UnimplementedError();
  }
}
