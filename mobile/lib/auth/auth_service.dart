import 'dart:convert';
import 'dart:io';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class AuthSessionTokens {
  const AuthSessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  factory AuthSessionTokens.fromJson(Map<String, dynamic> json) {
    return AuthSessionTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String username;
  final String? displayName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
      return AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
      );
    }
}

abstract class AuthService {
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  });

  Future<AuthSessionTokens> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<AuthUser> me({required String accessToken});
}

class HttpAuthService implements AuthService {
  HttpAuthService({required Uri baseUri, HttpClient? httpClient})
      : _baseUri = baseUri,
        _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  @override
  Future<AuthSessionTokens> login({
    required String username,
    required String password,
  }) async {
    final json = await _postJson(
      '/auth/login',
      body: <String, dynamic>{
        'username': username,
        'password': password,
      },
    );
    return AuthSessionTokens.fromJson(json);
  }

  @override
  Future<AuthUser> me({required String accessToken}) async {
    final json = await _getJson(
      '/auth/me',
      headers: <String, String>{
        'authorization': 'Bearer $accessToken',
      },
    );
    return AuthUser.fromJson(json);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _postJson(
      '/auth/logout',
      body: <String, dynamic>{'refresh_token': refreshToken},
      allowEmptyResponse: true,
    );
  }

  @override
  Future<AuthSessionTokens> refresh({required String refreshToken}) async {
    final json = await _postJson(
      '/auth/refresh',
      body: <String, dynamic>{'refresh_token': refreshToken},
    );
    return AuthSessionTokens.fromJson(json);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final request = await _httpClient.getUrl(_resolve(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    headers?.forEach(request.headers.set);
    final response = await request.close();
    return _readJsonResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
    bool allowEmptyResponse = false,
  }) async {
    final request = await _httpClient.postUrl(_resolve(path));
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode(body));
    final response = await request.close();
    return _readJsonResponse(response, allowEmptyResponse: allowEmptyResponse);
  }

  Future<Map<String, dynamic>> _readJsonResponse(
    HttpClientResponse response, {
    bool allowEmptyResponse = false,
  }) async {
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 400) {
      final parsedError = _extractError(body);
      throw AuthException(
        parsedError.message,
        statusCode: response.statusCode,
        code: parsedError.code,
      );
    }

    if (body.isEmpty) {
      if (allowEmptyResponse) {
        return const <String, dynamic>{};
      }
      throw AuthException('Empty response from authentication service');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected response from authentication service');
    }
    return decoded;
  }

  _ParsedAuthError _extractError(String body) {
    if (body.isEmpty) {
      return const _ParsedAuthError(message: 'Authentication request failed');
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return _ParsedAuthError(message: detail);
        }
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final nestedMessage = error['message'];
          if (nestedMessage is String && nestedMessage.isNotEmpty) {
            return _ParsedAuthError(
              message: nestedMessage,
              code: error['code'] as String?,
            );
          }
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return _ParsedAuthError(message: message);
        }
      }
    } on FormatException {
      return _ParsedAuthError(message: body);
    }

    return const _ParsedAuthError(message: 'Authentication request failed');
  }

  Uri _resolve(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.resolve(normalizedPath);
  }
}

class _ParsedAuthError {
  const _ParsedAuthError({required this.message, this.code});

  final String message;
  final String? code;
}
