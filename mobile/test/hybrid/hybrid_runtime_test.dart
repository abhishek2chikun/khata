import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/app/app_mode.dart';

void main() {
  test('hybrid is the default runtime mode when DATA_MODE is unset', () {
    expect(parseDataMode(''), DataMode.hybrid);
  });

  test('legacy api/local DATA_MODE values are not production runtime options',
      () {
    expect(() => parseDataMode('api'), throwsArgumentError);
    expect(() => parseDataMode('local'), throwsArgumentError);
  });
}
