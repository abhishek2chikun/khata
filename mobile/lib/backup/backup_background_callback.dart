import 'backup_scheduler.dart';
import 'drive_platform.dart';

/// Unique WorkManager task name for daily encrypted backup.
const backupBackgroundTaskName = 'khata_daily_encrypted_backup';

/// Injectable runner used by tests and production background entry point.
typedef BackupBackgroundRunner = Future<BackupBackgroundResult> Function();

BackupBackgroundRunner? _backupBackgroundRunner;

/// Test-only hook to inject fake dependencies without widget bindings.
void configureBackupBackgroundRunner(BackupBackgroundRunner? runner) {
  _backupBackgroundRunner = runner;
}

class BackupBackgroundResult {
  const BackupBackgroundResult.success()
      : succeeded = true,
        actionRequired = false,
        message = null;

  const BackupBackgroundResult.actionRequired(this.message)
      : succeeded = false,
        actionRequired = true;

  const BackupBackgroundResult.failure(this.message)
      : succeeded = false,
        actionRequired = false;

  final bool succeeded;
  final bool actionRequired;
  final String? message;
}

/// Runs a background backup attempt using injected or default runner logic.
Future<BackupBackgroundResult> runBackupBackgroundTask() async {
  final runner = _backupBackgroundRunner ?? _defaultBackgroundRunner;
  return runner();
}

Future<BackupBackgroundResult> _defaultBackgroundRunner() async {
  // Production wiring is completed in Task 05. Task 01 proves the callback
  // boundary compiles and can be invoked without Flutter widget bindings.
  return const BackupBackgroundResult.actionRequired(
    'Background backup requires Google account and secure password.',
  );
}

/// Validates that background execution can consult auth/secret gateways without UI.
Future<BackupBackgroundResult> evaluateBackgroundPrerequisites({
  required GoogleAuthGateway authGateway,
  required BackupSecretStore secretStore,
}) async {
  if (!await authGateway.isSignedIn() || !await authGateway.hasDriveAccess()) {
    return const BackupBackgroundResult.actionRequired(
      'Sign in to Google Drive in the app to enable automatic backup.',
    );
  }
  if (!await secretStore.hasPassword()) {
    return const BackupBackgroundResult.actionRequired(
      'Set a backup password in the app to enable automatic backup.',
    );
  }
  return const BackupBackgroundResult.success();
}

/// Top-level WorkManager entry point. Must not depend on widget state.
@pragma('vm:entry-point')
Future<void> backupBackgroundCallbackDispatcher() async {
  final result = await runBackupBackgroundTask();
  if (result.actionRequired || !result.succeeded) {
    throw BackupBackgroundExecutionException(result.message ?? 'backup failed');
  }
}

class BackupBackgroundExecutionException implements Exception {
  const BackupBackgroundExecutionException(this.message);

  final String message;

  @override
  String toString() => 'BackupBackgroundExecutionException: $message';
}
