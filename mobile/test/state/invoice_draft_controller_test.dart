import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
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

    controller.updateSeller(_seller);
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

    controller.updateSeller(_seller);
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

const _seller = Seller(
  id: 'seller-1',
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
  company: 'Acme',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemCode: 'PEN-1',
  defaultSellingPriceExclTax: 10,
  defaultGstRate: 18,
  quantityOnHand: 4,
  lowStockThreshold: 2,
  isActive: true,
);

final _invoiceDetail = InvoiceDetail(
  id: 'inv-1',
  sellerId: 'seller-1',
  invoiceNumber: '1001',
  status: 'ACTIVE',
  paymentMode: 'CREDIT',
  sellerName: 'ABC Stores',
  invoiceDate: '2026-04-20',
  grandTotal: 118,
  notes: null,
  cancelReason: null,
  items: const <InvoiceDetailItem>[
    InvoiceDetailItem(
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
