import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_auth_service.dart';

void main() {
  test('HybridOfflineException exposes message', () {
    const error = HybridOfflineException('Connect before saving invoice');
    expect(error.toString(), 'Connect before saving invoice');
  });
}
