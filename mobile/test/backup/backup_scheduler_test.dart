import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_scheduler.dart';

void main() {
  test('defaults automatic backup time to 02:00', () {
    const settings = BackupScheduleSettings();

    expect(settings.dailyBackupTime, const BackupTimeOfDay(hour: 2, minute: 0));
  });

  test('computes next due backup before and after configured time', () {
    const settings = BackupScheduleSettings(
      dailyBackupTime: BackupTimeOfDay(hour: 0, minute: 0),
    );

    expect(
      BackupScheduler.nextDueBackup(
        now: DateTime(2026, 5, 8, 23, 30),
        settings: settings,
      ),
      DateTime(2026, 5, 9),
    );
    expect(
      BackupScheduler.nextDueBackup(
        now: DateTime(2026, 5, 8, 0, 30),
        settings: settings,
      ),
      DateTime(2026, 5, 9),
    );
  });

  test('reports backup due when last backup predates todays scheduled time',
      () {
    final settings = BackupScheduleSettings(
      automaticBackupsEnabled: true,
      dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
      lastBackupAt: DateTime(2026, 5, 7, 23, 55),
    );

    expect(
      BackupScheduler.isBackupDue(
        now: DateTime(2026, 5, 8, 0, 1),
        settings: settings,
      ),
      isTrue,
    );
  });

  test('does not report backup due before midnight scheduled time', () {
    final settings = BackupScheduleSettings(
      automaticBackupsEnabled: true,
      dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
      lastBackupAt: DateTime(2026, 5, 7, 0, 5),
    );

    expect(
      BackupScheduler.isBackupDue(
        now: DateTime(2026, 5, 7, 23, 59),
        settings: settings,
      ),
      isFalse,
    );
  });

  test('reports missed backup after midnight on next app launch', () {
    final settings = BackupScheduleSettings(
      automaticBackupsEnabled: true,
      dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
      lastBackupAt: DateTime(2026, 5, 6, 23, 50),
    );

    expect(
      BackupScheduler.missedBackupDueAt(
        now: DateTime(2026, 5, 8, 9),
        settings: settings,
      ),
      DateTime(2026, 5, 8),
    );
  });

  test('runs catch-up backup only when a backup is due', () async {
    var runs = 0;
    final scheduler = BackupScheduler(
      settingsLoader: () async => BackupScheduleSettings(
        automaticBackupsEnabled: true,
        dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
        lastBackupAt: DateTime(2026, 5, 7, 23, 59),
      ),
      runBackup: () async {
        runs += 1;
      },
    );

    final didRun = await scheduler.runCatchUpIfDue(
      now: DateTime(2026, 5, 8, 0, 1),
    );

    expect(didRun, isTrue);
    expect(runs, 1);
  });

  test('registers background scheduling intent with platform adapter',
      () async {
    final adapter = _RecordingBackupScheduleAdapter();
    final scheduler = BackupScheduler(
      settingsLoader: () async => const BackupScheduleSettings(
        automaticBackupsEnabled: true,
        dailyBackupTime: BackupTimeOfDay(hour: 1, minute: 30),
      ),
      runBackup: () async {},
      scheduleAdapter: adapter,
    );

    await scheduler.registerPlatformSchedule();

    expect(
        adapter.registeredTimes, [const BackupTimeOfDay(hour: 1, minute: 30)]);
  });

  test('records catch-up backup failures before surfacing them', () async {
    final recorder = _RecordingBackupEventRecorder();
    final scheduler = BackupScheduler(
      settingsLoader: () async => BackupScheduleSettings(
        automaticBackupsEnabled: true,
        dailyBackupTime: const BackupTimeOfDay(hour: 0, minute: 0),
        lastBackupAt: DateTime(2026, 5, 7, 23, 59),
      ),
      runBackup: () async {
        throw StateError('drive unavailable');
      },
      eventRecorder: recorder,
    );

    await expectLater(
      () => scheduler.runCatchUpIfDue(now: DateTime(2026, 5, 8, 0, 1)),
      throwsA(isA<StateError>()),
    );
    expect(recorder.failures.single, contains('drive unavailable'));
  });
}

class _RecordingBackupScheduleAdapter implements BackupScheduleAdapter {
  final registeredTimes = <BackupTimeOfDay>[];
  var canceled = false;

  @override
  Future<void> registerDailyBackup(BackupTimeOfDay dailyBackupTime) async {
    registeredTimes.add(dailyBackupTime);
  }

  @override
  Future<void> cancelDailyBackup() async {
    canceled = true;
  }
}

class _RecordingBackupEventRecorder implements BackupEventRecorder {
  final failures = <String>[];

  @override
  Future<void> recordBackupFailure(String message) async {
    failures.add(message);
  }
}
