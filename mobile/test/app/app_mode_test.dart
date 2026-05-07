import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('parseDataMode defaults to api', () {
    expect(parseDataMode(''), DataMode.api);
  });

  test('parseDataMode accepts local', () {
    expect(parseDataMode('local'), DataMode.local);
  });

  test('parseDataMode rejects unknown values', () {
    expect(() => parseDataMode('server'), throwsArgumentError);
  });
}
