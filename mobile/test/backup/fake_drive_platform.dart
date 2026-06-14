import 'package:crypto/crypto.dart';
import 'package:internal_billing_khata_mobile/backup/drive_platform.dart';

class FakeDriveGateway implements DriveGateway {
  FakeDriveGateway({
    this.shouldFailVerification = false,
    this.shouldFailUpload = false,
    this.shouldFailDownload = false,
  });

  final files = <String, _StoredDriveFile>{};
  final unrelatedFiles = <String, _StoredDriveFile>{};
  bool shouldFailVerification;
  bool shouldFailUpload;
  bool shouldFailDownload;
  String? _folderId;
  var _nextId = 1;
  var ensureFolderCalls = 0;

  @override
  Future<String> ensureBackupFolder() async {
    ensureFolderCalls += 1;
    _folderId ??= 'folder-$ensureFolderCalls';
    return _folderId!;
  }

  @override
  Future<List<DriveBackupFile>> listOwnedBackupFiles({
    required String folderId,
  }) async {
    return files.values
        .where((file) => file.folderId == folderId)
        .map((file) => file.toMetadata())
        .toList()
      ..sort((a, b) => b.createdTime.compareTo(a.createdTime));
  }

  @override
  Future<DriveBackupFile> uploadBackupFile({
    required String folderId,
    required String fileName,
    required List<int> bytes,
    required Map<String, String> appProperties,
  }) async {
    if (shouldFailUpload) {
      throw const DriveTransportException('network failure');
    }
    final id = 'file-${_nextId++}';
    final sha = sha256.convert(bytes).toString();
    files[id] = _StoredDriveFile(
      id: id,
      folderId: folderId,
      name: fileName,
      bytes: List<int>.from(bytes),
      appProperties: Map<String, String>.from(appProperties),
      sha256: sha,
      createdTime: DateTime.utc(2026, 6, 14, _nextId),
    );
    return files[id]!.toMetadata();
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    if (shouldFailDownload) {
      throw const DriveTransportException('network failure');
    }
    final file = files[fileId];
    if (file == null) {
      throw const DriveTransportException('file not found');
    }
    return List<int>.from(file.bytes);
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    files.remove(fileId);
  }

  @override
  Future<void> verifyUploadedFile({
    required String fileId,
    required String expectedSha256,
  }) async {
    if (shouldFailVerification) {
      throw const DriveTransportException('upload verification failed');
    }
    final file = files[fileId];
    if (file == null || file.sha256 != expectedSha256) {
      throw const DriveTransportException('upload verification failed');
    }
  }

  void seedUnrelatedFile({
    required String folderId,
    required String name,
  }) {
    final id = 'unrelated-${_nextId++}';
    unrelatedFiles[id] = _StoredDriveFile(
      id: id,
      folderId: folderId,
      name: name,
      bytes: const [9, 9, 9],
      appProperties: const {},
      sha256: 'sha-unrelated',
      createdTime: DateTime.utc(2026, 6, 1),
    );
  }
}

class _StoredDriveFile {
  _StoredDriveFile({
    required this.id,
    required this.folderId,
    required this.name,
    required this.bytes,
    required this.appProperties,
    required this.sha256,
    required this.createdTime,
  });

  final String id;
  final String folderId;
  final String name;
  final List<int> bytes;
  final Map<String, String> appProperties;
  final String sha256;
  final DateTime createdTime;

  DriveBackupFile toMetadata() {
    return DriveBackupFile(
      id: id,
      name: name,
      createdTime: createdTime,
      sizeBytes: bytes.length,
      appProperties: appProperties,
      sha256: sha256,
    );
  }
}

class FakeGoogleAuthGateway implements GoogleAuthGateway {
  FakeGoogleAuthGateway({
    bool signedIn = true,
    this.hasAccess = true,
    this.shouldCancelSignIn = false,
    this.email = 'owner@example.com',
  }) : _signedIn = signedIn;

  bool _signedIn;
  final bool hasAccess;
  final bool shouldCancelSignIn;
  final String email;

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<String?> accountEmail() async => _signedIn ? email : null;

  @override
  Future<void> signIn() async {
    if (shouldCancelSignIn) {
      throw const DriveAuthException('sign in canceled');
    }
    _signedIn = true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }

  @override
  Future<bool> hasDriveAccess() async => _signedIn && hasAccess;
}

class FakeBackupSecretStore implements BackupSecretStore {
  FakeBackupSecretStore({String? initialPassword})
      : _password = initialPassword;

  String? _password;

  @override
  Future<void> clearPassword() async {
    _password = null;
  }

  @override
  Future<bool> hasPassword() async =>
      _password != null && _password!.isNotEmpty;

  @override
  Future<String?> readPassword() async => _password;

  @override
  Future<void> savePassword(String password) async {
    _password = password;
  }
}
