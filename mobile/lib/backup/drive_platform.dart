// Repository-owned abstractions for Google Drive backup transport.

class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
    required this.appProperties,
    this.sha256,
  });

  final String id;
  final String name;
  final DateTime createdTime;
  final int sizeBytes;
  final Map<String, String> appProperties;
  final String? sha256;
}

class DriveAuthException implements Exception {
  const DriveAuthException(this.message);

  final String message;

  @override
  String toString() => 'DriveAuthException: $message';
}

class DriveTransportException implements Exception {
  const DriveTransportException(this.message);

  final String message;

  @override
  String toString() => 'DriveTransportException: $message';
}

/// Minimum Drive file scope for app-created backups in a visible folder.
abstract class GoogleAuthGateway {
  static const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  static const driveScopes = <String>[driveFileScope];

  Future<bool> isSignedIn();

  Future<void> signIn();

  Future<void> signOut();

  /// Returns true when an authenticated client can be created for Drive v3.
  Future<bool> hasDriveAccess();

  Future<String?> accountEmail();
}

abstract class DriveGateway {
  static const khataFolderName = 'Khata Backups';
  static const khataOwnerProperty = 'khata_owner';
  static const khataOwnerValue = 'khata_app';

  Future<String> ensureBackupFolder();

  Future<List<DriveBackupFile>> listOwnedBackupFiles({required String folderId});

  Future<DriveBackupFile> uploadBackupFile({
    required String folderId,
    required String fileName,
    required List<int> bytes,
    required Map<String, String> appProperties,
  });

  Future<List<int>> downloadFile({required String fileId});

  Future<void> deleteFile({required String fileId});

  Future<void> verifyUploadedFile({
    required String fileId,
    required String expectedSha256,
  });
}

abstract class BackupSecretStore {
  static const storageKey = 'khata_backup_password';

  Future<String?> readPassword();

  Future<void> savePassword(String password);

  Future<void> clearPassword();

  Future<bool> hasPassword();
}
