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
    final header = _validatePackage(package);
    final secretKey = await _deriveKey(
      password: password,
      salt: header.salt,
      iterations: package.kdfIterations,
    );
    try {
      return await AesGcm.with256bits().decrypt(
        SecretBox(
          header.ciphertext,
          nonce: header.nonce,
          mac: Mac(header.mac),
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

  _ValidatedPackageHeader _validatePackage(LocalBackupPackage package) {
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
    if (package.kdfIterations != LocalBackupPackage.defaultKdfIterations) {
      throw const BackupDecryptionException(
        'Unsupported backup KDF iteration count',
      );
    }

    late final List<int> salt;
    late final List<int> nonce;
    late final List<int> mac;
    late final List<int> ciphertext;
    try {
      salt = base64Decode(package.salt);
      nonce = base64Decode(package.nonce);
      mac = base64Decode(package.mac);
      ciphertext = base64Decode(package.payloadCiphertext);
    } on FormatException catch (_) {
      throw const BackupDecryptionException('Backup package is malformed');
    }
    if (salt.length != 16 ||
        nonce.length != 12 ||
        mac.length != 16 ||
        ciphertext.isEmpty) {
      throw const BackupDecryptionException('Backup package is malformed');
    }
    return _ValidatedPackageHeader(
      salt: salt,
      nonce: nonce,
      mac: mac,
      ciphertext: ciphertext,
    );
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

class _ValidatedPackageHeader {
  const _ValidatedPackageHeader({
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.ciphertext,
  });

  final List<int> salt;
  final List<int> nonce;
  final List<int> mac;
  final List<int> ciphertext;
}
