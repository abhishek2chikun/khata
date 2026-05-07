class BackupTimeOfDay {
  const BackupTimeOfDay({required this.hour, required this.minute})
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  DateTime onDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    return other is BackupTimeOfDay &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}

class BackupScheduleSettings {
  const BackupScheduleSettings({
    this.automaticBackupsEnabled = false,
    this.dailyBackupTime = const BackupTimeOfDay(hour: 0, minute: 0),
    this.lastBackupAt,
  });

  final bool automaticBackupsEnabled;
  final BackupTimeOfDay dailyBackupTime;
  final DateTime? lastBackupAt;
}

abstract class BackupScheduleAdapter {
  Future<void> registerDailyBackup(BackupTimeOfDay dailyBackupTime);
}

class UnsupportedBackupScheduleAdapter implements BackupScheduleAdapter {
  const UnsupportedBackupScheduleAdapter();

  @override
  Future<void> registerDailyBackup(BackupTimeOfDay dailyBackupTime) {
    throw const BackupSchedulingUnsupportedException(
      'Background backup scheduling requires platform task configuration.',
    );
  }
}

class BackupSchedulingUnsupportedException implements Exception {
  const BackupSchedulingUnsupportedException(this.message);

  final String message;

  @override
  String toString() => 'BackupSchedulingUnsupportedException: $message';
}

class BackupScheduler {
  BackupScheduler({
    required Future<BackupScheduleSettings> Function() settingsLoader,
    required Future<void> Function() runBackup,
    BackupScheduleAdapter scheduleAdapter =
        const UnsupportedBackupScheduleAdapter(),
  })  : _settingsLoader = settingsLoader,
        _runBackup = runBackup,
        _scheduleAdapter = scheduleAdapter;

  final Future<BackupScheduleSettings> Function() _settingsLoader;
  final Future<void> Function() _runBackup;
  final BackupScheduleAdapter _scheduleAdapter;

  static DateTime nextDueBackup({
    required DateTime now,
    required BackupScheduleSettings settings,
  }) {
    final todayDueAt = settings.dailyBackupTime.onDate(now);
    if (now.isBefore(todayDueAt)) {
      return todayDueAt;
    }
    return settings.dailyBackupTime.onDate(now.add(const Duration(days: 1)));
  }

  static bool isBackupDue({
    required DateTime now,
    required BackupScheduleSettings settings,
  }) {
    return missedBackupDueAt(now: now, settings: settings) != null;
  }

  static DateTime? missedBackupDueAt({
    required DateTime now,
    required BackupScheduleSettings settings,
  }) {
    if (!settings.automaticBackupsEnabled) {
      return null;
    }

    final dueAt = settings.dailyBackupTime.onDate(now);
    if (now.isBefore(dueAt)) {
      return null;
    }

    final lastBackupAt = settings.lastBackupAt;
    if (lastBackupAt == null || lastBackupAt.isBefore(dueAt)) {
      return dueAt;
    }
    return null;
  }

  Future<bool> runCatchUpIfDue({DateTime? now}) async {
    final settings = await _settingsLoader();
    if (!isBackupDue(now: now ?? DateTime.now(), settings: settings)) {
      return false;
    }
    await _runBackup();
    return true;
  }

  Future<void> registerPlatformSchedule() async {
    final settings = await _settingsLoader();
    if (!settings.automaticBackupsEnabled) {
      return;
    }
    await _scheduleAdapter.registerDailyBackup(settings.dailyBackupTime);
  }
}
