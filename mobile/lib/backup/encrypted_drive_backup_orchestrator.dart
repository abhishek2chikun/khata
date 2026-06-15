import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../local/local_database.dart';
import 'backup_models.dart';
import 'drive_backup_service.dart';
import 'drive_platform.dart';
import 'local_backup_service.dart';
import 'local_backup_transfer_service.dart';

class DriveBackupListItem {
  const DriveBackupListItem({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
    required this.schemaVersion,
  });

  final String id;
  final String name;
  final DateTime createdTime;
  final int sizeBytes;
  final int schemaVersion;
}

typedef DriveGatewayFactory = Future<DriveGateway> Function();

class EncryptedDriveBackupOrchestrator {
  EncryptedDriveBackupOrchestrator({
    required LocalDatabase database,
    required GoogleAuthGateway authGateway,
    required DriveGatewayFactory driveGatewayFactory,
    required BackupSecretStore secretStore,
    LocalBackupService? backupService,
    DateTime Function()? clock,
  })  : _database = database,
        _authGateway = authGateway,
        _driveGatewayFactory = driveGatewayFactory,
        _secretStore = secretStore,
        _backupService =
            backupService ?? LocalBackupService(database: database),
        _clock = clock ?? DateTime.now;

  static const retentionCount = 30;

  final LocalDatabase _database;
  final GoogleAuthGateway _authGateway;
  final DriveGatewayFactory _driveGatewayFactory;
  final BackupSecretStore _secretStore;
  final LocalBackupService _backupService;
  final DateTime Function() _clock;

  Future<void> runVerifiedBackup(
      {String eventType = 'automatic_backup'}) async {
    await _ensureReadyForBackup();
    final password = (await _secretStore.readPassword())!;
    final now = _clock().toUtc();
    DriveGateway? gateway;
    String? uploadedFileId;
    var uploadVerified = false;
    try {
      gateway = await _driveGatewayFactory();
      final package = await _backupService.exportEncrypted(password: password);
      final encoded = utf8.encode(package.encode());
      final contentHash = _sha256Hex(encoded);
      final folderId = await gateway.ensureBackupFolder();
      final uploaded = await gateway.uploadBackupFile(
        folderId: folderId,
        fileName: _fileName(now),
        bytes: encoded,
        appProperties: {
          DriveGateway.khataOwnerProperty: DriveGateway.khataOwnerValue,
          'schema_version': '${LocalBackupPayload.currentSchemaVersion}',
          'compatibility_version':
              LocalBackupPayload.currentBackendCompatibilityVersion,
          'exported_at': now.toIso8601String(),
          'sha256': contentHash,
        },
      );
      uploadedFileId = uploaded.id;
      await gateway.verifyUploadedFile(
        fileId: uploaded.id,
        expectedSha256: contentHash,
      );
      uploadVerified = true;
      await _updateLastBackupAt(now);
      await _pruneOwnedBackupsBestEffort(
        gateway: gateway,
        folderId: folderId,
        at: now,
      );
      await _recordEvent(
        eventType: eventType,
        status: 'success',
        driveFileId: uploaded.id,
        at: now,
      );
    } on Object catch (error) {
      if (gateway != null && uploadedFileId != null && !uploadVerified) {
        try {
          await gateway.deleteFile(fileId: uploadedFileId);
        } on Object {
          // Preserve the original upload or verification failure for callers.
        }
      }
      await _recordEvent(
        eventType: eventType,
        status: 'failure',
        message: redactBackupFailureMessage(error),
        at: now,
      );
      rethrow;
    }
  }

  Future<List<DriveBackupListItem>> listBackups() async {
    final gateway = await _driveGatewayFactory();
    final folderId = await gateway.ensureBackupFolder();
    final files = await gateway.listOwnedBackupFiles(folderId: folderId);
    return files
        .map(
          (file) => DriveBackupListItem(
            id: file.id,
            name: file.name,
            createdTime: file.createdTime,
            sizeBytes: file.sizeBytes,
            schemaVersion: int.tryParse(
                  file.appProperties['schema_version'] ?? '',
                ) ??
                LocalBackupPayload.currentSchemaVersion,
          ),
        )
        .toList();
  }

  Future<void> restoreFromBackup({
    required String fileId,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const BackupPasswordException(
        'Backup password must contain at least 8 characters.',
      );
    }
    final now = _clock().toUtc();
    try {
      final gateway = await _driveGatewayFactory();
      final bytes = await gateway.downloadFile(fileId: fileId);
      final package = LocalBackupPackage.decode(utf8.decode(bytes));
      await _backupService.importEncrypted(
        package: package,
        password: password,
      );
      await _recordEvent(
        eventType: 'drive_restore',
        status: 'success',
        driveFileId: fileId,
        at: now,
      );
    } on Object catch (error) {
      await _recordEvent(
        eventType: 'drive_restore',
        status: 'failure',
        message: redactBackupFailureMessage(error),
        at: now,
      );
      rethrow;
    }
  }

  Future<void> _ensureReadyForBackup() async {
    if (!await _authGateway.isSignedIn() ||
        !await _authGateway.hasDriveAccess()) {
      throw const DriveBackupConfigurationException(
        'Connect a Google account with Drive access before backing up.',
      );
    }
    final password = await _secretStore.readPassword();
    if (password == null || password.length < 8) {
      throw const DriveBackupConfigurationException(
        'Set a backup password before backing up to Google Drive.',
      );
    }
  }

  Future<void> _pruneOwnedBackups({
    required DriveGateway gateway,
    required String folderId,
  }) async {
    final files = await gateway.listOwnedBackupFiles(folderId: folderId);
    if (files.length <= retentionCount) {
      return;
    }
    final extras = files.skip(retentionCount).toList();
    for (final file in extras) {
      await gateway.deleteFile(fileId: file.id);
    }
  }

  Future<void> _pruneOwnedBackupsBestEffort({
    required DriveGateway gateway,
    required String folderId,
    required DateTime at,
  }) async {
    try {
      await _pruneOwnedBackups(gateway: gateway, folderId: folderId);
    } on Object catch (error) {
      await _recordEvent(
        eventType: 'drive_retention',
        status: 'failure',
        message: redactBackupFailureMessage(error),
        at: at,
      );
    }
  }

  Future<void> _updateLastBackupAt(DateTime now) async {
    const settingsId = 'local-backup-settings';
    final existing = await (_database.select(_database.backupSettings)
          ..where((settings) => settings.id.equals(settingsId)))
        .getSingleOrNull();
    await _database.into(_database.backupSettings).insertOnConflictUpdate(
          BackupSettingsCompanion(
            id: const Value(settingsId),
            backupDirectory: Value(existing?.backupDirectory ?? 'Google Drive'),
            automaticBackupsEnabled:
                Value(existing?.automaticBackupsEnabled ?? false),
            dailyBackupTime: Value(existing?.dailyBackupTime ?? '02:00'),
            lastBackupAt: Value(now.toIso8601String()),
            updatedAt: Value(now.toIso8601String()),
          ),
        );
  }

  Future<void> _recordEvent({
    required String eventType,
    required String status,
    required DateTime at,
    String? driveFileId,
    String? message,
  }) {
    return _database.into(_database.backupEvents).insert(
          BackupEventsCompanion.insert(
            id: '$eventType-${at.microsecondsSinceEpoch}',
            eventType: eventType,
            status: status,
            filePath: Value(driveFileId),
            message: Value(message),
            createdAt: at.toIso8601String(),
          ),
        );
  }

  static String _fileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'khata-backup-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.khata';
  }

  static String _sha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}
