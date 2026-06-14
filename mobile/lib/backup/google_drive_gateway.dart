import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import 'drive_platform.dart';

/// Drive v3 transport using an authenticated Google API client.
class GoogleApisDriveGateway implements DriveGateway {
  GoogleApisDriveGateway({required auth.AuthClient client})
      : _api = drive.DriveApi(client);

  final drive.DriveApi _api;

  @override
  Future<String> ensureBackupFolder() async {
    final existing = await _api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' "
          "and name='${DriveGateway.khataFolderName}' "
          "and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,appProperties)',
    );
    for (final file in existing.files ?? const <drive.File>[]) {
      if (file.appProperties?[DriveGateway.khataOwnerProperty] ==
          DriveGateway.khataOwnerValue) {
        return file.id!;
      }
    }

    final created = await _api.files.create(
      drive.File(
        name: DriveGateway.khataFolderName,
        mimeType: 'application/vnd.google-apps.folder',
        appProperties: {
          DriveGateway.khataOwnerProperty: DriveGateway.khataOwnerValue,
        },
      ),
      $fields: 'id',
    );
    return created.id!;
  }

  @override
  Future<List<DriveBackupFile>> listOwnedBackupFiles({
    required String folderId,
  }) async {
    final response = await _api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,createdTime,size,appProperties)',
    );
    final files = <DriveBackupFile>[];
    for (final file in response.files ?? const <drive.File>[]) {
      final properties = file.appProperties ?? const <String, String>{};
      if (properties[DriveGateway.khataOwnerProperty] !=
          DriveGateway.khataOwnerValue) {
        continue;
      }
      files.add(
        DriveBackupFile(
          id: file.id!,
          name: file.name ?? 'backup.khata',
          createdTime: file.createdTime ?? DateTime.now().toUtc(),
          sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
          appProperties: Map<String, String>.from(properties),
          sha256: properties['sha256'],
        ),
      );
    }
    return files;
  }

  @override
  Future<DriveBackupFile> uploadBackupFile({
    required String folderId,
    required String fileName,
    required List<int> bytes,
    required Map<String, String> appProperties,
  }) async {
    final sha256 = _sha256Hex(bytes);
    final metadata = drive.File(
      name: fileName,
      parents: [folderId],
      description: 'Encrypted Khata local backup',
      appProperties: {
        ...appProperties,
        'sha256': sha256,
      },
    );
    final uploaded = await _api.files.create(
      metadata,
      uploadMedia: drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: 'application/octet-stream',
      ),
      $fields: 'id,name,createdTime,size,appProperties',
    );
    final properties = uploaded.appProperties ?? const <String, String>{};
    return DriveBackupFile(
      id: uploaded.id!,
      name: uploaded.name ?? fileName,
      createdTime: uploaded.createdTime ?? DateTime.now().toUtc(),
      sizeBytes: int.tryParse(uploaded.size ?? '${bytes.length}') ?? bytes.length,
      appProperties: Map<String, String>.from(properties),
      sha256: properties['sha256'] ?? sha256,
    );
  }

  @override
  Future<List<int>> downloadFile({required String fileId}) async {
    final media = await _api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return media.stream.expand((chunk) => chunk).toList();
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    await _api.files.delete(fileId);
  }

  @override
  Future<void> verifyUploadedFile({
    required String fileId,
    required String expectedSha256,
  }) async {
    final metadata = await _api.files.get(
      fileId,
      $fields: 'id,appProperties,size',
    ) as drive.File;
    final storedHash = metadata.appProperties?['sha256'];
    if (storedHash != null && storedHash != expectedSha256) {
      throw const DriveTransportException('upload verification failed');
    }
    final bytes = await downloadFile(fileId: fileId);
    if (_sha256Hex(bytes) != expectedSha256) {
      throw const DriveTransportException('upload verification failed');
    }
  }

  static String _sha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}
