import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  group('Product', () {
    test('requires canonical V2 JSON fields', () {
      expect(
        () => Product.fromJson(<String, dynamic>{
          'id': 'p1',
          'company': 'Acme',
          'category': 'Pens',
          'item_name': 'Blue Pen',
          'item_code': 'PEN-1',
          'default_selling_price_excl_tax': '10',
          'default_gst_rate': '18',
          'quantity_on_hand': '5',
          'low_stock_threshold': '2',
          'is_active': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ApiProductsService', () {
    test('create payload omits unsupported is_active field', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body:
              '{"id":"p1","company_name":"Acme","category":"Pens","item_name":"Blue Pen","item_number":"PEN-1","buying_price":"8","selling_price":"10","unit":"pcs","gst_rate":"18","quantity_on_hand":"5","low_stock_threshold":"2","is_active":true}',
        ),
      );
      final service = ApiProductsService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      await service.createProduct(
        const CreateProductInput(
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-1',
          buyingPrice: 8,
          sellingPrice: 10,
          unit: 'pcs',
          gstRate: 18,
          quantityOnHand: 5,
          lowStockThreshold: 2,
        ),
      );

      expect(httpClient.lastMethod, 'POST');
      expect(httpClient.lastPath, '/products');
      expect(httpClient.lastBody, isNotNull);
      final payload = jsonDecode(httpClient.lastBody!) as Map<String, dynamic>;
      expect(payload['quantity_on_hand'], 5);
      expect(payload.containsKey('is_active'), isFalse);
      expect(payload.containsKey('company'), isFalse);
      expect(payload.containsKey('item_code'), isFalse);
      expect(payload.containsKey('default_selling_price_excl_tax'), isFalse);
      expect(payload.containsKey('default_gst_rate'), isFalse);
      expect(payload['company_name'], 'Acme');
      expect(payload['item_number'], 'PEN-1');
      expect(payload['buying_price'], 8);
      expect(payload['selling_price'], 10);
      expect(payload['unit'], 'pcs');
      expect(payload['gst_rate'], 18);
    });

    test('update payload omits forbidden quantity_on_hand and is_active fields',
        () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body:
              '{"id":"p1","company_name":"Acme","category":"Pens","item_name":"Blue Pen","item_number":"PEN-1","buying_price":"8","selling_price":"10","unit":"pcs","gst_rate":"18","quantity_on_hand":"5","low_stock_threshold":"2","is_active":true}',
        ),
      );
      final service = ApiProductsService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      await service.updateProduct(
        id: 'p1',
        input: const UpdateProductInput(
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-1',
          buyingPrice: 8,
          sellingPrice: 10,
          unit: 'pcs',
          gstRate: 18,
          lowStockThreshold: 2,
        ),
      );

      expect(httpClient.lastMethod, 'PUT');
      expect(httpClient.lastPath, '/products/p1');
      expect(httpClient.lastBody, isNotNull);
      final payload = jsonDecode(httpClient.lastBody!) as Map<String, dynamic>;
      expect(payload.containsKey('quantity_on_hand'), isFalse);
      expect(payload.containsKey('is_active'), isFalse);
      expect(payload.containsKey('company'), isFalse);
      expect(payload.containsKey('item_code'), isFalse);
      expect(payload.containsKey('default_selling_price_excl_tax'), isFalse);
      expect(payload.containsKey('default_gst_rate'), isFalse);
      expect(payload['low_stock_threshold'], 2);
    });

    test('fetch query emits canonical product filter keys only', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(statusCode: 200, body: '[]'),
      );
      final service = ApiProductsService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      await service.fetchProducts(
        filter: const ProductFilter(companyName: 'Acme', category: 'Pens'),
      );

      expect(httpClient.lastQueryParameters, isNot(contains('company')));
      expect(httpClient.lastQueryParameters['company_name'], 'Acme');
      expect(httpClient.lastQueryParameters['category'], 'Pens');
    });
  });
}

class FakeAuthService implements AuthService {
  @override
  Future<AuthSessionTokens> login(
      {required String username, required String password}) {
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
  Map<String, String> lastQueryParameters = const <String, String>{};
  String? lastBody;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    lastMethod = 'GET';
    lastPath = url.path;
    lastQueryParameters = url.queryParameters;
    return RecordingHttpRequest(
      response: response,
      onClose: (body) => lastBody = body,
    );
  }

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
  Future<HttpClientRequest> putUrl(Uri url) async {
    lastMethod = 'PUT';
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
      : _bodyStream =
            Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]);

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
