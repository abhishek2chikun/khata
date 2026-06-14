import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local/local_database.dart';
import 'backup_models.dart';
import 'local_backup_service.dart';

enum BackupImportResult { imported, canceled }

abstract class BackupTransferService {
  Future<String> exportBackup({required String password});

  Future<BackupImportResult> importBackup({required String password});
}

typedef BackupFileSharer = Future<void> Function(String path);
typedef BackupFilePicker = Future<List<int>?> Function();
typedef BackupOutputDirectory = Future<String> Function();

class LocalBackupTransferService implements BackupTransferService {
  LocalBackupTransferService({
    required LocalDatabase database,
    LocalBackupService? backupService,
    BackupFileSharer? shareFile,
    BackupFilePicker? pickFile,
    BackupOutputDirectory? outputDirectory,
    DateTime Function()? clock,
  })  : _database = database,
        _backupService =
            backupService ?? LocalBackupService(database: database),
        _shareFile = shareFile ?? _shareBackupFile,
        _pickFile = pickFile ?? _pickBackupFile,
        _outputDirectory = outputDirectory ??
            (() => getTemporaryDirectory().then((directory) => directory.path)),
        _clock = clock ?? DateTime.now;

  final LocalDatabase _database;
  final LocalBackupService _backupService;
  final BackupFileSharer _shareFile;
  final BackupFilePicker _pickFile;
  final BackupOutputDirectory _outputDirectory;
  final DateTime Function() _clock;

  @override
  Future<String> exportBackup({required String password}) async {
    _validatePassword(password);
    final now = _clock().toUtc();
    try {
      final package = await _backupService.exportEncrypted(password: password);
      final directory = await _outputDirectory();
      final file = File('$directory/${_fileName(now)}');
      await file.writeAsString(package.encode(), flush: true);
      await _shareFile(file.path);
      await _recordEvent(
        eventType: 'manual_export',
        status: 'success',
        filePath: file.path,
        at: now,
      );
      await _updateLastBackup(now);
      return file.path;
    } on Object catch (error) {
      await _recordEvent(
        eventType: 'manual_export',
        status: 'failure',
        message: error.toString(),
        at: now,
      );
      rethrow;
    }
  }

  @override
  Future<BackupImportResult> importBackup({required String password}) async {
    _validatePassword(password);
    final bytes = await _pickFile();
    if (bytes == null) {
      return BackupImportResult.canceled;
    }

    final now = _clock().toUtc();
    try {
      final package = LocalBackupPackage.decode(utf8.decode(bytes));
      await _backupService.importEncrypted(
        package: package,
        password: password,
      );
      await _recordEvent(
        eventType: 'manual_import',
        status: 'success',
        at: now,
      );
      return BackupImportResult.imported;
    } on Object catch (error) {
      await _recordEvent(
        eventType: 'manual_import',
        status: 'failure',
        message: error.toString(),
        at: now,
      );
      rethrow;
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const BackupPasswordException(
        'Backup password must contain at least 8 characters.',
      );
    }
  }

  Future<void> _updateLastBackup(DateTime now) async {
    const settingsId = 'local-backup-settings';
    final existing = await (_database.select(_database.backupSettings)
          ..where((settings) => settings.id.equals(settingsId)))
        .getSingleOrNull();
    await _database.into(_database.backupSettings).insertOnConflictUpdate(
          BackupSettingsCompanion.insert(
            id: settingsId,
            backupDirectory:
                Value(existing?.backupDirectory ?? 'Android share sheet'),
            automaticBackupsEnabled:
                Value(existing?.automaticBackupsEnabled ?? false),
            dailyBackupTime: Value(existing?.dailyBackupTime ?? '02:00'),
            lastBackupAt: Value(now.toIso8601String()),
            updatedAt: now.toIso8601String(),
          ),
        );
  }

  Future<void> _recordEvent({
    required String eventType,
    required String status,
    required DateTime at,
    String? filePath,
    String? message,
  }) {
    return _database.into(_database.backupEvents).insert(
          BackupEventsCompanion.insert(
            id: '$eventType-${at.microsecondsSinceEpoch}',
            eventType: eventType,
            status: status,
            filePath: Value(filePath),
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

  static Future<void> _shareBackupFile(String path) async {
    await Share.shareXFiles(
      <XFile>[XFile(path, mimeType: 'application/octet-stream')],
      subject: 'Khata encrypted backup',
      text: 'Encrypted Khata local-data backup. Keep the password separately.',
    );
  }

  static Future<List<int>?> _pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['khata'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final picked = result.files.single;
    if (picked.bytes != null) {
      return picked.bytes;
    }
    final path = picked.path;
    return path == null ? null : File(path).readAsBytes();
  }
}

class BackupPasswordException implements Exception {
  const BackupPasswordException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FakeBackupTransferService implements BackupTransferService {
  int exportCount = 0;
  int importCount = 0;
  BackupImportResult importResult = BackupImportResult.imported;
  String? lastPassword;

  @override
  Future<String> exportBackup({required String password}) async {
    exportCount += 1;
    lastPassword = password;
    return '/tmp/backup.khata';
  }

  @override
  Future<BackupImportResult> importBackup({required String password}) async {
    importCount += 1;
    lastPassword = password;
    return importResult;
  }
}
