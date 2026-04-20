import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/auth/auth_service.dart';

void main() {
  test('login surfaces backend nested error envelope message', () async {
    final httpClient = FakeHttpClient(
      response: FakeHttpClientResponse(
        statusCode: 401,
        body: jsonEncode(<String, dynamic>{
          'error': <String, dynamic>{
            'code': 'invalid_credentials',
            'message': 'Username or password is incorrect',
          },
        }),
      ),
    );
    final service = HttpAuthService(
      baseUri: Uri.parse('http://localhost:8000/'),
      httpClient: httpClient,
    );

    expect(
      () => service.login(username: 'owner', password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Username or password is incorrect',
        ),
      ),
    );
  });

  test('me accepts null display name from backend payload', () async {
    final httpClient = FakeHttpClient(
      response: FakeHttpClientResponse(
        statusCode: 200,
        body: jsonEncode(<String, dynamic>{
          'id': 'user-1',
          'username': 'owner',
          'display_name': null,
        }),
      ),
    );
    final service = HttpAuthService(
      baseUri: Uri.parse('http://localhost:8000/'),
      httpClient: httpClient,
    );

    final user = await service.me(accessToken: 'access-token');

    expect(user.id, 'user-1');
    expect(user.username, 'owner');
    expect(user.displayName, isNull);
  });
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient({required this.response});

  final HttpClientResponse response;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return FakeHttpClientRequest(response: response);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return FakeHttpClientRequest(response: response);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientRequest implements HttpClientRequest {
  FakeHttpClientRequest({required this.response});

  final HttpClientResponse response;
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  void write(Object? object) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeHttpClientResponse({required this.statusCode, required String body})
      : _bytes = Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]);

  final int statusCode;
  final Stream<List<int>> _bytes;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _bytes.listen(
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
