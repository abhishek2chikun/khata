import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/screens/invoice_preview_screen.dart';
import 'package:internal_billing_khata_mobile/services/invoice_settlement.dart';
import 'package:internal_billing_khata_mobile/services/invoice_share_service.dart';
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

  testWidgets('preview shows payment mode and amount received', (tester) async {
    final controller = await _makeController(
      quote: _quote,
      paymentMode: settlementModeCredit,
      paidAmount: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentModeLabel')), findsOneWidget);
    expect(find.byKey(const Key('amountReceivedLabel')), findsOneWidget);
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

  testWidgets('preview shows Credit payment mode label', (tester) async {
    final controller = await _makeController(
      quote: _quote,
      paymentMode: settlementModeCredit,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentModeLabel')), findsOneWidget);
    expect(find.textContaining('Credit'), findsOneWidget);
  });

  testWidgets('preview shows Cash payment mode without amount received field',
      (tester) async {
    final controller = await _makeController(
      quote: _quote,
      paymentMode: settlementModeCash,
      paidAmount: 236,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paymentModeLabel')), findsOneWidget);
    expect(find.textContaining('Cash'), findsOneWidget);
    expect(find.byKey(const Key('amountReceivedLabel')), findsNothing);
  });

  testWidgets('post-creation shows share buttons when invoice is created',
      (tester) async {
    final createdInvoice = InvoiceDetail(
      id: 'inv-1',
      customerId: 'customer-1',
      invoiceNumber: '42',
      status: 'ACTIVE',
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      customerName: 'ABC Stores',
      invoiceDate: '2026-01-10',
      grandTotal: 236,
      notes: null,
      cancelReason: null,
      items: const <InvoiceDetailItem>[
        InvoiceDetailItem(
          productId: 'product-1',
          productName: 'Blue Pen',
          quantity: 2,
          lineTotal: 236,
        ),
      ],
    );
    final service = _CreateInvoicesService(createdInvoice: createdInvoice);
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
    controller.updateItemProduct(0, _product);
    await controller.requestQuote();
    await controller.submitInvoice();

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(
          controller: controller,
          shareService: _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sharePdfButton')), findsOneWidget);
    expect(find.byKey(const Key('sendSmsButton')), findsOneWidget);
    expect(find.text('Share PDF (WhatsApp and more)'), findsOneWidget);
    expect(find.text('Invoice created'), findsOneWidget);
  });

  testWidgets('view pdf button visible before confirm when company profile provided',
      (tester) async {
    final controller = await _makeController(quote: _quote);

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(
          controller: controller,
          companyProfile: _companyProfile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('viewPdfButton')), findsOneWidget);
    expect(find.byKey(const Key('confirmInvoiceButton')), findsOneWidget);
  });

  testWidgets('view pdf button hidden after invoice is created', (tester) async {
    final createdInvoice = InvoiceDetail(
      id: 'inv-1',
      customerId: 'customer-1',
      invoiceNumber: '42',
      status: 'ACTIVE',
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      customerName: 'ABC Stores',
      invoiceDate: '2026-01-10',
      grandTotal: 236,
      notes: null,
      cancelReason: null,
      items: const <InvoiceDetailItem>[
        InvoiceDetailItem(
          productId: 'product-1',
          productName: 'Blue Pen',
          quantity: 2,
          lineTotal: 236,
        ),
      ],
    );
    final service = _CreateInvoicesService(createdInvoice: createdInvoice);
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
    controller.updateItemProduct(0, _product);
    await controller.requestQuote();
    await controller.submitInvoice();

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(
          controller: controller,
          companyProfile: _companyProfile,
          shareService: _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('viewPdfButton')), findsNothing);
    expect(find.byKey(const Key('sharePdfButton')), findsOneWidget);
  });

  testWidgets('non-gst preview hides item number in item subtitle', (tester) async {
    const nonGstQuote = InvoiceQuote(
      placeOfSupplyState: 'Maharashtra',
      placeOfSupplyStateCode: '27',
      taxRegime: 'INTRA_STATE',
      gstFlag: false,
      items: <InvoiceQuoteItem>[
        InvoiceQuoteItem(
          productId: 'product-1',
          productItemName: 'Blue Pen',
          productItemNumber: 'PEN-1',
          productCategory: 'Pens',
          unit: 'PCS',
          quantity: 1,
          enteredUnitPrice: 100,
          unitPriceExclTax: 100,
          lineTotal: 100,
        ),
      ],
      totals: InvoiceTotals(
        subtotal: 100,
        discountTotal: 0,
        taxableTotal: 100,
        gstTotal: 0,
        grandTotal: 100,
      ),
      warnings: <InvoiceWarning>[],
    );
    final controller = await _makeController(quote: nonGstQuote);

    await tester.pumpWidget(
      MaterialApp(
        home: InvoicePreviewScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PEN-1'), findsNothing);
    expect(find.textContaining('Pens'), findsOneWidget);
    expect(find.byKey(const Key('gstTotal')), findsNothing);
  });
}

Future<InvoiceDraftController> _makeController({
  required InvoiceQuote quote,
  String paymentMode = settlementModeCredit,
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
  controller.updateSettlementMode(paymentMode);
  if (paidAmount > 0) {
    controller.updateAmountReceived(paidAmount);
  }
  controller.updateItemProduct(0, _product);
  await controller.requestQuote();
  return controller;
}

const _companyProfile = CompanyProfile(
  id: 'company-1',
  name: 'Acme Traders',
  address: 'Main Road',
  city: 'Pune',
  state: 'Maharashtra',
  stateCode: '27',
  gstin: '27AAAAA0000A1Z5',
  gstFlag: true,
  phone: '9999999999',
  email: 'owner@example.com',
  bankName: 'ABC Bank',
  bankAccount: '1234567890',
  bankIfsc: 'ABC0001234',
  bankBranch: 'Pune',
  jurisdiction: 'Pune',
  isActive: true,
);

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

class _CreateInvoicesService implements InvoicesService {
  _CreateInvoicesService({required this.createdInvoice});

  final InvoiceDetail createdInvoice;

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async => _quote;

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) async {
    return CreateInvoiceResult(
      invoice: createdInvoice,
      warnings: const <InvoiceWarning>[],
    );
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

class _FakeShareService implements InvoiceShareService {
  @override
  Future<void> shareInvoicePdf(String filePath, {required String text}) async {}

  @override
  Future<void> shareViaSms(String phoneNumber) async {}
}
