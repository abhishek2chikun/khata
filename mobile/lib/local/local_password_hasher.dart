import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class LocalPasswordHash {
  const LocalPasswordHash({
    required this.salt,
    required this.hash,
    required this.version,
  });

  final String salt;
  final String hash;
  final int version;
}

class LocalPasswordHasher {
  static const currentVersion = 1;
  static const _rounds = 12000;

  LocalPasswordHash hashPassword(String password) {
    final salt = _generateSalt();
    return LocalPasswordHash(
      salt: salt,
      hash: _hash(password: password, salt: salt),
      version: currentVersion,
    );
  }

  bool verify({
    required String password,
    required String salt,
    required String passwordHash,
    required int version,
  }) {
    if (version != currentVersion) {
      return false;
    }
    return _hash(password: password, salt: salt) == passwordHash;
  }

  String hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash({required String password, required String salt}) {
    List<int> bytes = utf8.encode('$salt:$password');
    for (var round = 0; round < _rounds; round += 1) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64UrlEncode(bytes);
  }
}
