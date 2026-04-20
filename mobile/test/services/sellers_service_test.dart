import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';
import 'package:internal_billing_khata_mobile/auth/session_store.dart';
import 'package:internal_billing_khata_mobile/services/api_client.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  group('ApiSellersService', () {
    test('fetch sellers does not send unsupported search query parameter', () async {
      final httpClient = RecordingHttpClient(
        response: FakeHttpResponse(
          statusCode: 200,
          body: '[{"id":"seller-1","name":"ABC Stores","address":"Market Yard","phone":null,"gstin":null,"state":null,"state_code":null,"is_active":true,"pending_balance":"500.00"}]',
        ),
      );
      final service = ApiSellersService(
        apiClient: ApiClient(
          baseUri: Uri.parse('http://localhost:8000/'),
          httpClient: httpClient,
          authService: FakeAuthService(),
          sessionStore: InMemorySessionStore(),
        ),
      );

      await service.fetchSellers(search: 'abc');

      expect(httpClient.lastMethod, 'GET');
      expect(httpClient.lastPath, '/sellers');
      expect(httpClient.lastQueryParameters, isEmpty);
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
  Map<String, String> lastQueryParameters = <String, String>{};

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    lastMethod = 'GET';
    lastPath = url.path;
    lastQueryParameters = url.queryParameters;
    return RecordingHttpRequest(response: response);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingHttpRequest implements HttpClientRequest {
  RecordingHttpRequest({required this.response});

  final HttpClientResponse response;
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return response;
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
