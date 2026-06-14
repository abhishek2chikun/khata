import 'package:drift/drift.dart';

import '../local/local_database.dart';
import 'backup_scheduler.dart';
import 'drive_platform.dart';
import 'encrypted_drive_backup_orchestrator.dart';
import 'google_auth_gateway.dart';
import 'local_backup_transfer_service.dart';

abstract class DriveBackupService {
  Future<BackupScheduleSettings> loadSettings();

  Future<void> saveSettings(BackupScheduleSettings settings);

  Future<bool> isGoogleAccountConnected();

  Future<String?> googleAccountEmail();

  Future<void> connectGoogleAccount();

  Future<void> disconnectGoogleAccount();

  Future<bool> hasBackupPassword();

  Future<void> saveBackupPassword(String password);

  Future<void> removeBackupPassword();

  Future<void> backupToDriveNow();

  Future<List<DriveBackupListItem>> listDriveBackups();

  Future<void> restoreFromDrive({
    required String fileId,
    required String password,
  });

  Future<String?> lastFailureMessage();
}

class DriveBackupConfigurationException implements Exception {
  const DriveBackupConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'DriveBackupConfigurationException: $message';
}

class EncryptedDriveBackupService implements DriveBackupService {
  EncryptedDriveBackupService({
    required LocalDatabase database,
    required GoogleAuthGateway authGateway,
    required EncryptedDriveBackupOrchestrator orchestrator,
    required BackupScheduleAdapter scheduleAdapter,
    required BackupSecretStore secretStore,
  })  : _database = database,
        _authGateway = authGateway,
        _orchestrator = orchestrator,
        _scheduleAdapter = scheduleAdapter,
        _secretStore = secretStore;

  final LocalDatabase _database;
  final GoogleAuthGateway _authGateway;
  final EncryptedDriveBackupOrchestrator _orchestrator;
  final BackupScheduleAdapter _scheduleAdapter;
  final BackupSecretStore _secretStore;

  static const _settingsId = 'local-backup-settings';

  @override
  Future<BackupScheduleSettings> loadSettings() async {
    final row = await (_database.select(_database.backupSettings)
          ..where((settings) => settings.id.equals(_settingsId)))
        .getSingleOrNull();
    if (row == null) {
      return const BackupScheduleSettings();
    }
    return BackupScheduleSettings(
      automaticBackupsEnabled: row.automaticBackupsEnabled,
      dailyBackupTime: BackupTimeOfDay.parse(row.dailyBackupTime),
      lastBackupAt: row.lastBackupAt == null
          ? null
          : DateTime.tryParse(row.lastBackupAt!),
    );
  }

  @override
  Future<void> saveSettings(BackupScheduleSettings settings) async {
    await _database.into(_database.backupSettings).insertOnConflictUpdate(
          BackupSettingsCompanion(
            id: const Value(_settingsId),
            backupDirectory: const Value('Google Drive'),
            automaticBackupsEnabled: Value(settings.automaticBackupsEnabled),
            dailyBackupTime: Value(settings.dailyBackupTime.format24Hour()),
            lastBackupAt:
                Value(settings.lastBackupAt?.toUtc().toIso8601String()),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
    if (settings.automaticBackupsEnabled) {
      await _scheduleAdapter.registerDailyBackup(settings.dailyBackupTime);
      return;
    }
    await _scheduleAdapter.cancelDailyBackup();
  }

  @override
  Future<bool> isGoogleAccountConnected() => _authGateway.isSignedIn();

  @override
  Future<String?> googleAccountEmail() => _authGateway.accountEmail();

  @override
  Future<void> connectGoogleAccount() => _authGateway.signIn();

  @override
  Future<void> disconnectGoogleAccount() => _authGateway.signOut();

  @override
  Future<bool> hasBackupPassword() => _secretStore.hasPassword();

  @override
  Future<void> saveBackupPassword(String password) async {
    if (password.length < 8) {
      throw const BackupPasswordException(
        'Backup password must contain at least 8 characters.',
      );
    }
    await _secretStore.savePassword(password);
  }

  @override
  Future<void> removeBackupPassword() => _secretStore.clearPassword();

  @override
  Future<void> backupToDriveNow() {
    return _orchestrator.runVerifiedBackup(eventType: 'manual_drive_backup');
  }

  @override
  Future<List<DriveBackupListItem>> listDriveBackups() {
    return _orchestrator.listBackups();
  }

  @override
  Future<void> restoreFromDrive({
    required String fileId,
    required String password,
  }) {
    return _orchestrator.restoreFromBackup(fileId: fileId, password: password);
  }

  @override
  Future<String?> lastFailureMessage() async {
    final rows = await (_database.select(_database.backupEvents)
          ..where(
            (event) =>
                event.status.equals('failure') &
                (event.eventType.equals('automatic_backup') |
                    event.eventType.equals('manual_drive_backup') |
                    event.eventType.equals('drive_restore')),
          )
          ..orderBy([
            (event) => OrderingTerm.desc(event.createdAt),
          ])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.single.message;
  }
}

class GoogleDriveBackupService implements DriveBackupService {
  const GoogleDriveBackupService();

  Future<T> _unsupported<T>() {
    throw const DriveBackupConfigurationException(
      'Google Drive backup requires local mode configuration.',
    );
  }

  @override
  Future<BackupScheduleSettings> loadSettings() async {
    return const BackupScheduleSettings();
  }

  @override
  Future<void> saveSettings(BackupScheduleSettings settings) =>
      _unsupported<void>();

  @override
  Future<bool> isGoogleAccountConnected() => _unsupported<bool>();

  @override
  Future<String?> googleAccountEmail() => _unsupported<String?>();

  @override
  Future<void> connectGoogleAccount() => _unsupported<void>();

  @override
  Future<void> disconnectGoogleAccount() => _unsupported<void>();

  @override
  Future<bool> hasBackupPassword() => _unsupported<bool>();

  @override
  Future<void> saveBackupPassword(String password) => _unsupported<void>();

  @override
  Future<void> removeBackupPassword() => _unsupported<void>();

  @override
  Future<void> backupToDriveNow() => _unsupported<void>();

  @override
  Future<List<DriveBackupListItem>> listDriveBackups() => _unsupported();

  @override
  Future<void> restoreFromDrive({
    required String fileId,
    required String password,
  }) =>
      _unsupported<void>();

  @override
  Future<String?> lastFailureMessage() => _unsupported<String?>();
}

class LocalBackupEventRecorder implements BackupEventRecorder {
  LocalBackupEventRecorder({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

  @override
  Future<void> recordBackupFailure(String message) async {
    await _database.into(_database.backupEvents).insert(
          BackupEventsCompanion.insert(
            id: 'backup-failure-${DateTime.now().microsecondsSinceEpoch}',
            eventType: 'automatic_backup',
            status: 'failure',
            message: Value(message),
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
  }
}

class FakeDriveBackupService implements DriveBackupService {
  FakeDriveBackupService({
    BackupScheduleSettings? settings,
    this.connected = false,
    this.hasPassword = false,
    this.accountEmail,
    List<DriveBackupListItem>? backups,
  })  : _settings = settings ?? const BackupScheduleSettings(),
        _backups = backups ?? const <DriveBackupListItem>[];

  BackupScheduleSettings _settings;
  final List<DriveBackupListItem> _backups;
  bool connected;
  bool hasPassword;
  String? accountEmail;
  int backupNowCount = 0;
  int restoreCount = 0;
  String? lastRestoreFileId;
  String? lastSavedPassword;
  String? storedFailureMessage;

  set settings(BackupScheduleSettings value) {
    _settings = value;
  }

  @override
  Future<BackupScheduleSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(BackupScheduleSettings settings) async {
    _settings = settings;
  }

  @override
  Future<bool> isGoogleAccountConnected() async => connected;

  @override
  Future<String?> googleAccountEmail() async => accountEmail;

  @override
  Future<void> connectGoogleAccount() async {
    connected = true;
    accountEmail ??= 'owner@example.com';
  }

  @override
  Future<void> disconnectGoogleAccount() async {
    connected = false;
    accountEmail = null;
  }

  @override
  Future<bool> hasBackupPassword() async => hasPassword;

  @override
  Future<void> saveBackupPassword(String password) async {
    lastSavedPassword = password;
    hasPassword = true;
  }

  @override
  Future<void> removeBackupPassword() async {
    hasPassword = false;
    lastSavedPassword = null;
  }

  @override
  Future<void> backupToDriveNow() async {
    backupNowCount += 1;
  }

  @override
  Future<List<DriveBackupListItem>> listDriveBackups() async {
    return List<DriveBackupListItem>.from(_backups);
  }

  @override
  Future<void> restoreFromDrive({
    required String fileId,
    required String password,
  }) async {
    restoreCount += 1;
    lastRestoreFileId = fileId;
    lastSavedPassword = password;
  }

  @override
  Future<String?> lastFailureMessage() async => storedFailureMessage;
}
