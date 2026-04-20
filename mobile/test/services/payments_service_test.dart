import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  group('ApiPaymentsService', () {
    test('record payment payload includes request_id', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(statusCode: 201, body: '{}'),
      );
      final service = ApiPaymentsService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      await service.recordPayment(
        const RecordPaymentInput(
          requestId: '11111111-1111-4111-8111-111111111111',
          sellerId: 'seller-1',
          amount: 125.5,
          occurredOn: '2026-04-20',
          notes: 'Cash',
        ),
      );

      expect(httpClient.lastMethod, 'POST');
      expect(httpClient.lastPath, '/payments');
      final payload = jsonDecode(httpClient.lastBody!) as Map<String, dynamic>;
      expect(payload['request_id'], '11111111-1111-4111-8111-111111111111');
      expect(payload['seller_id'], 'seller-1');
      expect(payload['amount'], 125.5);
      expect(payload['occurred_on'], '2026-04-20');
      expect(payload['notes'], 'Cash');
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
