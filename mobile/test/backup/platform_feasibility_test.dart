import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_background_callback.dart';
import 'package:internal_billing_khata_mobile/backup/backup_scheduler.dart';
import 'package:internal_billing_khata_mobile/backup/drive_platform.dart';
import 'package:internal_billing_khata_mobile/backup/workmanager_schedule_adapter.dart';

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

class FakeDriveGateway implements DriveGateway {
  FakeDriveGateway({this.shouldFailVerification = false});

  final files = <String, _StoredDriveFile>{};
  final shouldFailVerification;
  var _folderId = 'folder-1';
  var _nextId = 1;

  @override
  Future<String> ensureBackupFolder() async => _folderId;

  @override
  Future<List<DriveBackupFile>> listOwnedBackupFiles({required String folderId}) async {
    return files.values
        .where((file) => file.folderId == folderId)
        .map((file) => file.toMetadata())
        .toList()
      ..sort((a, b) => b.createdTime.compareTo(a.createdTime));
  }

  @override
  Future<DriveBackupFile> uploadBackupFile({
    required String folderId,
    required String fileName,
    required List<int> bytes,
    required Map<String, String> appProperties,
  }) async {
    final id = 'file-${_nextId++}';
    final sha = 'sha-${bytes.join('-')}';
    files[id] = _StoredDriveFile(
      id: id,
      folderId: folderId,
      name: fileName,
      bytes: List<int>.from(bytes),
      appProperties: Map<String, String>.from(appProperties),
      sha256: sha,
    );
    return files[id]!.toMetadata();
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    final file = files[fileId];
    if (file == null) {
      throw const DriveTransportException('file not found');
    }
    return List<int>.from(file.bytes);
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    files.remove(fileId);
  }

  @override
  Future<void> verifyUploadedFile({
    required String fileId,
    required String expectedSha256,
  }) async {
    if (shouldFailVerification) {
      throw const DriveTransportException('upload verification failed');
    }
    final file = files[fileId];
    if (file == null || file.sha256 != expectedSha256) {
      throw const DriveTransportException('upload verification failed');
    }
  }
}

class _StoredDriveFile {
  _StoredDriveFile({
    required this.id,
    required this.folderId,
    required this.name,
    required this.bytes,
    required this.appProperties,
    required this.sha256,
  });

  final String id;
  final String folderId;
  final String name;
  final List<int> bytes;
  final Map<String, String> appProperties;
  final String sha256;

  DriveBackupFile toMetadata() {
    return DriveBackupFile(
      id: id,
      name: name,
      createdTime: DateTime.utc(2026, 6, 14),
      sizeBytes: bytes.length,
      appProperties: appProperties,
      sha256: sha256,
    );
  }
}

class FakeGoogleAuthGateway implements GoogleAuthGateway {
  FakeGoogleAuthGateway({
    bool signedIn = true,
    this.hasAccess = true,
    this.shouldCancelSignIn = false,
  }) : _signedIn = signedIn;

  bool _signedIn;
  final bool hasAccess;
  final bool shouldCancelSignIn;

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<void> signIn() async {
    if (shouldCancelSignIn) {
      throw const DriveAuthException('sign in canceled');
    }
    _signedIn = true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }

  @override
  Future<bool> hasDriveAccess() async => _signedIn && hasAccess;
}

class FakeBackupSecretStore implements BackupSecretStore {
  String? _password;

  @override
  Future<void> clearPassword() async {
    _password = null;
  }

  @override
  Future<bool> hasPassword() async => _password != null && _password!.isNotEmpty;

  @override
  Future<String?> readPassword() async => _password;

  @override
  Future<void> savePassword(String password) async {
    _password = password;
  }
}