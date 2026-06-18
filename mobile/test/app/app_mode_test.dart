import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('parseDataMode defaults to hybrid', () {
    expect(parseDataMode(''), DataMode.hybrid);
  });

  test('parseDataMode accepts hybrid', () {
    expect(parseDataMode('hybrid'), DataMode.hybrid);
  });

  test('parseDataMode accepts api', () {
    expect(parseDataMode('api'), DataMode.api);
  });

  test('parseDataMode accepts local', () {
    expect(parseDataMode('local'), DataMode.local);
  });

  test('parseDataMode trims and normalizes case', () {
    expect(parseDataMode(' LOCAL '), DataMode.local);
  });

  test('parseDataMode rejects unknown values', () {
    expect(() => parseDataMode('server'), throwsArgumentError);
  });

  test('resolveDataMode honors compile-time DATA_MODE override', () {
    expect(resolveDataMode(), DataMode.local);
  });
}
