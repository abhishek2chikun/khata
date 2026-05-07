import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'backup_models.dart';

class BackupCrypto {
  BackupCrypto({Random? random})
      : _fixedSaltBytes = null,
        _fixedNonceBytes = null,
        _random = random ?? Random.secure();

  BackupCrypto.forTesting({
    required List<int> saltBytes,
    required List<int> nonceBytes,
  })  : _fixedSaltBytes = List<int>.unmodifiable(saltBytes),
        _fixedNonceBytes = List<int>.unmodifiable(nonceBytes),
        _random = Random(0);

  final Random _random;
  final List<int>? _fixedSaltBytes;
  final List<int>? _fixedNonceBytes;

  Future<LocalBackupPackage> encrypt({
    required List<int> payloadBytes,
    required String password,
  }) async {
    final salt = _fixedSaltBytes ?? _randomBytes(16);
    final nonce = _fixedNonceBytes ?? _randomBytes(12);
    final secretKey = await _deriveKey(
      password: password,
      salt: salt,
      iterations: LocalBackupPackage.defaultKdfIterations,
    );
    final secretBox = await AesGcm.with256bits().encrypt(
      payloadBytes,
      secretKey: secretKey,
      nonce: nonce,
    );
    return LocalBackupPackage(
      version: LocalBackupPackage.currentVersion,
      cipher: LocalBackupPackage.currentCipher,
      kdf: LocalBackupPackage.currentKdf,
      kdfIterations: LocalBackupPackage.defaultKdfIterations,
      salt: base64Encode(salt),
      nonce: base64Encode(secretBox.nonce),
      mac: base64Encode(secretBox.mac.bytes),
      payloadCiphertext: base64Encode(secretBox.cipherText),
    );
  }

  Future<List<int>> decrypt({
    required LocalBackupPackage package,
    required String password,
  }) async {
    _validatePackage(package);
    final salt = base64Decode(package.salt);
    final nonce = base64Decode(package.nonce);
    final secretKey = await _deriveKey(
      password: password,
      salt: salt,
      iterations: package.kdfIterations,
    );
    try {
      return await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(package.payloadCiphertext),
          nonce: nonce,
          mac: Mac(base64Decode(package.mac)),
        ),
        secretKey: secretKey,
      );
    } on SecretBoxAuthenticationError catch (_) {
      throw const BackupDecryptionException(
        'Backup password is incorrect or payload is corrupted',
      );
    } on FormatException catch (_) {
      throw const BackupDecryptionException('Backup package is malformed');
    }
  }

  void _validatePackage(LocalBackupPackage package) {
    if (package.version != LocalBackupPackage.currentVersion) {
      throw UnsupportedBackupVersionException(
        'Unsupported backup package version ${package.version}',
      );
    }
    if (package.cipher != LocalBackupPackage.currentCipher ||
        package.kdf != LocalBackupPackage.currentKdf) {
      throw const UnsupportedBackupVersionException(
        'Unsupported backup encryption settings',
      );
    }
  }

  Future<SecretKey> _deriveKey({
    required String password,
    required List<int> salt,
    required int iterations,
  }) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
