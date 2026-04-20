import 'dart:convert';
import 'dart:io';

import '../auth/auth_service.dart';
import '../auth/session_store.dart';
import '../models/api_error.dart';

class ApiResponse {
  const ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class ApiClient {
  ApiClient({
    required Uri baseUri,
    required HttpClient httpClient,
    required AuthService authService,
    required SessionStore sessionStore,
    this.onAuthorizationFailed,
  })  : _baseUri = baseUri,
        _httpClient = httpClient,
        _authService = authService,
        _sessionStore = sessionStore;

  final Uri _baseUri;
  final HttpClient _httpClient;
  final AuthService _authService;
  final SessionStore _sessionStore;
  final Future<void> Function()? onAuthorizationFailed;

  Future<ApiResponse> get(String path, {Map<String, String?>? queryParameters}) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) {
    return _send(method: 'POST', path: path, body: body);
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) {
    return _send(method: 'PUT', path: path, body: body);
  }

  Future<ApiResponse> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String?>? queryParameters,
    bool allowRefresh = true,
  }) async {
    final session = await _sessionStore.readSession();
    final request = await _openRequest(
      method: method,
      path: path,
      accessToken: session?.accessToken,
      queryParameters: queryParameters,
    );

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 401 && allowRefresh && session != null) {
      await _refreshSession(session.refreshToken);
      return _send(
        method: method,
        path: path,
        body: body,
        queryParameters: queryParameters,
        allowRefresh: false,
      );
    }

    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && !allowRefresh) {
        await onAuthorizationFailed?.call();
      }
      throw _toApiError(responseBody, response.statusCode);
    }

    return ApiResponse(statusCode: response.statusCode, body: responseBody);
  }

  Future<void> _refreshSession(String refreshToken) async {
    try {
      final refreshed = await _authService.refresh(refreshToken: refreshToken);
      await _sessionStore.writeSession(
        StoredSession(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          tokenType: refreshed.tokenType,
        ),
      );
    } on AuthException catch (error) {
      if (error.statusCode == 401) {
        await onAuthorizationFailed?.call();
      }
      throw ApiError(
        code: error.code,
        message: error.message,
        statusCode: error.statusCode,
      );
    } on Object {
      throw const ApiError(message: 'Unable to refresh session');
    }
  }

  Future<HttpClientRequest> _openRequest({
    required String method,
    required String path,
    String? accessToken,
    Map<String, String?>? queryParameters,
  }) async {
    final resolvedUri = _resolve(path, queryParameters: queryParameters);
    late final HttpClientRequest request;
    switch (method) {
      case 'GET':
        request = await _httpClient.getUrl(resolvedUri);
      case 'POST':
        request = await _httpClient.postUrl(resolvedUri);
      case 'PUT':
        request = await _httpClient.putUrl(resolvedUri);
      default:
        throw ArgumentError('Unsupported method $method');
    }

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (method != 'GET') {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    }
    return request;
  }

  ApiError _toApiError(String body, int statusCode) {
    if (body.isEmpty) {
      return ApiError(
        message: 'Request failed',
        statusCode: statusCode,
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          return ApiError(
            code: error['code'] as String?,
            message: error['message'] as String? ?? 'Request failed',
            statusCode: statusCode,
          );
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return ApiError(message: message, statusCode: statusCode);
        }
      }
    } on FormatException {
      return ApiError(message: body, statusCode: statusCode);
    }

    return ApiError(message: 'Request failed', statusCode: statusCode);
  }

  Uri _resolve(String path, {Map<String, String?>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(normalizedPath);
    final filteredQuery = <String, String>{
      for (final entry in (queryParameters ?? const <String, String?>{}).entries)
        if (entry.value != null && entry.value!.isNotEmpty) entry.key: entry.value!,
    };
    if (filteredQuery.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: filteredQuery);
  }
}
