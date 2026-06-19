import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('parseDataMode defaults to hybrid', () {
    expect(parseDataMode(''), DataMode.hybrid);
  });

  test('parseDataMode accepts hybrid', () {
    expect(parseDataMode('hybrid'), DataMode.hybrid);
  });

  test('parseDataMode rejects api', () {
    expect(() => parseDataMode('api'), throwsArgumentError);
  });

  test('parseDataMode rejects local', () {
    expect(() => parseDataMode('local'), throwsArgumentError);
  });

  test('parseDataMode trims and normalizes hybrid case', () {
    expect(parseDataMode(' HYBRID '), DataMode.hybrid);
  });

  test('parseDataMode rejects unknown values', () {
    expect(() => parseDataMode('server'), throwsArgumentError);
  });

  test('resolveDataMode defaults to hybrid', () {
    expect(resolveDataMode(), DataMode.hybrid);
  });

  test('hybrid is the only compiled runtime mode', () {
    expect(DataMode.values, const <DataMode>[DataMode.hybrid]);
  });
}
