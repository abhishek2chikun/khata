import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';

void main() {
  group('ApiInvoicesService', () {
    test('quote parses backend-shaped items and totals', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, dynamic>{
            'place_of_supply_state': 'Maharashtra',
            'place_of_supply_state_code': '27',
            'tax_regime': 'INTRA_STATE',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'product_id': 'product-1',
                'quantity': '2.000',
                'pricing_mode': 'PRE_TAX',
                'entered_unit_price': '100.00',
                'unit_price_excl_tax': '100.00',
                'unit_price_incl_tax': '118.00',
                'gst_rate': '18.00',
                'cgst_rate': '9.00',
                'sgst_rate': '9.00',
                'igst_rate': '0.00',
                'discount_percent': '0.00',
                'discount_amount': '0.00',
                'taxable_amount': '200.00',
                'gst_amount': '36.00',
                'cgst_amount': '18.00',
                'sgst_amount': '18.00',
                'igst_amount': '0.00',
                'line_total': '236.00',
              },
            ],
            'totals': <String, dynamic>{
              'subtotal': '200.00',
              'discount_total': '0.00',
              'taxable_total': '200.00',
              'gst_total': '36.00',
              'grand_total': '236.00',
            },
            'warnings': <Map<String, dynamic>>[],
          }),
        ),
      );
      final service = ApiInvoicesService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      final quote = await service.quoteInvoice(_draft);

      expect(httpClient.lastMethod, 'POST');
      expect(httpClient.lastPath, '/invoices/quote');
      expect(quote.items.single.productId, 'product-1');
      expect(quote.items.single.quantity, 2);
      expect(quote.items.single.unitPriceExclTax, 100);
      expect(quote.items.single.lineTotal, 236);
      expect(quote.totals.subtotal, 200);
      expect(quote.totals.discountTotal, 0);
      expect(quote.totals.taxableTotal, 200);
      expect(quote.totals.gstTotal, 36);
      expect(quote.totals.grandTotal, 236);
    });

    test('create parses nested seller snapshot and full item objects', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 201,
          body: jsonEncode(<String, dynamic>{
            'invoice': <String, dynamic>{
              'id': 'inv-1',
              'request_id': 'request-1',
              'invoice_number': 1001,
              'seller_id': 'seller-1',
              'invoice_date': '2026-04-20',
              'tax_regime': 'INTRA_STATE',
              'status': 'ACTIVE',
              'payment_mode': 'CREDIT',
              'place_of_supply_state': 'Maharashtra',
              'place_of_supply_state_code': '27',
              'subtotal': '200.00',
              'discount_total': '0.00',
              'taxable_total': '200.00',
              'gst_total': '36.00',
              'grand_total': '236.00',
              'notes': 'Handle with care',
              'created_at': '2026-04-20T10:00:00Z',
              'cancel_request_id': null,
              'cancel_reason': null,
              'canceled_at': null,
              'seller_snapshot': <String, dynamic>{
                'id': 'seller-1',
                'name': 'ABC Stores',
                'address': 'Market Yard',
                'state': 'Maharashtra',
                'state_code': '27',
                'phone': '9999999999',
                'gstin': '27BBBBB0000B1Z5',
              },
              'company_snapshot': <String, dynamic>{
                'name': 'Acme Traders',
                'address': 'Main Road',
                'city': 'Pune',
                'state': 'Maharashtra',
                'state_code': '27',
                'gstin': '27AAAAA0000A1Z5',
                'phone': '9999999998',
                'email': 'billing@example.com',
                'bank_name': null,
                'bank_account': null,
                'bank_ifsc': null,
                'bank_branch': null,
                'jurisdiction': null,
              },
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'item-1',
                  'product_id': 'product-1',
                  'line_number': 1,
                  'product_name': 'Blue Pen',
                  'product_code': 'PEN-1',
                  'company': 'Acme',
                  'category': 'Pens',
                  'quantity': '2.000',
                  'pricing_mode': 'PRE_TAX',
                  'entered_unit_price': '100.00',
                  'unit_price_excl_tax': '100.00',
                  'unit_price_incl_tax': '118.00',
                  'gst_rate': '18.00',
                  'cgst_rate': '9.00',
                  'sgst_rate': '9.00',
                  'igst_rate': '0.00',
                  'discount_percent': '0.00',
                  'discount_amount': '0.00',
                  'taxable_amount': '200.00',
                  'gst_amount': '36.00',
                  'cgst_amount': '18.00',
                  'sgst_amount': '18.00',
                  'igst_amount': '0.00',
                  'line_total': '236.00',
                },
              ],
            },
            'warnings': <Map<String, dynamic>>[
              <String, dynamic>{
                'code': 'NEGATIVE_STOCK',
                'message': 'Stock will go negative for Blue Pen',
              },
            ],
          }),
        ),
      );
      final service = ApiInvoicesService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      final result = await service.createInvoice(draft: _draft, requestId: 'request-1');

      expect(httpClient.lastMethod, 'POST');
      expect(httpClient.lastPath, '/invoices');
      expect(result.invoice.id, 'inv-1');
      expect(result.invoice.invoiceNumber, '1001');
      expect(result.invoice.sellerName, 'ABC Stores');
      expect(result.invoice.grandTotal, 236);
      expect(result.invoice.items.single.productName, 'Blue Pen');
      expect(result.invoice.items.single.quantity, 2);
      expect(result.invoice.items.single.lineTotal, 236);
      expect(result.warnings.single.message, 'Stock will go negative for Blue Pen');
    });
  });
}

const _draft = InvoiceDraft(
  seller: Seller(
    id: 'seller-1',
    name: 'ABC Stores',
    address: 'Market Yard',
    phone: '9999999999',
    gstin: '27BBBBB0000B1Z5',
    state: 'Maharashtra',
    stateCode: '27',
    isActive: true,
    pendingBalance: 0,
  ),
  invoiceDate: '2026-04-20',
  placeOfSupplyStateCode: '27',
  items: <InvoiceDraftItem>[
    InvoiceDraftItem(
      product: Product(
        id: 'product-1',
        company: 'Acme',
        category: 'Pens',
        itemName: 'Blue Pen',
        itemCode: 'PEN-1',
        defaultSellingPriceExclTax: 100,
        defaultGstRate: 18,
        quantityOnHand: 5,
        lowStockThreshold: 2,
        isActive: true,
      ),
      quantity: 2,
      pricingMode: 'PRE_TAX',
      unitPrice: 100,
      gstRate: 18,
      discountPercent: 0,
    ),
  ],
);

class FakeAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login({required String username, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> me({required String accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) {
    throw UnimplementedError();
  }
}

class InMemorySessionStore implements SessionStore {
  @override
  Future<void> clearSession() async {}

  @override
  Future<StoredSession?> readSession() async {
    return const StoredSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'bearer',
    );
  }

  @override
  Future<void> writeSession(StoredSession session) async {}
}

class RecordingHttpClient implements HttpClient {
  RecordingHttpClient({required this.response});

  final HttpClientResponse response;
  String? lastMethod;
  String? lastPath;
  String? lastBody;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    lastMethod = 'POST';
    lastPath = url.path;
    return RecordingHttpRequest(
      response: response,
      onClose: (body) => lastBody = body,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingHttpRequest implements HttpClientRequest {
  RecordingHttpRequest({required this.response, required this.onClose});

  final HttpClientResponse response;
  final void Function(String body) onClose;
  final HttpHeaders headers = _FakeHttpHeaders();
  final StringBuffer _buffer = StringBuffer();

  @override
  Future<HttpClientResponse> close() async {
    onClose(_buffer.toString());
    return response;
  }

  @override
  void write(Object? object) {
    _buffer.write(object);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeHttpResponse({required this.statusCode, required String body})
      : _bodyStream = Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]);

  @override
  final int statusCode;
  final Stream<List<int>> _bodyStream;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _bodyStream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
