import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internal_billing_khata_mobile/backup/google_auth_configuration.dart';
import 'package:internal_billing_khata_mobile/backup/google_auth_gateway.dart';

void main() {
  test(
      'allows platform resource configuration when client ID define is missing',
      () {
    const configuration = GoogleAuthConfiguration(serverClientId: '');

    expect(configuration.serverClientIdOrNull, isNull);
  });

  test('accepts a configured web OAuth client ID', () {
    const configuration = GoogleAuthConfiguration(
      serverClientId: 'client.apps.googleusercontent.com',
    );

    expect(
      configuration.serverClientIdOrNull,
      'client.apps.googleusercontent.com',
    );
  });

  test('maps Android OAuth configuration failures to actionable guidance', () {
    final error = mapGoogleSignInError(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'serverClientId must be provided on Android',
      ),
    );

    expect(error.message, contains('google-services.json'));
    expect(error.message, contains('GOOGLE_DRIVE_SERVER_CLIENT_ID'));
    expect(error.message, contains('signing SHA'));
  });
}
