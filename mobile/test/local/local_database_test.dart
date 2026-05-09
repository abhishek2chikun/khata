import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('local database exposes schema version and core tables', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.schemaVersion, 4);
    expect(
        database.allTables.map((table) => table.actualTableName),
        containsAll(<String>[
          'local_users',
          'products',
          'stock_movements',
          'customers',
          'customer_transactions',
          'buyers',
          'buyer_transactions',
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

    expect(
        _columnNames(database, 'products'),
        containsAll(<String>[
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
        ]));
    expect(
        _columnNames(database, 'customers'),
        containsAll(<String>[
          'state',
          'state_code',
          'is_active',
        ]));
    expect(
        _columnNames(database, 'buyers'),
        containsAll(<String>[
          'state',
          'state_code',
          'is_active',
        ]));
    expect(
        _columnNames(database, 'buyer_transactions'),
        containsAll(<String>[
          'request_id',
          'request_hash',
          'opening_payable_buyer_id',
          'entry_type',
          'amount',
          'occurred_at',
          'created_by_user_id',
        ]));
    expect(
        _columnNames(database, 'company_profiles'),
        containsAll(<String>[
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
    expect(
        _columnNames(database, 'invoices'),
        containsAll(<String>[
          'request_id',
          'request_hash',
          'customer_name',
          'customer_state_code',
          'company_bank_ifsc',
          'tax_regime',
          'discount_total',
          'taxable_total',
          'cancel_request_id',
          'canceled_by_user_id',
          'canceled_at',
        ]));
    expect(
        _columnNames(database, 'invoice_items'),
        containsAll(<String>[
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

  test('products table exposes canonical V2 columns and constraints', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(
        _columnNames(database, 'products'),
        containsAll(<String>[
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
        ]));
    _expectRequired(database, 'products', 'item_number');
    _expectRequired(database, 'products', 'company_name');
    _expectRequired(database, 'products', 'buying_price');
    _expectRequired(database, 'products', 'selling_price');
    _expectRequired(database, 'products', 'gst_rate');
    _expectNullable(database, 'products', 'unit');

    final productTable = database.allTables
        .singleWhere((table) => table.actualTableName == 'products');
    final uniqueKeys = productTable.uniqueKeys
        .map((key) => key.map((column) => column.$name).toSet())
        .toList();
    expect(uniqueKeys, contains(equals(<String>{'item_number'})));
    expect(
      uniqueKeys,
      contains(equals(<String>{'company_name', 'item_name', 'category'})),
    );
  });

  test('migrates schema v1 products to canonical inclusive-price V2 rows',
      () async {
    final directory = await Directory.systemTemp.createTemp('khata-v1-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/local.sqlite');
    _seedSchemaV1Database(file);

    final database = LocalDatabase.forConnection(NativeDatabase(file));
    addTearDown(database.close);

    final products = await database.select(database.products).get();

    expect(products, hasLength(3));
    final pen = products.singleWhere((product) => product.id == 'product-1');
    expect(pen.id, 'product-1');
    expect(pen.itemNumber, 'PEN-1');
    expect(pen.companyName, 'Acme');
    expect(pen.category, 'Pens');
    expect(pen.itemName, 'Blue Pen');
    expect(pen.buyerId, null);
    expect(pen.buyingPrice, '84');
    expect(pen.sellingPrice, '118');
    expect(pen.unit, null);
    expect(pen.gstRate, '18');
    expect(pen.quantityOnHand, '7.500');
    expect(pen.lowStockThreshold, '2.000');
    expect(pen.isActive, isTrue);
    expect(pen.createdAt, '2026-01-01T00:00:00.000Z');
    expect(pen.updatedAt, '2026-01-02T00:00:00.000Z');

    final fallback =
        products.singleWhere((product) => product.id == 'product-2');
    expect(fallback.buyingPrice, '0');
    expect(fallback.sellingPrice, '56');
    expect(fallback.quantityOnHand, '3.250');

    final zeroTax =
        products.singleWhere((product) => product.id == 'product-3');
    expect(zeroTax.buyingPrice, '80');
    expect(zeroTax.sellingPrice, '118');

    final movement = await database.customSelect(
      'SELECT product_id FROM stock_movements WHERE id = ?',
      variables: <Variable<Object>>[Variable<String>('movement-1')],
    ).getSingle();
    expect(movement.data['product_id'], 'product-1');

    await expectLater(
      () => database.customStatement(
        """
        INSERT INTO products (
          id, item_number, item_name, category, buyer_id, company_name,
          buying_price, selling_price, unit, gst_rate, quantity_on_hand,
          low_stock_threshold, is_active, created_at, updated_at
        ) VALUES (
          'duplicate-number', 'PEN-1', 'Other Pen', 'Pens', NULL, 'Other',
          '10', '12', NULL, '18', '1', '0', 1,
          '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'
        )
        """,
      ),
      throwsA(anything),
    );
    await expectLater(
      () => database.customStatement(
        """
        INSERT INTO products (
          id, item_number, item_name, category, buyer_id, company_name,
          buying_price, selling_price, unit, gst_rate, quantity_on_hand,
          low_stock_threshold, is_active, created_at, updated_at
        ) VALUES (
          'duplicate-identity', 'PEN-2', 'Blue Pen', 'Pens', NULL, 'Acme',
          '10', '12', NULL, '18', '1', '0', 1,
          '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'
        )
        """,
      ),
      throwsA(anything),
    );
  });

  test('backup settings stores automatic backup flag and daily time', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    expect(database.backupSettings.automaticBackupsEnabled,
        isA<GeneratedColumn<bool>>());
    expect(database.backupSettings.dailyBackupTime,
        isA<GeneratedColumn<String>>());
  });

  test('business table nullability and column types match backend models',
      () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    _expectRequired(database, 'products', 'company_name');
    _expectRequired(database, 'products', 'category');
    _expectRequired(database, 'products', 'item_number');
    _expectRequired(database, 'products', 'buying_price');
    _expectRequired(database, 'products', 'selling_price');
    _expectRequired(database, 'products', 'gst_rate');
    _expectNullable(database, 'products', 'unit');

    _expectRequired(database, 'customers', 'address');
    _expectRequired(database, 'company_profiles', 'address');
    _expectRequired(database, 'company_profiles', 'city');
    _expectRequired(database, 'company_profiles', 'state');
    _expectRequired(database, 'company_profiles', 'state_code');

    _expectRequired(database, 'invoices', 'customer_address');
    _expectRequired(database, 'invoices', 'place_of_supply_state');
    _expectRequired(database, 'invoices', 'place_of_supply_state_code');
    _expectRequired(database, 'invoices', 'company_address');
    _expectRequired(database, 'invoices', 'company_city');
    _expectRequired(database, 'invoices', 'company_state');
    _expectRequired(database, 'invoices', 'company_state_code');
    _expectRequired(database, 'invoices', 'payment_mode');
    expect(_column(database, 'invoices', 'invoice_number'),
        isA<GeneratedColumn<int>>());

    _expectNullable(database, 'stock_movements', 'request_id');
    _expectNullable(database, 'stock_movements', 'request_hash');
    _expectNullable(database, 'customer_transactions', 'request_id');
    _expectNullable(database, 'customer_transactions', 'request_hash');

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
      throwsA(predicate((Object error) =>
          error.toString().contains('FOREIGN KEY constraint failed'))),
    );
  });
}

Set<String> _columnNames(LocalDatabase database, String tableName) {
  final table = database.allTables
      .singleWhere((table) => table.actualTableName == tableName);
  return table.$columns.map((column) => column.$name).toSet();
}

GeneratedColumn<Object> _column(
    LocalDatabase database, String tableName, String columnName) {
  final table = database.allTables
      .singleWhere((table) => table.actualTableName == tableName);
  return table.$columns.singleWhere((column) => column.$name == columnName);
}

void _expectRequired(
    LocalDatabase database, String tableName, String columnName) {
  final column = _column(database, tableName, columnName);
  expect(column.$nullable, isFalse,
      reason: '$tableName.$columnName should be NOT NULL');
  expect(column.requiredDuringInsert, isTrue,
      reason: '$tableName.$columnName should require insert values');
}

void _expectNullable(
    LocalDatabase database, String tableName, String columnName) {
  final column = _column(database, tableName, columnName);
  expect(column.$nullable, isTrue,
      reason: '$tableName.$columnName should allow null');
  expect(column.requiredDuringInsert, isFalse,
      reason: '$tableName.$columnName should not require insert values');
}

void _seedSchemaV1Database(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('''
      CREATE TABLE products (
        id TEXT NOT NULL PRIMARY KEY,
        company TEXT NOT NULL,
        category TEXT NOT NULL,
        item_name TEXT NOT NULL,
        item_code TEXT NOT NULL UNIQUE,
        buying_price_excl_tax TEXT NULL,
        buying_gst_rate TEXT NULL,
        default_selling_price_excl_tax TEXT NOT NULL,
        default_gst_rate TEXT NOT NULL,
        quantity_on_hand TEXT NOT NULL,
        low_stock_threshold TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (company, category, item_name)
      )
    ''');
    database.execute('''
      CREATE TABLE stock_movements (
        id TEXT NOT NULL PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id)
      )
    ''');
    database.execute('''
      INSERT INTO products (
        id, company, category, item_name, item_code,
        buying_price_excl_tax, buying_gst_rate,
        default_selling_price_excl_tax, default_gst_rate,
        quantity_on_hand, low_stock_threshold, is_active, created_at, updated_at
      ) VALUES
        (
          'product-1', 'Acme', 'Pens', 'Blue Pen', 'PEN-1',
          '80', '5', '100', '18', '7.500', '2.000', 1,
          '2026-01-01T00:00:00.000Z', '2026-01-02T00:00:00.000Z'
        ),
        (
          'product-2', 'Acme', 'Books', 'Ledger Book', 'BOOK-1',
          NULL, NULL, '50', '12', '3.250', '1.000', 0,
          '2026-01-03T00:00:00.000Z', '2026-01-04T00:00:00.000Z'
        ),
        (
          'product-3', 'Beta', 'Pens', 'Red Pen', 'PEN-2',
          '80', NULL, '100', '18', '4.000', '1.000', 1,
          '2026-01-05T00:00:00.000Z', '2026-01-06T00:00:00.000Z'
        )
    ''');
    database.execute(
      "INSERT INTO stock_movements (id, product_id) VALUES ('movement-1', 'product-1')",
    );
    database.execute('PRAGMA user_version = 1');
  } finally {
    database.dispose();
  }
}
