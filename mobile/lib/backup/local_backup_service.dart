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
    'customers',
    'buyers',
    'company_profiles',
    'invoices',
    'invoice_items',
    'stock_movements',
    'customer_transactions',
    'buyer_transactions',
    'backup_settings',
    'backup_events',
  ];

  static const _deleteOrder = <String>[
    'backup_events',
    'backup_settings',
    'local_sessions',
    'buyer_transactions',
    'customer_transactions',
    'stock_movements',
    'invoice_items',
    'invoices',
    'company_profiles',
    'buyers',
    'customers',
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
      'hsn_code',
      'quantity_on_hand',
      'low_stock_threshold',
      'is_active',
      'created_at',
      'updated_at',
    },
    'customers': {
      'id',
      'name',
      'address',
      'state',
      'state_code',
      'phone',
      'gstin',
      'whatsapp_number',
      'is_active',
      'created_at',
      'updated_at',
    },
    'buyers': {
      'id',
      'name',
      'address',
      'state',
      'state_code',
      'phone',
      'gstin',
      'whatsapp_number',
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
      'gst_flag',
      'created_at',
      'updated_at',
    },
    'invoices': {
      'id',
      'request_id',
      'request_hash',
      'invoice_number',
      'customer_id',
      'customer_name',
      'customer_address',
      'customer_state',
      'customer_state_code',
      'customer_phone',
      'customer_whatsapp_number',
      'customer_gstin',
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
      'gst_flag',
      'invoice_date',
      'invoice_datetime',
      'tax_regime',
      'status',
      'payment_state',
      'paid_amount',
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
      'product_item_number',
      'product_item_name',
      'product_category',
      'product_buyer_id',
      'product_company_name',
      'product_hsn_code',
      'buying_price',
      'selling_price',
      'unit',
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
      'revenue_amount',
      'buying_amount',
      'profit_amount',
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
    'customer_transactions': {
      'id',
      'customer_id',
      'invoice_id',
      'request_id',
      'request_hash',
      'opening_balance_customer_id',
      'entry_type',
      'amount',
      'occurred_on',
      'notes',
      'created_by_user_id',
      'created_at',
    },
    'buyer_transactions': {
      'id',
      'buyer_id',
      'request_id',
      'request_hash',
      'opening_payable_buyer_id',
      'entry_type',
      'amount',
      'occurred_at',
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
    if (payload.schemaVersion < 9 ||
        payload.schemaVersion > LocalBackupPayload.currentSchemaVersion) {
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
    final normalizedPayload = payload.schemaVersion == 9
        ? _convertV9BackupPayload(payload)
        : payload;
    _validatePayload(normalizedPayload);

    await _database.transaction(() async {
      for (final tableName in _deleteOrder) {
        await _database.customStatement('DELETE FROM $tableName');
      }
      for (final tableName in _tables) {
        for (final row
            in normalizedPayload.tables[tableName] ??
                const <Map<String, Object?>>[]) {
          await _insertRow(tableName, row);
        }
      }
    });
  }

  LocalBackupPayload _convertV9BackupPayload(LocalBackupPayload payload) {
    final tables = payload.tables.map(
      (tableName, rows) => MapEntry(
        tableName,
        rows.map((row) => Map<String, Object?>.from(row)).toList(),
      ),
    );
    for (final row in tables['products'] ?? const <Map<String, Object?>>[]) {
      row.putIfAbsent('hsn_code', () => null);
    }
    for (final row
        in tables['invoice_items'] ?? const <Map<String, Object?>>[]) {
      row.putIfAbsent('product_hsn_code', () => null);
    }
    return LocalBackupPayload(
      schemaVersion: LocalBackupPayload.currentSchemaVersion,
      backendCompatibilityVersion: payload.backendCompatibilityVersion,
      exportedAt: payload.exportedAt,
      tables: tables,
    );
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
