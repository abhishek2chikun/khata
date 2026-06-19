import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  test('maps invalid credentials to friendly message', () {
    expect(
      mapGotrueAuthError(
        supabase.AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      ),
      'Invalid email or password.',
    );
  });

  test('HybridOfflineException exposes message', () {
    const error = HybridOfflineException('Connect before saving invoice');
    expect(error.toString(), 'Connect before saving invoice');
  });
}
