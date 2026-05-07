import 'package:drift/drift.dart';

import '../local/local_database.dart';
import 'backup_scheduler.dart';

abstract class DriveBackupService {
  Future<BackupScheduleSettings> loadSettings();

  Future<void> saveSettings(BackupScheduleSettings settings);

  Future<void> exportBackup();

  Future<void> importBackup();
}

class DriveBackupConfigurationException implements Exception {
  const DriveBackupConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'DriveBackupConfigurationException: $message';
}

class GoogleDriveBackupService implements DriveBackupService {
  const GoogleDriveBackupService();

  @override
  Future<BackupScheduleSettings> loadSettings() async {
    return const BackupScheduleSettings();
  }

  @override
  Future<void> saveSettings(BackupScheduleSettings settings) {
    throw const DriveBackupConfigurationException(
      'Google Drive backup settings require local backup configuration.',
    );
  }

  @override
  Future<void> exportBackup() {
    throw const DriveBackupConfigurationException(
      'Google Drive backup requires OAuth and Drive upload configuration.',
    );
  }

  @override
  Future<void> importBackup() {
    throw const DriveBackupConfigurationException(
      'Google Drive restore requires OAuth and Drive file selection configuration.',
    );
  }
}

class LocalDriveBackupService implements DriveBackupService {
  LocalDriveBackupService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

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
            automaticBackupsEnabled: Value(settings.automaticBackupsEnabled),
            dailyBackupTime: Value(settings.dailyBackupTime.format24Hour()),
            lastBackupAt:
                Value(settings.lastBackupAt?.toUtc().toIso8601String()),
            updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
          ),
        );
  }

  @override
  Future<void> exportBackup() {
    throw const DriveBackupConfigurationException(
      'Google Drive backup requires OAuth and Drive upload configuration.',
    );
  }

  @override
  Future<void> importBackup() {
    throw const DriveBackupConfigurationException(
      'Google Drive restore requires OAuth and Drive file selection configuration.',
    );
  }
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
  FakeDriveBackupService({BackupScheduleSettings? settings})
      : _settings = settings ?? const BackupScheduleSettings();

  BackupScheduleSettings _settings;
  int exportCount = 0;
  int importCount = 0;

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
  Future<void> exportBackup() async {
    exportCount += 1;
  }

  @override
  Future<void> importBackup() async {
    importCount += 1;
  }
}
