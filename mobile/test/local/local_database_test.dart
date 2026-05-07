import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';

void main() {
  test('local database exposes schema version and core tables', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
    expect(database.allTables.map((table) => table.actualTableName), containsAll(<String>[
      'local_users',
      'products',
      'stock_movements',
      'sellers',
      'seller_transactions',
      'company_profiles',
      'invoices',
      'invoice_items',
      'local_sessions',
      'backup_events',
      'backup_settings',
    ]));
  });

  test('business tables expose backend-compatible columns', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(_columnNames(database, 'products'), containsAll(<String>[
      'company',
      'category',
      'item_name',
      'item_code',
      'buying_price_excl_tax',
      'buying_gst_rate',
      'default_selling_price_excl_tax',
      'default_gst_rate',
      'quantity_on_hand',
      'low_stock_threshold',
      'is_active',
    ]));
    expect(_columnNames(database, 'sellers'), containsAll(<String>[
      'state',
      'state_code',
      'is_active',
    ]));
    expect(_columnNames(database, 'company_profiles'), containsAll(<String>[
      'city',
      'state',
      'state_code',
      'email',
      'bank_name',
      'bank_account',
      'bank_ifsc',
      'bank_branch',
      'jurisdiction',
      'is_active',
    ]));
    expect(_columnNames(database, 'invoices'), containsAll(<String>[
      'request_id',
      'request_hash',
      'seller_name',
      'seller_state_code',
      'company_bank_ifsc',
      'tax_regime',
      'discount_total',
      'taxable_total',
      'cancel_request_id',
      'canceled_by_user_id',
      'canceled_at',
    ]));
    expect(_columnNames(database, 'invoice_items'), containsAll(<String>[
      'line_number',
      'product_name',
      'product_code',
      'pricing_mode',
      'entered_unit_price',
      'unit_price_excl_tax',
      'unit_price_incl_tax',
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
    ]));
  });

  test('backup settings stores automatic backup flag as bool', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.backupSettings.automaticBackupsEnabled, isA<GeneratedColumn<bool>>());
  });

  test('business table nullability and column types match backend models', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    _expectRequired(database, 'products', 'company');
    _expectRequired(database, 'products', 'category');
    _expectRequired(database, 'products', 'item_code');
    _expectNullable(database, 'products', 'buying_price_excl_tax');
    _expectNullable(database, 'products', 'buying_gst_rate');

    _expectRequired(database, 'sellers', 'address');
    _expectRequired(database, 'company_profiles', 'address');
    _expectRequired(database, 'company_profiles', 'city');
    _expectRequired(database, 'company_profiles', 'state');
    _expectRequired(database, 'company_profiles', 'state_code');

    _expectRequired(database, 'invoices', 'seller_address');
    _expectRequired(database, 'invoices', 'place_of_supply_state');
    _expectRequired(database, 'invoices', 'place_of_supply_state_code');
    _expectRequired(database, 'invoices', 'company_address');
    _expectRequired(database, 'invoices', 'company_city');
    _expectRequired(database, 'invoices', 'company_state');
    _expectRequired(database, 'invoices', 'company_state_code');
    _expectRequired(database, 'invoices', 'payment_mode');
    expect(_column(database, 'invoices', 'invoice_number'), isA<GeneratedColumn<int>>());

    _expectNullable(database, 'stock_movements', 'request_id');
    _expectNullable(database, 'stock_movements', 'request_hash');
    _expectNullable(database, 'seller_transactions', 'request_id');
    _expectNullable(database, 'seller_transactions', 'request_hash');

    _expectRequired(database, 'invoice_items', 'product_code');
    _expectRequired(database, 'invoice_items', 'company');
    _expectRequired(database, 'invoice_items', 'category');
  });

  test('foreign key constraints reject orphan invoice items', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await expectLater(
      () => database.customStatement(
        """
        INSERT INTO invoice_items (
          id,
          invoice_id,
          product_id,
          line_number,
          product_name,
          product_code,
          company,
          category,
          quantity,
          pricing_mode,
          entered_unit_price,
          unit_price_excl_tax,
          unit_price_incl_tax,
          gst_rate,
          cgst_rate,
          sgst_rate,
          igst_rate,
          discount_percent,
          discount_amount,
          taxable_amount,
          gst_amount,
          cgst_amount,
          sgst_amount,
          igst_amount,
          line_total
        ) VALUES (
          'item-1',
          'missing-invoice',
          'missing-product',
          1,
          'Missing Product',
          'MISSING-1',
          'Missing Company',
          'Missing Category',
          '1',
          'exclusive',
          '10',
          '10',
          '11.8',
          '18',
          '9',
          '9',
          '0',
          '0',
          '0',
          '10',
          '1.8',
          '0.9',
          '0.9',
          '0',
          '11.8'
        )
        """,
      ),
      throwsA(predicate((Object error) => error.toString().contains('FOREIGN KEY constraint failed'))),
    );
  });
}

Set<String> _columnNames(LocalDatabase database, String tableName) {
  final table = database.allTables.singleWhere((table) => table.actualTableName == tableName);
  return table.$columns.map((column) => column.$name).toSet();
}

GeneratedColumn<Object> _column(LocalDatabase database, String tableName, String columnName) {
  final table = database.allTables.singleWhere((table) => table.actualTableName == tableName);
  return table.$columns.singleWhere((column) => column.$name == columnName);
}

void _expectRequired(LocalDatabase database, String tableName, String columnName) {
  final column = _column(database, tableName, columnName);
  expect(column.$nullable, isFalse, reason: '$tableName.$columnName should be NOT NULL');
  expect(column.requiredDuringInsert, isTrue, reason: '$tableName.$columnName should require insert values');
}

void _expectNullable(LocalDatabase database, String tableName, String columnName) {
  final column = _column(database, tableName, columnName);
  expect(column.$nullable, isTrue, reason: '$tableName.$columnName should allow null');
  expect(column.requiredDuringInsert, isFalse, reason: '$tableName.$columnName should not require insert values');
}
