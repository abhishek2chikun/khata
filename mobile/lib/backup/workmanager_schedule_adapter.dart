import 'package:workmanager/workmanager.dart';

import 'backup_background_callback.dart';
import 'backup_scheduler.dart';

/// Registers unique periodic WorkManager backup near the configured local time.
class WorkManagerBackupScheduleAdapter implements BackupScheduleAdapter {
  WorkManagerBackupScheduleAdapter({
    Workmanager? workmanager,
    Future<void> Function(String, String, Duration)? registerPeriodicTask,
    Future<void> Function(String)? cancelByUniqueName,
  })  : _workmanager = workmanager ?? Workmanager(),
        _registerPeriodicTask = registerPeriodicTask,
        _cancelByUniqueName = cancelByUniqueName;

  final Workmanager _workmanager;
  final Future<void> Function(String, String, Duration)? _registerPeriodicTask;
  final Future<void> Function(String)? _cancelByUniqueName;

  static Duration initialDelayUntil(BackupTimeOfDay dailyBackupTime, DateTime now) {
    final nextDue = BackupScheduler.nextDueBackup(now: now, settings: BackupScheduleSettings(
      automaticBackupsEnabled: true,
      dailyBackupTime: dailyBackupTime,
    ));
    final delay = nextDue.difference(now);
    return delay.isNegative ? Duration.zero : delay;
  }

  @override
  Future<void> registerDailyBackup(BackupTimeOfDay dailyBackupTime) async {
    final delay = initialDelayUntil(dailyBackupTime, DateTime.now());
    if (_registerPeriodicTask != null) {
      await _registerPeriodicTask(
        backupBackgroundTaskName,
        backupBackgroundTaskName,
        delay,
      );
      return;
    }
    await _workmanager.registerPeriodicTask(
      backupBackgroundTaskName,
      backupBackgroundTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  @override
  Future<void> cancelDailyBackup() async {
    if (_cancelByUniqueName != null) {
      await _cancelByUniqueName(backupBackgroundTaskName);
      return;
    }
    await _workmanager.cancelByUniqueName(backupBackgroundTaskName);
  }
}
