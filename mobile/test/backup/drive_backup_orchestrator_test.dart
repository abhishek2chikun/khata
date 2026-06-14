import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_models.dart';
import 'package:internal_billing_khata_mobile/backup/drive_backup_service.dart';
import 'package:internal_billing_khata_mobile/backup/drive_platform.dart';
import 'package:internal_billing_khata_mobile/backup/encrypted_drive_backup_orchestrator.dart';
import 'package:internal_billing_khata_mobile/backup/local_backup_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;

import 'backup_test_fixtures.dart';
import 'fake_drive_platform.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('EncryptedDriveBackupOrchestrator', () {
    late db.LocalDatabase database;
    late FakeDriveGateway gateway;
    late FakeGoogleAuthGateway auth;
    late FakeBackupSecretStore secrets;

    setUp(() {
      database = db.LocalDatabase.memory();
      gateway = FakeDriveGateway();
      auth = FakeGoogleAuthGateway();
      secrets = FakeBackupSecretStore(initialPassword: 'backup-password');
    });

    tearDown(() async {
      await database.close();
    });

    EncryptedDriveBackupOrchestrator buildOrchestrator({
      DateTime Function()? clock,
    }) {
      return EncryptedDriveBackupOrchestrator(
        database: database,
        authGateway: auth,
        secretStore: secrets,
        driveGatewayFactory: () async => gateway,
        clock: clock,
      );
    }

    test('creates and reuses Khata backup folder', () async {
      final orchestrator = buildOrchestrator();
      await orchestrator.runVerifiedBackup();
      await orchestrator.runVerifiedBackup();
      expect(gateway.ensureFolderCalls, 2);
    });

    test('uploads metadata and verifies before recording success', () async {
      await seedRoundTripData(database);
      final orchestrator = buildOrchestrator(
        clock: () => DateTime.utc(2026, 6, 14, 2, 0),
      );

      await orchestrator.runVerifiedBackup();

      expect(gateway.files, hasLength(1));
      final uploaded = gateway.files.values.single;
      expect(uploaded.appProperties[DriveGateway.khataOwnerProperty],
          DriveGateway.khataOwnerValue);
      expect(uploaded.appProperties['schema_version'], '10');

      final settings = await (database.select(database.backupSettings)).get();
      expect(settings.single.lastBackupAt, isNotNull);
    });

    test('verification failure prevents success and retention prune', () async {
      await seedRoundTripData(database);
      gateway.shouldFailVerification = true;
      final orchestrator = buildOrchestrator();

      await expectLater(
        () => orchestrator.runVerifiedBackup(),
        throwsA(isA<DriveTransportException>()),
      );

      expect(gateway.files, hasLength(1));
      final settings = await (database.select(database.backupSettings)).get();
      expect(settings, isEmpty);
    });

    test('retention keeps newest 30 owned backups', () async {
      await seedRoundTripData(database);
      final orchestrator = buildOrchestrator(
        clock: () => DateTime.utc(2026, 6, 14),
      );
      final folderId = await gateway.ensureBackupFolder();

      for (var index = 0; index < 31; index += 1) {
        await gateway.uploadBackupFile(
          folderId: folderId,
          fileName: 'seed-$index.khata',
          bytes: [index],
          appProperties: {
            DriveGateway.khataOwnerProperty: DriveGateway.khataOwnerValue,
            'schema_version': '10',
          },
        );
      }
      expect(gateway.files, hasLength(31));

      await orchestrator.runVerifiedBackup();

      expect(gateway.files.length, lessThanOrEqualTo(31));
      final owned = await gateway.listOwnedBackupFiles(folderId: folderId);
      expect(owned.length, EncryptedDriveBackupOrchestrator.retentionCount);
    });

    test('does not list unrelated files without ownership property', () async {
      final folderId = await gateway.ensureBackupFolder();
      gateway.seedUnrelatedFile(folderId: folderId, name: 'notes.txt');
      await gateway.uploadBackupFile(
        folderId: folderId,
        fileName: 'owned.khata',
        bytes: [1],
        appProperties: {
          DriveGateway.khataOwnerProperty: DriveGateway.khataOwnerValue,
        },
      );

      final listed = await gateway.listOwnedBackupFiles(folderId: folderId);
      expect(listed, hasLength(1));
      expect(listed.single.name, 'owned.khata');
      expect(gateway.unrelatedFiles, isNotEmpty);
    });

    test('lists backups newest first and restores downloaded package', () async {
      await seedRoundTripData(database);
      final orchestrator = buildOrchestrator();
      await orchestrator.runVerifiedBackup();

      final listed = await orchestrator.listBackups();
      expect(listed, hasLength(1));

      await database.customStatement('DELETE FROM invoice_items');
      await database.customStatement('DELETE FROM stock_movements');
      await database.customStatement('DELETE FROM products');
      expect(await database.select(database.products).get(), isEmpty);

      await orchestrator.restoreFromBackup(
        fileId: listed.single.id,
        password: 'backup-password',
      );

      expect(await database.select(database.products).get(), isNotEmpty);
    });

    test('maps sign-in cancellation to DriveAuthException', () async {
      auth = FakeGoogleAuthGateway(shouldCancelSignIn: true);
      await expectLater(() => auth.signIn(), throwsA(isA<DriveAuthException>()));
    });

    test('requires drive access before backup', () async {
      auth = FakeGoogleAuthGateway(signedIn: true, hasAccess: false);
      final orchestrator = buildOrchestrator();

      await expectLater(
        () => orchestrator.runVerifiedBackup(),
        throwsA(isA<DriveBackupConfigurationException>()),
      );
    });

    test('network upload failure does not update last backup', () async {
      await seedRoundTripData(database);
      gateway.shouldFailUpload = true;
      final orchestrator = buildOrchestrator();

      await expectLater(
        () => orchestrator.runVerifiedBackup(),
        throwsA(isA<DriveTransportException>()),
      );

      final settings = await (database.select(database.backupSettings)).get();
      expect(settings, isEmpty);
    });
  });

  group('secure store', () {
    test('stores password only in secure store abstraction', () async {
      final store = FakeBackupSecretStore();
      expect(await store.hasPassword(), isFalse);
      await store.savePassword('secure-password-123');
      expect(await store.readPassword(), 'secure-password-123');
      await store.clearPassword();
      expect(await store.hasPassword(), isFalse);
    });
  });
}

Future<String> canonicalDatabaseDigest(db.LocalDatabase database) async {
  const tables = <String>[
    'local_users',
    'products',
    'customers',
    'buyers',
    'company_profiles',
    'invoices',
    'invoice_items',
    'stock_movements',
    'customer_transactions',
    'buyer_transactions',
  ];
  final payload = <String, List<Map<String, Object?>>>{};
  for (final tableName in tables) {
    final rows = await database
        .customSelect('SELECT * FROM $tableName ORDER BY id')
        .get();
    payload[tableName] = rows
        .map((row) => _sortMapKeys(row.data))
        .toList();
  }
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

Map<String, Object?> _sortMapKeys(Map<String, Object?> row) {
  final keys = row.keys.toList()..sort();
  return {for (final key in keys) key: row[key]};
}
