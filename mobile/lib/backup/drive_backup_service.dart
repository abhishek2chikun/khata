import 'backup_scheduler.dart';

abstract class DriveBackupService {
  Future<BackupScheduleSettings> loadSettings();

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
  Future<void> exportBackup() async {
    exportCount += 1;
  }

  @override
  Future<void> importBackup() async {
    importCount += 1;
  }
}
