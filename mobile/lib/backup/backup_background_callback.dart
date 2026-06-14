import 'package:flutter/widgets.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:workmanager/workmanager.dart';

import '../local/local_database.dart';
import 'backup_models.dart';
import 'backup_scheduler.dart';
import 'drive_backup_service.dart';
import 'drive_platform.dart';
import 'encrypted_drive_backup_orchestrator.dart';
import 'google_auth_gateway.dart';
import 'google_drive_gateway.dart';
import 'secure_backup_secret_store.dart';

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
  LocalDatabase? database;
  auth.AuthClient? authClient;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    database = LocalDatabase();
    final authGateway = GoogleSignInAuthGateway();
    final secretStore = FlutterSecureBackupSecretStore();
    final prerequisites = await evaluateBackgroundPrerequisites(
      authGateway: authGateway,
      secretStore: secretStore,
    );
    if (prerequisites.actionRequired) {
      await LocalBackupEventRecorder(database: database).recordBackupFailure(
        prerequisites.message ?? 'Background backup requires user action.',
      );
      return prerequisites;
    }

    authClient = await authGateway.createDriveAuthClient(
      promptIfUnauthorized: false,
    );
    if (authClient == null) {
      const message =
          'Sign in to Google Drive in the app to enable automatic backup.';
      await LocalBackupEventRecorder(database: database).recordBackupFailure(
        message,
      );
      return const BackupBackgroundResult.actionRequired(message);
    }

    final orchestrator = EncryptedDriveBackupOrchestrator(
      database: database,
      authGateway: authGateway,
      secretStore: secretStore,
      driveGatewayFactory: () async {
        return GoogleApisDriveGateway(client: authClient!);
      },
    );
    await orchestrator.runVerifiedBackup();
    return const BackupBackgroundResult.success();
  } on Object catch (error) {
    if (database != null) {
      await LocalBackupEventRecorder(database: database).recordBackupFailure(
        redactBackupFailureMessage(error),
      );
    }
    return BackupBackgroundResult.failure(redactBackupFailureMessage(error));
  } finally {
    authClient?.close();
    await database?.close();
  }
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

/// Top-level WorkManager callback dispatcher.
@pragma('vm:entry-point')
void backupWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final result = await runBackupBackgroundTask();
    if (result.actionRequired) {
      return true;
    }
    return result.succeeded;
  });
}

class BackupBackgroundExecutionException implements Exception {
  const BackupBackgroundExecutionException(this.message);

  final String message;

  @override
  String toString() => 'BackupBackgroundExecutionException: $message';
}
