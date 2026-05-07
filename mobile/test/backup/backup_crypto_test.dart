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

  test('rejects unsupported kdf iteration counts before decrypting', () async {
    final crypto = BackupCrypto.forTesting(
      saltBytes: List<int>.filled(16, 5),
      nonceBytes: List<int>.filled(12, 6),
    );
    final package = await crypto.encrypt(
      payloadBytes: utf8.encode('{"schema_version":1}'),
      password: 'right-password',
    );

    await expectLater(
      () => crypto.decrypt(
        package: _copyPackage(package, kdfIterations: 0),
        password: 'right-password',
      ),
      throwsA(isA<BackupDecryptionException>()),
    );
    await expectLater(
      () => crypto.decrypt(
        package: _copyPackage(
          package,
          kdfIterations: LocalBackupPackage.defaultKdfIterations + 1,
        ),
        password: 'right-password',
      ),
      throwsA(isA<BackupDecryptionException>()),
    );
  });

  test('rejects malformed salt nonce and mac sizes before decrypting',
      () async {
    final crypto = BackupCrypto.forTesting(
      saltBytes: List<int>.filled(16, 7),
      nonceBytes: List<int>.filled(12, 8),
    );
    final package = await crypto.encrypt(
      payloadBytes: utf8.encode('{"schema_version":1}'),
      password: 'right-password',
    );

    for (final malformed in <LocalBackupPackage>[
      _copyPackage(package, salt: base64Encode(List<int>.filled(15, 1))),
      _copyPackage(package, nonce: base64Encode(List<int>.filled(11, 1))),
      _copyPackage(package, mac: base64Encode(List<int>.filled(15, 1))),
      _copyPackage(package, payloadCiphertext: ''),
    ]) {
      await expectLater(
        () => crypto.decrypt(package: malformed, password: 'right-password'),
        throwsA(isA<BackupDecryptionException>()),
      );
    }
  });

  test('rejects tampered ciphertext and mac authentication tags', () async {
    final crypto = BackupCrypto.forTesting(
      saltBytes: List<int>.filled(16, 9),
      nonceBytes: List<int>.filled(12, 10),
    );
    final package = await crypto.encrypt(
      payloadBytes: utf8.encode('{"schema_version":1}'),
      password: 'right-password',
    );

    await expectLater(
      () => crypto.decrypt(
        package: _copyPackage(
          package,
          payloadCiphertext: _tamperBase64(package.payloadCiphertext),
        ),
        password: 'right-password',
      ),
      throwsA(isA<BackupDecryptionException>()),
    );
    await expectLater(
      () => crypto.decrypt(
        package: _copyPackage(package, mac: _tamperBase64(package.mac)),
        password: 'right-password',
      ),
      throwsA(isA<BackupDecryptionException>()),
    );
  });
}

LocalBackupPackage _copyPackage(
  LocalBackupPackage package, {
  int? kdfIterations,
  String? salt,
  String? nonce,
  String? mac,
  String? payloadCiphertext,
}) {
  return LocalBackupPackage(
    version: package.version,
    cipher: package.cipher,
    kdf: package.kdf,
    kdfIterations: kdfIterations ?? package.kdfIterations,
    salt: salt ?? package.salt,
    nonce: nonce ?? package.nonce,
    mac: mac ?? package.mac,
    payloadCiphertext: payloadCiphertext ?? package.payloadCiphertext,
  );
}

String _tamperBase64(String value) {
  final bytes = base64Decode(value);
  bytes[0] = bytes[0] ^ 1;
  return base64Encode(bytes);
}
