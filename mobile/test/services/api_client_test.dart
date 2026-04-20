import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('refreshes token once after 401 and retries successfully', () async {
      final httpClient = SequenceHttpClient(
        responses: <FakeHttpResponse>[
          FakeHttpResponse(statusCode: 401, body: '{"error":{"code":"unauthorized","message":"Unauthorized"}}'),
          FakeHttpResponse(
            statusCode: 200,
            body: '{"access_token":"fresh-access","refresh_token":"fresh-refresh","token_type":"bearer"}',
          ),
          FakeHttpResponse(statusCode: 200, body: '[{"id":"p1","item_name":"Blue Pen"}]'),
        ],
      );
      final authService = HttpAuthService(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
      );
      final sessionStore = InMemorySessionStore(
        const StoredSession(
          accessToken: 'stale-access',
          refreshToken: 'refresh-1',
          tokenType: 'bearer',
        ),
      );
      final apiClient = ApiClient(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
        authService: authService,
        sessionStore: sessionStore,
      );

      final response = await apiClient.get('/products');

      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), isA<List<dynamic>>());
      expect(sessionStore.session?.accessToken, 'fresh-access');
      expect(httpClient.authorizationHeaders, <String?>[
        'Bearer stale-access',
        null,
        'Bearer fresh-access',
      ]);
    });

    test('fails cleanly when refresh request is unauthorized', () async {
      var authFailureCount = 0;
      final httpClient = SequenceHttpClient(
        responses: <FakeHttpResponse>[
          FakeHttpResponse(statusCode: 401, body: '{"error":{"code":"unauthorized","message":"Unauthorized"}}'),
          FakeHttpResponse(
            statusCode: 401,
            body: '{"error":{"code":"refresh_expired","message":"Session expired"}}',
          ),
        ],
      );
      final authService = HttpAuthService(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
      );
      final sessionStore = InMemorySessionStore(
        const StoredSession(
          accessToken: 'stale-access',
          refreshToken: 'stale-refresh',
          tokenType: 'bearer',
        ),
      );
      final apiClient = ApiClient(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
        authService: authService,
        sessionStore: sessionStore,
        onAuthorizationFailed: () async {
          authFailureCount++;
        },
      );

      await expectLater(
        apiClient.get('/products'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.code, 'code', 'refresh_expired')
              .having((error) => error.message, 'message', 'Session expired')
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
      expect(authFailureCount, 1);
    });

    test('fails cleanly when retried request is still unauthorized', () async {
      var authFailureCount = 0;
      final httpClient = SequenceHttpClient(
        responses: <FakeHttpResponse>[
          FakeHttpResponse(statusCode: 401, body: '{"error":{"code":"unauthorized","message":"Unauthorized"}}'),
          FakeHttpResponse(
            statusCode: 200,
            body: '{"access_token":"fresh-access","refresh_token":"fresh-refresh","token_type":"bearer"}',
          ),
          FakeHttpResponse(
            statusCode: 401,
            body: '{"error":{"code":"unauthorized","message":"Still unauthorized"}}',
          ),
        ],
      );
      final authService = HttpAuthService(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
      );
      final sessionStore = InMemorySessionStore(
        const StoredSession(
          accessToken: 'stale-access',
          refreshToken: 'refresh-1',
          tokenType: 'bearer',
        ),
      );
      final apiClient = ApiClient(
        baseUri: Uri.parse('http://localhost:8000/'),
        httpClient: httpClient,
        authService: authService,
        sessionStore: sessionStore,
        onAuthorizationFailed: () async {
          authFailureCount++;
        },
      );

      await expectLater(
        apiClient.get('/products'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.code, 'code', 'unauthorized')
              .having((error) => error.message, 'message', 'Still unauthorized')
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
      expect(sessionStore.session?.accessToken, 'fresh-access');
      expect(authFailureCount, 1);
      expect(httpClient.authorizationHeaders, <String?>[
        'Bearer stale-access',
        null,
        'Bearer fresh-access',
      ]);
    });
  });
}

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore(this.session);

  StoredSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession session) async {
    this.session = session;
  }
}

class SequenceHttpClient implements HttpClient {
  SequenceHttpClient({required List<FakeHttpResponse> responses})
      : _responses = List<FakeHttpResponse>.from(responses);

  final List<FakeHttpResponse> _responses;
  final List<String?> authorizationHeaders = <String?>[];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return SequenceHttpRequest(
      response: _responses.removeAt(0),
      onClose: (headers) {
        authorizationHeaders.add(headers[HttpHeaders.authorizationHeader]);
      },
    );
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return SequenceHttpRequest(
      response: _responses.removeAt(0),
      onClose: (headers) {
        authorizationHeaders.add(headers[HttpHeaders.authorizationHeader]);
      },
    );
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    return SequenceHttpRequest(
      response: _responses.removeAt(0),
      onClose: (headers) {
        authorizationHeaders.add(headers[HttpHeaders.authorizationHeader]);
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SequenceHttpRequest implements HttpClientRequest {
  SequenceHttpRequest({required this.response, required this.onClose});

  final FakeHttpResponse response;
  final void Function(Map<String, String> headers) onClose;
  final _TestHttpHeaders headers = _TestHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    onClose(headers.values);
    return response;
  }

  @override
  void write(Object? object) {}

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

class _TestHttpHeaders implements HttpHeaders {
  final Map<String, String> values = <String, String>{};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
