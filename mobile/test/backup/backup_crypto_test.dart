import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_crypto.dart';
import 'package:internal_billing_khata_mobile/backup/backup_models.dart';

void main() {
  test('encrypts backup payload without exposing plaintext and decrypts it',
      () async {
    final crypto = BackupCrypto.forTesting(
      saltBytes: List<int>.filled(16, 1),
      nonceBytes: List<int>.filled(12, 2),
    );
    final payload = utf8.encode(jsonEncode(<String, Object?>{
      'schema_version': 1,
      'backend_compatibility_version': 'local-v1',
      'tables': <String, Object?>{
        'products': <Object?>[
          <String, Object?>{'id': 'product-uuid', 'quantity_on_hand': '1.50'},
        ],
      },
    }));

    final package = await crypto.encrypt(
      payloadBytes: payload,
      password: 'correct horse battery staple',
    );

    expect(package.version, LocalBackupPackage.currentVersion);
    expect(package.cipher, 'aes-256-gcm');
    expect(package.kdf, 'pbkdf2-hmac-sha256');
    expect(package.payloadCiphertext, isNot(contains('product-uuid')));
    expect(package.payloadCiphertext, isNot(contains('1.50')));

    final decrypted = await crypto.decrypt(
      package: package,
      password: 'correct horse battery staple',
    );

    expect(utf8.decode(decrypted), utf8.decode(payload));
  });

  test('rejects wrong passwords for authenticated backup packages', () async {
    final crypto = BackupCrypto.forTesting(
      saltBytes: List<int>.filled(16, 3),
      nonceBytes: List<int>.filled(12, 4),
    );
    final package = await crypto.encrypt(
      payloadBytes: utf8.encode('{"schema_version":1}'),
      password: 'right-password',
    );

    await expectLater(
      () => crypto.decrypt(package: package, password: 'wrong-password'),
      throwsA(isA<BackupDecryptionException>()),
    );
  });
}
