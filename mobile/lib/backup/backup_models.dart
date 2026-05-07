import 'dart:convert';

class LocalBackupPackage {
  const LocalBackupPackage({
    required this.version,
    required this.cipher,
    required this.kdf,
    required this.kdfIterations,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.payloadCiphertext,
  });

  static const currentVersion = 1;
  static const currentCipher = 'aes-256-gcm';
  static const currentKdf = 'pbkdf2-hmac-sha256';
  static const defaultKdfIterations = 210000;

  final int version;
  final String cipher;
  final String kdf;
  final int kdfIterations;
  final String salt;
  final String nonce;
  final String mac;
  final String payloadCiphertext;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'cipher': cipher,
      'kdf': kdf,
      'kdf_iterations': kdfIterations,
      'salt': salt,
      'nonce': nonce,
      'mac': mac,
      'payload_ciphertext': payloadCiphertext,
    };
  }

  factory LocalBackupPackage.fromJson(Map<String, Object?> json) {
    return LocalBackupPackage(
      version: json['version'] as int,
      cipher: json['cipher'] as String,
      kdf: json['kdf'] as String,
      kdfIterations: json['kdf_iterations'] as int,
      salt: json['salt'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      payloadCiphertext: json['payload_ciphertext'] as String,
    );
  }

  String encode() => jsonEncode(toJson());

  static LocalBackupPackage decode(String value) {
    return LocalBackupPackage.fromJson(
      jsonDecode(value) as Map<String, Object?>,
    );
  }
}

class LocalBackupPayload {
  const LocalBackupPayload({
    required this.schemaVersion,
    required this.backendCompatibilityVersion,
    required this.exportedAt,
    required this.tables,
  });

  static const currentSchemaVersion = 1;
  static const currentBackendCompatibilityVersion = 'local-v1';

  final int schemaVersion;
  final String backendCompatibilityVersion;
  final String exportedAt;
  final Map<String, List<Map<String, Object?>>> tables;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': schemaVersion,
      'backend_compatibility_version': backendCompatibilityVersion,
      'exported_at': exportedAt,
      'tables': tables,
    };
  }

  factory LocalBackupPayload.fromJson(Map<String, Object?> json) {
    final tablePayloads = json['tables'] as Map<String, Object?>;
    return LocalBackupPayload(
      schemaVersion: json['schema_version'] as int,
      backendCompatibilityVersion:
          json['backend_compatibility_version'] as String,
      exportedAt: json['exported_at'] as String,
      tables: tablePayloads.map(
        (tableName, rows) => MapEntry(
          tableName,
          (rows as List<Object?>)
              .map((row) => Map<String, Object?>.from(row as Map))
              .toList(),
        ),
      ),
    );
  }

  List<int> encode() => utf8.encode(jsonEncode(toJson()));

  static LocalBackupPayload decode(List<int> bytes) {
    return LocalBackupPayload.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, Object?>,
    );
  }
}

class UnsupportedBackupVersionException implements Exception {
  const UnsupportedBackupVersionException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedBackupVersionException: $message';
}

class BackupDecryptionException implements Exception {
  const BackupDecryptionException(this.message);

  final String message;

  @override
  String toString() => 'BackupDecryptionException: $message';
}
