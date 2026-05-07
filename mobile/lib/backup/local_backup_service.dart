import '../local/local_database.dart';
import 'backup_crypto.dart';
import 'backup_models.dart';

class LocalBackupService {
  LocalBackupService({
    required LocalDatabase database,
    BackupCrypto? crypto,
  })  : _database = database,
        _crypto = crypto ?? BackupCrypto();

  final LocalDatabase _database;
  final BackupCrypto _crypto;

  static const _tables = <String>[
    'local_users',
    'products',
    'sellers',
    'company_profiles',
    'invoices',
    'invoice_items',
    'stock_movements',
    'seller_transactions',
    'backup_settings',
    'backup_events',
  ];

  static const _deleteOrder = <String>[
    'backup_events',
    'backup_settings',
    'local_sessions',
    'seller_transactions',
    'stock_movements',
    'invoice_items',
    'invoices',
    'company_profiles',
    'sellers',
    'products',
    'local_users',
  ];

  Future<LocalBackupPackage> exportEncrypted({
    required String password,
    int schemaVersion = LocalBackupPayload.currentSchemaVersion,
  }) async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final tableName in _tables) {
      final rows =
          await _database.customSelect('SELECT * FROM $tableName').get();
      tables[tableName] = rows.map((row) => row.data).toList();
    }
    final payload = LocalBackupPayload(
      schemaVersion: schemaVersion,
      backendCompatibilityVersion:
          LocalBackupPayload.currentBackendCompatibilityVersion,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      tables: tables,
    );
    return _crypto.encrypt(payloadBytes: payload.encode(), password: password);
  }

  Future<void> importEncrypted({
    required LocalBackupPackage package,
    required String password,
  }) async {
    final payload = LocalBackupPayload.decode(
      await _crypto.decrypt(package: package, password: password),
    );
    if (payload.schemaVersion != LocalBackupPayload.currentSchemaVersion) {
      throw UnsupportedBackupVersionException(
        'Unsupported backup schema version ${payload.schemaVersion}',
      );
    }
    if (payload.backendCompatibilityVersion !=
        LocalBackupPayload.currentBackendCompatibilityVersion) {
      throw UnsupportedBackupVersionException(
        'Unsupported backend compatibility version '
        '${payload.backendCompatibilityVersion}',
      );
    }
    _validateRequiredTables(payload);

    await _database.transaction(() async {
      for (final tableName in _deleteOrder) {
        await _database.customStatement('DELETE FROM $tableName');
      }
      for (final tableName in _tables) {
        for (final row
            in payload.tables[tableName] ?? const <Map<String, Object?>>[]) {
          await _insertRow(tableName, row);
        }
      }
    });
  }

  void _validateRequiredTables(LocalBackupPayload payload) {
    for (final tableName in _tables) {
      if (!payload.tables.containsKey(tableName)) {
        throw InvalidBackupPayloadException(
          'Backup payload is missing required table $tableName',
        );
      }
    }
  }

  Future<void> _insertRow(String tableName, Map<String, Object?> row) {
    if (row.isEmpty) {
      return Future<void>.value();
    }
    final columns = row.keys.toList();
    final placeholders = List<String>.filled(columns.length, '?').join(', ');
    final columnSql = columns.join(', ');
    return _database.customStatement(
      'INSERT INTO $tableName ($columnSql) VALUES ($placeholders)',
      columns.map((column) => row[column]).toList(),
    );
  }
}
