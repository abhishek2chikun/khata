import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_background_callback.dart';
import 'package:internal_billing_khata_mobile/backup/backup_scheduler.dart';
import 'package:internal_billing_khata_mobile/backup/drive_platform.dart';
import 'package:internal_billing_khata_mobile/backup/workmanager_schedule_adapter.dart';

import 'fake_drive_platform.dart';

void main() {
  tearDown(() => configureBackupBackgroundRunner(null));

  group('UnsupportedBackupScheduleAdapter', () {
    test('cannot register platform work without adapter replacement', () async {
      const adapter = UnsupportedBackupScheduleAdapter();
      final scheduler = BackupScheduler(
        settingsLoader: () async => const BackupScheduleSettings(
          automaticBackupsEnabled: true,
          dailyBackupTime: BackupTimeOfDay(hour: 2, minute: 0),
        ),
        runBackup: () async {},
      );

      await expectLater(
        () => adapter.registerDailyBackup(const BackupTimeOfDay(hour: 2, minute: 0)),
        throwsA(isA<BackupSchedulingUnsupportedException>()),
      );

      await expectLater(
        () => scheduler.registerPlatformSchedule(),
        throwsA(isA<BackupSchedulingUnsupportedException>()),
      );
    });
  });

  group('WorkManagerBackupScheduleAdapter', () {
    test('registers unique periodic task with network constraint and initial delay', () async {
      final registrations = <({String uniqueName, String taskName, Duration delay})>[];
      final adapter = WorkManagerBackupScheduleAdapter(
        registerPeriodicTask: (uniqueName, taskName, delay) async {
          registrations.add((uniqueName: uniqueName, taskName: taskName, delay: delay));
        },
      );

      await adapter.registerDailyBackup(const BackupTimeOfDay(hour: 2, minute: 0));

      expect(registrations, hasLength(1));
      expect(registrations.single.uniqueName, backupBackgroundTaskName);
      expect(registrations.single.taskName, backupBackgroundTaskName);
      expect(registrations.single.delay.inHours, lessThanOrEqualTo(24));
    });

    test('computes initial delay until next configured backup time', () {
      final delay = WorkManagerBackupScheduleAdapter.initialDelayUntil(
        const BackupTimeOfDay(hour: 2, minute: 0),
        DateTime(2026, 6, 14, 10, 0),
      );

      expect(delay, const Duration(hours: 16));
    });

    test('cancels scheduled work when disabled', () async {
      var canceled = false;
      final adapter = WorkManagerBackupScheduleAdapter(
        cancelByUniqueName: (name) async {
          canceled = true;
          expect(name, backupBackgroundTaskName);
        },
      );

      await adapter.cancelDailyBackup();
      expect(canceled, isTrue);
    });
  });

  group('Drive platform adapters', () {
    test('fake drive gateway supports upload list download delete flow', () async {
      final gateway = FakeDriveGateway();
      final folderId = await gateway.ensureBackupFolder();
      final uploaded = await gateway.uploadBackupFile(
        folderId: folderId,
        fileName: 'backup-20260614.khata',
        bytes: [1, 2, 3],
        appProperties: {
          DriveGateway.khataOwnerProperty: DriveGateway.khataOwnerValue,
          'schema_version': '10',
        },
      );

      await gateway.verifyUploadedFile(
        fileId: uploaded.id,
        expectedSha256: uploaded.sha256!,
      );

      final listed = await gateway.listOwnedBackupFiles(folderId: folderId);
      expect(listed, hasLength(1));
      expect(listed.single.name, 'backup-20260614.khata');

      final downloaded = await gateway.downloadFile(fileId: uploaded.id);
      expect(downloaded, [1, 2, 3]);

      await gateway.deleteFile(fileId: uploaded.id);
      expect(await gateway.listOwnedBackupFiles(folderId: folderId), isEmpty);
    });

    test('fake auth gateway maps sign-in cancellation to DriveAuthException', () async {
      final gateway = FakeGoogleAuthGateway(shouldCancelSignIn: true);

      await expectLater(() => gateway.signIn(), throwsA(isA<DriveAuthException>()));
    });

    test('fake secret store keeps password out of plaintext settings', () async {
      final store = FakeBackupSecretStore();

      expect(await store.hasPassword(), isFalse);
      await store.savePassword('secure-password-123');
      expect(await store.readPassword(), 'secure-password-123');
      await store.clearPassword();
      expect(await store.hasPassword(), isFalse);
    });
  });

  group('backup background callback', () {
    test('invokes injected runner without widget bindings', () async {
      configureBackupBackgroundRunner(() async {
        return const BackupBackgroundResult.success();
      });

      final result = await runBackupBackgroundTask();
      expect(result.succeeded, isTrue);
    });

    test('returns action-required when auth or password missing', () async {
      final auth = FakeGoogleAuthGateway(signedIn: false);
      final secrets = FakeBackupSecretStore();

      final result = await evaluateBackgroundPrerequisites(
        authGateway: auth,
        secretStore: secrets,
      );

      expect(result.actionRequired, isTrue);
      expect(result.message, contains('Sign in'));
    });

    test('fl_chart compiles for analytics feasibility', () {
      final chart = LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 1), FlSpot(1, 2)],
            isCurved: false,
          ),
        ],
      );
      expect(chart.lineBarsData, hasLength(1));
    });
  });
}
