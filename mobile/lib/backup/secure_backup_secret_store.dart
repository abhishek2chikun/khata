import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'drive_platform.dart';

/// Stores the backup password only in platform secure storage.
class FlutterSecureBackupSecretStore implements BackupSecretStore {
  FlutterSecureBackupSecretStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearPassword() {
    return _storage.delete(key: BackupSecretStore.storageKey);
  }

  @override
  Future<bool> hasPassword() async {
    final password = await readPassword();
    return password != null && password.isNotEmpty;
  }

  @override
  Future<String?> readPassword() {
    return _storage.read(key: BackupSecretStore.storageKey);
  }

  @override
  Future<void> savePassword(String password) {
    return _storage.write(key: BackupSecretStore.storageKey, value: password);
  }
}
