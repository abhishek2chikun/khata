import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/services/invoice_settlement.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/state/invoice_draft_controller.dart';

void main() {
  test(
      'invoice draft controller reuses request id across safe retry after submit failure timeout',
      () async {
    final invoicesService = FakeInvoicesService(
      createResponses: <Object>[
        const SocketException('timed out'),
        CreateInvoiceResult(
          invoice: _invoiceDetail,
          warnings: const <InvoiceWarning>[],
        ),
      ],
    );
    final controller = InvoiceDraftController(invoicesService: invoicesService);

    controller.updateCustomer(_customer);
    controller.updateInvoiceDate('2026-04-20');
    controller.updatePlaceOfSupplyStateCode('27');
    controller.updateItemProduct(0, _product);

    await controller.submitInvoice();

    final firstRequestId = controller.requestId;
    expect(firstRequestId, isNotNull);
    expect(controller.submitErrorMessage, contains('Connect to the server'));
    expect(controller.createdInvoice, isNull);

    await controller.submitInvoice();

    expect(controller.createdInvoice?.id, 'inv-1');
    expect(controller.requestId, isNull);
    expect(invoicesService.createRequestIds,
        <String>[firstRequestId!, firstRequestId]);
  });

  test('updateSettlementMode maps Cash to TOTAL_PAID in payload', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );

    controller.updateSettlementMode(settlementModeCash);
    expect(controller.draft.paymentMode, settlementModeCash);
    expect(controller.draft.toJson()['payment_state'], 'TOTAL_PAID');
    expect(controller.draft.toJson()['payment_mode'], settlementModeCash);
  });

  test('unpaid Credit maps to CREDIT with zero paid amount', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );

    controller.updateSettlementMode(settlementModeCredit);
    controller.updateAmountReceived(0);
    expect(controller.draft.toJson()['payment_state'], 'CREDIT');
    expect(controller.draft.toJson()['paid_amount'], 0);
  });

  test('partial Credit maps to PARTIAL_PAID after quote', () async {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(quoteResponse: _quote),
    );
    controller.updateCustomer(_customer);
    controller.updateItemProduct(0, _product);
    controller.updateSettlementMode(settlementModeCredit);
    controller.updateAmountReceived(100);

    await controller.requestQuote();

    expect(controller.draft.toJson()['payment_state'], 'PARTIAL_PAID');
    expect(controller.draft.paidAmount, 100);
  });

  test('Cash resolves paid amount to quote grand total', () async {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(quoteResponse: _quote),
    );
    controller.updateCustomer(_customer);
    controller.updateItemProduct(0, _product);
    controller.updateSettlementMode(settlementModeCash);

    await controller.requestQuote();

    expect(controller.draft.paymentState, 'TOTAL_PAID');
    expect(controller.draft.paidAmount, 236);
  });

  test('Credit equal to total is rejected with Cash guidance', () async {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(quoteResponse: _quote),
    );
    controller.updateCustomer(_customer);
    controller.updateItemProduct(0, _product);
    controller.updateSettlementMode(settlementModeCredit);
    controller.updateAmountReceived(236);

    final quoted = await controller.requestQuote();

    expect(quoted, isFalse);
    expect(controller.amountReceivedError, contains('Use Cash'));
  });

  test('Credit over total is rejected', () async {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(quoteResponse: _quote),
    );
    controller.updateCustomer(_customer);
    controller.updateItemProduct(0, _product);
    controller.updateSettlementMode(settlementModeCredit);
    controller.updateAmountReceived(300);

    final quoted = await controller.requestQuote();

    expect(quoted, isFalse);
    expect(controller.amountReceivedError, isNotNull);
  });

  test('draft always serializes zero discount_percent', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );
    controller.updateItemProduct(0, _product);

    expect(
      controller.draft.toJson()['items'][0]['discount_percent'],
      0,
    );
  });

  test('draft serializes integral quantity and three-decimal unit price', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );
    controller.updateItemProduct(0, _product);
    controller.updateItemQuantity(0, 2);
    controller.updateItemUnitPrice(0, 12.345);

    final item = controller.draft.toJson()['items'][0] as Map<String, dynamic>;
    expect(item['quantity'], 2);
    expect(item['unit_price'], 12.345);
  });

  test('switching gst off clears line gst overrides', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );
    controller.updateItemProduct(0, _product);
    controller.updateItemGstRate(0, 12);
    controller.setGstFlag(false);

    expect(controller.draft.items.single.gstRate, 0);
  });

  test('updatePaymentState syncs paymentMode so toJson reflects current selection',
      () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );

    controller.updatePaymentState('TOTAL_PAID');
    expect(controller.draft.paymentState, 'TOTAL_PAID');
    expect(controller.draft.paymentMode, settlementModeCash);
    expect(controller.draft.toJson()['payment_state'], 'TOTAL_PAID');

    controller.updatePaymentState('CREDIT');
    expect(controller.draft.paymentState, 'CREDIT');
    expect(controller.draft.paymentMode, settlementModeCredit);
    expect(controller.draft.toJson()['payment_state'], 'CREDIT');
  });

  test('updatePaymentState to PARTIAL_PAID serializes correctly', () {
    final controller = InvoiceDraftController(
      invoicesService: FakeInvoicesService(),
    );

    controller.updatePaymentState('PARTIAL_PAID');
    controller.updatePaidAmount(50);
    expect(controller.draft.paymentState, 'PARTIAL_PAID');
    expect(controller.draft.paymentMode, settlementModeCredit);
    expect(controller.draft.toJson()['payment_state'], 'PARTIAL_PAID');
    expect(controller.draft.toJson()['paid_amount'], 50);
  });

  test(
      'editing draft after failure clears request id so next submit uses a new one',
      () async {
    final invoicesService = FakeInvoicesService(
      createResponses: <Object>[
        const ApiError(message: 'Unable to save invoice', statusCode: 500),
        CreateInvoiceResult(
          invoice: _invoiceDetail,
          warnings: const <InvoiceWarning>[],
        ),
      ],
    );
    final controller = InvoiceDraftController(invoicesService: invoicesService);

    controller.updateCustomer(_customer);
    controller.updateInvoiceDate('2026-04-20');
    controller.updatePlaceOfSupplyStateCode('27');
    controller.updateItemProduct(0, _product);

    await controller.submitInvoice();
    final failedRequestId = controller.requestId;

    controller.updateNotes('changed after failure');
    expect(controller.requestId, isNull);

    await controller.submitInvoice();

    expect(controller.createdInvoice?.invoiceNumber, '1001');
    expect(controller.requestId, isNull);
    expect(invoicesService.createRequestIds, hasLength(2));
    expect(invoicesService.createRequestIds.first, failedRequestId);
    expect(invoicesService.createRequestIds.last, isNot(failedRequestId));
  });
}

const _customer = Customer(
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

const _product = Product(
  id: 'product-1',
  companyName: 'Acme',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemNumber: 'PEN-1',
  buyingPrice: 10,
  sellingPrice: 10,
  gstRate: 18,
  quantityOnHand: 4,
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

final _invoiceDetail = InvoiceDetail(
  id: 'inv-1',
  customerId: 'customer-1',
  invoiceNumber: '1001',
  status: 'ACTIVE',
  paymentMode: 'CREDIT',
  customerName: 'ABC Stores',
  invoiceDate: '2026-04-20',
  grandTotal: 118,
  notes: null,
  cancelReason: null,
  items: const <InvoiceDetailItem>[
    InvoiceDetailItem(
      productId: 'product-1',
      productName: 'Blue Pen',
      quantity: 1,
      lineTotal: 118,
    ),
  ],
);

class FakeInvoicesService implements InvoicesService {
  FakeInvoicesService({
    this.quoteResponse,
    this.quoteError,
    this.createResponses = const <Object>[],
  });

  final InvoiceQuote? quoteResponse;
  final Object? quoteError;
  final List<Object> createResponses;
  final List<String> createRequestIds = <String>[];
  var _createCallCount = 0;

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) async {
    createRequestIds.add(requestId);
    final response = createResponses[_createCallCount];
    _createCallCount += 1;
    if (response is Exception) {
      throw response;
    }
    if (response is Error) {
      throw response;
    }
    return response as CreateInvoiceResult;
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async {
    if (quoteError != null) {
      throw quoteError!;
    }
    return quoteResponse!;
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
