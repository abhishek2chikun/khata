import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  group('ApiProductsService', () {
    test('create payload omits unsupported is_active field', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body: '{"id":"p1","company":"Acme","category":"Pens","item_name":"Blue Pen","item_code":"PEN-1","default_selling_price_excl_tax":10,"default_gst_rate":18,"quantity_on_hand":5,"low_stock_threshold":2,"is_active":true}',
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
          company: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemCode: 'PEN-1',
          defaultSellingPriceExclTax: 10,
          defaultGstRate: 18,
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
    });

    test('update payload omits forbidden quantity_on_hand and is_active fields', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body: '{"id":"p1","company":"Acme","category":"Pens","item_name":"Blue Pen","item_code":"PEN-1","default_selling_price_excl_tax":10,"default_gst_rate":18,"quantity_on_hand":5,"low_stock_threshold":2,"is_active":true}',
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
          company: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemCode: 'PEN-1',
          defaultSellingPriceExclTax: 10,
          defaultGstRate: 18,
          lowStockThreshold: 2,
        ),
      );

      expect(httpClient.lastMethod, 'PUT');
      expect(httpClient.lastPath, '/products/p1');
      expect(httpClient.lastBody, isNotNull);
      final payload = jsonDecode(httpClient.lastBody!) as Map<String, dynamic>;
      expect(payload.containsKey('quantity_on_hand'), isFalse);
      expect(payload.containsKey('is_active'), isFalse);
      expect(payload['low_stock_threshold'], 2);
    });
  });
}

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
      : _bodyStream = Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]);

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
