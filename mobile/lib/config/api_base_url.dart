import 'dart:convert';
import 'dart:io';

const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

Uri configuredOrDefaultApiBaseUri({bool? isAndroid}) {
  if (_configuredApiBaseUrl.trim().isNotEmpty) {
    return _normalizeBaseUri(_configuredApiBaseUrl);
  }

  return defaultCandidateApiBaseUris(
    isAndroid: isAndroid ?? Platform.isAndroid,
  ).first;
}

List<Uri> defaultCandidateApiBaseUris({required bool isAndroid}) {
  final rawCandidates = <String>[
    if (isAndroid) 'http://10.0.2.2:8010/',
    if (isAndroid) 'http://10.0.2.2:8000/',
    'http://localhost:8010/',
    'http://localhost:8000/',
  ];

  return rawCandidates.map(_normalizeBaseUri).toList(growable: false);
}

Future<Uri> resolveApiBaseUri({
  HttpClient? httpClient,
  bool? isAndroid,
}) async {
  if (_configuredApiBaseUrl.trim().isNotEmpty) {
    return _normalizeBaseUri(_configuredApiBaseUrl);
  }

  final client = httpClient ?? HttpClient();
  final shouldCloseClient = httpClient == null;
  client.connectionTimeout = const Duration(milliseconds: 1200);

  try {
    for (final candidate in defaultCandidateApiBaseUris(
      isAndroid: isAndroid ?? Platform.isAndroid,
    )) {
      final isHealthy = await _isHealthy(client, candidate);
      if (isHealthy) {
        return candidate;
      }
    }
  } finally {
    if (shouldCloseClient) {
      client.close(force: true);
    }
  }

  return configuredOrDefaultApiBaseUri(isAndroid: isAndroid);
}

Future<bool> _isHealthy(HttpClient client, Uri baseUri) async {
  try {
    final request = await client.getUrl(baseUri.resolve('health'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      return false;
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> && decoded['status'] == 'ok';
  } on Object {
    return false;
  }
}

Uri _normalizeBaseUri(String rawUrl) {
  final uri = Uri.parse(rawUrl.trim());
  final normalizedPath = uri.path.isEmpty ? '/' : uri.path;
  return uri.replace(
      path: normalizedPath.endsWith('/') ? normalizedPath : '$normalizedPath/');
}
