import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/local_backup_service.dart';
import 'package:internal_billing_khata_mobile/backup/local_backup_transfer_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

void main() {
  late LocalDatabase database;
  late Directory outputDirectory;

  setUp(() {
    database = LocalDatabase.memory();
    outputDirectory = Directory.systemTemp.createTempSync('khata_transfer_');
  });

  tearDown(() async {
    await database.close();
    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }
  });

  test('export writes, shares, records, and timestamps encrypted backup',
      () async {
    await _seedUser(database, username: 'owner');
    String? sharedPath;
    final service = LocalBackupTransferService(
      database: database,
      outputDirectory: () async => outputDirectory.path,
      shareFile: (path) async => sharedPath = path,
      pickFile: () async => null,
      clock: () => DateTime.utc(2026, 6, 13, 12, 34, 56),
    );

    final path = await service.exportBackup(password: 'secure-pass');

    expect(path, endsWith('khata-backup-20260613-123456.khata'));
    expect(sharedPath, path);
    final contents = await File(path).readAsString();
    expect(contents, isNot(contains('owner')));
    expect(contents, contains('payload_ciphertext'));
    final events = await database.select(database.backupEvents).get();
    expect(events.single.eventType, 'manual_export');
    expect(events.single.status, 'success');
    final settings = await database.select(database.backupSettings).get();
    expect(settings.single.lastBackupAt, '2026-06-13T12:34:56.000Z');
  });

  test('import restores encrypted payload and records success', () async {
    final source = LocalDatabase.memory();
    addTearDown(source.close);
    await _seedUser(source, username: 'restored-owner');
    final package = await LocalBackupService(database: source)
        .exportEncrypted(password: 'secure-pass');
    await _seedUser(database, username: 'replace-me');

    final service = LocalBackupTransferService(
      database: database,
      outputDirectory: () async => outputDirectory.path,
      shareFile: (_) async {},
      pickFile: () async => package.encode().codeUnits,
      clock: () => DateTime.utc(2026, 6, 13, 13),
    );

    final result = await service.importBackup(password: 'secure-pass');

    expect(result, BackupImportResult.imported);
    final users = await database.select(database.localUsers).get();
    expect(users.single.username, 'restored-owner');
    final events = await database.select(database.backupEvents).get();
    expect(events.single.eventType, 'manual_import');
    expect(events.single.status, 'success');
  });

  test('wrong import password preserves current data and records failure',
      () async {
    final source = LocalDatabase.memory();
    addTearDown(source.close);
    await _seedUser(source, username: 'restored-owner');
    final package = await LocalBackupService(database: source)
        .exportEncrypted(password: 'correct-pass');
    await _seedUser(database, username: 'current-owner');

    final service = LocalBackupTransferService(
      database: database,
      outputDirectory: () async => outputDirectory.path,
      shareFile: (_) async {},
      pickFile: () async => package.encode().codeUnits,
    );

    await expectLater(
      service.importBackup(password: 'wrong-pass'),
      throwsA(anything),
    );

    final users = await database.select(database.localUsers).get();
    expect(users.single.username, 'current-owner');
    final events = await database.select(database.backupEvents).get();
    expect(events.single.status, 'failure');
  });

  test('canceled import changes no data and records no event', () async {
    await _seedUser(database, username: 'current-owner');
    final service = LocalBackupTransferService(
      database: database,
      outputDirectory: () async => outputDirectory.path,
      shareFile: (_) async {},
      pickFile: () async => null,
    );

    final result = await service.importBackup(password: 'secure-pass');

    expect(result, BackupImportResult.canceled);
    expect((await database.select(database.localUsers).get()).single.username,
        'current-owner');
    expect(await database.select(database.backupEvents).get(), isEmpty);
  });

  test('short password is rejected before export or import', () async {
    final service = LocalBackupTransferService(
      database: database,
      outputDirectory: () async => outputDirectory.path,
      shareFile: (_) async {},
      pickFile: () async => null,
    );

    await expectLater(
      service.exportBackup(password: 'short'),
      throwsA(isA<BackupPasswordException>()),
    );
    await expectLater(
      service.importBackup(password: 'short'),
      throwsA(isA<BackupPasswordException>()),
    );
  });
}

Future<void> _seedUser(LocalDatabase database, {required String username}) {
  return database.into(database.localUsers).insert(
        LocalUsersCompanion.insert(
          id: 'user-$username',
          username: username,
          passwordHash: 'hash',
          displayName: const Value('Owner'),
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: '2026-06-13T00:00:00.000Z',
          updatedAt: '2026-06-13T00:00:00.000Z',
        ),
      );
}
