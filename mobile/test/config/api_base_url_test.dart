import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/config/api_base_url.dart';

void main() {
  test('android candidates prefer emulator host before localhost', () {
    final candidates = defaultCandidateApiBaseUris(isAndroid: true);

    expect(
      candidates.map((uri) => uri.toString()).toList(),
      <String>[
        'http://10.0.2.2:8010/',
        'http://10.0.2.2:8000/',
        'http://localhost:8010/',
        'http://localhost:8000/',
      ],
    );
  });

  test('non-android candidates use localhost ports', () {
    final candidates = defaultCandidateApiBaseUris(isAndroid: false);

    expect(
      candidates.map((uri) => uri.toString()).toList(),
      <String>[
        'http://localhost:8010/',
        'http://localhost:8000/',
      ],
    );
  });

  test('default base uri falls back to first platform candidate', () {
    expect(
      configuredOrDefaultApiBaseUri(isAndroid: true).toString(),
      'http://10.0.2.2:8010/',
    );
    expect(
      configuredOrDefaultApiBaseUri(isAndroid: false).toString(),
      'http://localhost:8010/',
    );
  });
}
