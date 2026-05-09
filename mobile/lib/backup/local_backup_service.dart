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

  static const _expectedColumns = <String, Set<String>>{
    'local_users': {
      'id',
      'username',
      'password_hash',
      'display_name',
      'is_active',
      'salt',
      'password_hash_version',
      'created_at',
      'updated_at',
    },
    'products': {
      'id',
      'item_number',
      'item_name',
      'category',
      'buyer_id',
      'company_name',
      'buying_price',
      'selling_price',
      'unit',
      'gst_rate',
      'quantity_on_hand',
      'low_stock_threshold',
      'is_active',
      'created_at',
      'updated_at',
    },
    'sellers': {
      'id',
      'name',
      'address',
      'state',
      'state_code',
      'phone',
      'gstin',
      'is_active',
      'created_at',
      'updated_at',
    },
    'company_profiles': {
      'id',
      'name',
      'address',
      'city',
      'state',
      'state_code',
      'gstin',
      'phone',
      'email',
      'bank_name',
      'bank_account',
      'bank_ifsc',
      'bank_branch',
      'jurisdiction',
      'is_active',
      'created_at',
      'updated_at',
    },
    'invoices': {
      'id',
      'request_id',
      'request_hash',
      'invoice_number',
      'seller_id',
      'seller_name',
      'seller_address',
      'seller_state',
      'seller_state_code',
      'seller_phone',
      'seller_gstin',
      'place_of_supply_state',
      'place_of_supply_state_code',
      'company_name',
      'company_address',
      'company_city',
      'company_state',
      'company_state_code',
      'company_gstin',
      'company_phone',
      'company_email',
      'company_bank_name',
      'company_bank_account',
      'company_bank_ifsc',
      'company_bank_branch',
      'company_jurisdiction',
      'invoice_date',
      'tax_regime',
      'status',
      'payment_mode',
      'subtotal',
      'discount_total',
      'taxable_total',
      'gst_total',
      'grand_total',
      'notes',
      'created_by_user_id',
      'cancel_request_id',
      'cancel_request_hash',
      'canceled_by_user_id',
      'cancel_reason',
      'canceled_at',
      'created_at',
    },
    'invoice_items': {
      'id',
      'invoice_id',
      'product_id',
      'line_number',
      'product_name',
      'product_code',
      'company',
      'category',
      'quantity',
      'pricing_mode',
      'entered_unit_price',
      'unit_price_excl_tax',
      'unit_price_incl_tax',
      'gst_rate',
      'cgst_rate',
      'sgst_rate',
      'igst_rate',
      'discount_percent',
      'discount_amount',
      'taxable_amount',
      'gst_amount',
      'cgst_amount',
      'sgst_amount',
      'igst_amount',
      'line_total',
    },
    'stock_movements': {
      'id',
      'product_id',
      'invoice_id',
      'request_id',
      'request_hash',
      'movement_type',
      'quantity_delta',
      'reason',
      'created_by_user_id',
      'created_at',
    },
    'seller_transactions': {
      'id',
      'seller_id',
      'invoice_id',
      'request_id',
      'request_hash',
      'opening_balance_seller_id',
      'entry_type',
      'amount',
      'occurred_on',
      'notes',
      'created_by_user_id',
      'created_at',
    },
    'backup_settings': {
      'id',
      'backup_directory',
      'automatic_backups_enabled',
      'daily_backup_time',
      'last_backup_at',
      'updated_at',
    },
    'backup_events': {
      'id',
      'event_type',
      'status',
      'file_path',
      'message',
      'created_at',
    },
  };

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
    _validatePayload(payload);

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

  void _validatePayload(LocalBackupPayload payload) {
    for (final tableName in _tables) {
      if (!payload.tables.containsKey(tableName)) {
        throw InvalidBackupPayloadException(
          'Backup payload is missing required table $tableName',
        );
      }
      final expectedColumns = _expectedColumns[tableName]!;
      final rows = payload.tables[tableName]!;
      for (final row in rows) {
        final columns = row.keys.toSet();
        if (columns.length != row.length ||
            !columns.containsAll(expectedColumns) ||
            !expectedColumns.containsAll(columns)) {
          throw InvalidBackupPayloadException(
            'Backup payload has invalid columns for table $tableName',
          );
        }
      }
    }
    for (final tableName in payload.tables.keys) {
      if (!_expectedColumns.containsKey(tableName)) {
        throw InvalidBackupPayloadException(
          'Backup payload contains unsupported table $tableName',
        );
      }
    }
  }

  Future<void> _insertRow(String tableName, Map<String, Object?> row) {
    final columns = row.keys.toList();
    final placeholders = List<String>.filled(columns.length, '?').join(', ');
    final columnSql = columns.join(', ');
    return _database.customStatement(
      'INSERT INTO $tableName ($columnSql) VALUES ($placeholders)',
      columns.map((column) => row[column]).toList(),
    );
  }
}
