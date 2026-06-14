import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_models.dart';
import 'package:internal_billing_khata_mobile/backup/encrypted_drive_backup_orchestrator.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;

import 'backup_test_fixtures.dart';
import 'drive_backup_orchestrator_test.dart' show canonicalDatabaseDigest;
import 'fake_drive_platform.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('drive backup round-trip restore matches canonical digest', () async {
    final database = db.LocalDatabase.memory();
    addTearDown(database.close);
    await _seedFullBackupTables(database);

    final gateway = FakeDriveGateway();
    final orchestrator = EncryptedDriveBackupOrchestrator(
      database: database,
      authGateway: FakeGoogleAuthGateway(),
      secretStore: FakeBackupSecretStore(initialPassword: 'backup-password'),
      driveGatewayFactory: () async => gateway,
    );

    final beforeDigest = await canonicalDatabaseDigest(database);
    await orchestrator.runVerifiedBackup(eventType: 'manual_drive_backup');

    await database.customStatement('DELETE FROM customer_transactions');
    await database.customStatement('DELETE FROM invoice_items');
    await database.customStatement('DELETE FROM stock_movements');
    await database.customStatement('DELETE FROM products');

    final backups = await orchestrator.listBackups();
    await orchestrator.restoreFromBackup(
      fileId: backups.single.id,
      password: 'backup-password',
    );

    final afterDigest = await canonicalDatabaseDigest(database);
    expect(afterDigest, beforeDigest);
    expect(await database.select(database.localSessions).get(), isEmpty);
  });

  test('wrong restore password leaves digest unchanged', () async {
    final database = db.LocalDatabase.memory();
    addTearDown(database.close);
    await _seedFullBackupTables(database);

    final gateway = FakeDriveGateway();
    final orchestrator = EncryptedDriveBackupOrchestrator(
      database: database,
      authGateway: FakeGoogleAuthGateway(),
      secretStore: FakeBackupSecretStore(initialPassword: 'backup-password'),
      driveGatewayFactory: () async => gateway,
    );

    await orchestrator.runVerifiedBackup();
    final beforeDigest = await canonicalDatabaseDigest(database);
    final backups = await orchestrator.listBackups();

    await database.customStatement('DELETE FROM invoice_items');
    await database.customStatement('DELETE FROM stock_movements');
    await database.customStatement('DELETE FROM products');

    await expectLater(
      () => orchestrator.restoreFromBackup(
        fileId: backups.single.id,
        password: 'wrong-password',
      ),
      throwsA(isA<BackupDecryptionException>()),
    );

    final afterDigest = await canonicalDatabaseDigest(database);
    expect(afterDigest, isNot(beforeDigest));
    expect(await database.select(database.products).get(), isEmpty);
  });
}

Future<void> _seedFullBackupTables(db.LocalDatabase database) async {
  await seedRoundTripData(database);

  await database.into(database.companyProfiles).insert(
        db.CompanyProfilesCompanion.insert(
          id: 'company-0001',
          name: 'Khata Traders',
          address: '10 Market Road',
          city: 'Mumbai',
          state: 'Maharashtra',
          stateCode: '27',
          phone: const Value('9000000000'),
          email: const Value('billing@example.com'),
          bankName: const Value('Example Bank'),
          bankAccount: const Value('1234567890'),
          bankIfsc: const Value('EXAM0000001'),
          bankBranch: const Value('Main'),
          jurisdiction: const Value('Mumbai'),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );

  await database.into(database.stockMovements).insert(
        db.StockMovementsCompanion.insert(
          id: 'stock-movement-0001',
          productId: 'product-0001',
          requestId: const Value('stock-request-0001'),
          requestHash: const Value('stock-request-hash'),
          movementType: 'ADJUSTMENT',
          quantityDelta: '1.000',
          reason: const Value('Seed stock'),
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-03T00:00:00.000Z',
        ),
      );

  await database.into(database.backupSettings).insert(
        db.BackupSettingsCompanion.insert(
          id: 'local-backup-settings',
          backupDirectory: const Value('Google Drive'),
          automaticBackupsEnabled: const Value(false),
          dailyBackupTime: const Value('02:00'),
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );

  await database.into(database.backupEvents).insert(
        db.BackupEventsCompanion.insert(
          id: 'seed-event-0001',
          eventType: 'manual_export',
          status: 'success',
          createdAt: '2026-01-01T00:00:00.000Z',
        ),
      );

  await _seedLocalSession(database, id: 'session-to-clear');
}

Future<void> _seedLocalSession(
  db.LocalDatabase database, {
  required String id,
}) {
  return database.into(database.localSessions).insert(
        db.LocalSessionsCompanion.insert(
          id: id,
          localUserId: 'local-system-user',
          sessionTokenHash: 'session-hash-$id',
          refreshTokenHash: 'refresh-hash-$id',
          createdAt: '2026-01-02T00:00:00.000Z',
        ),
      );
}
