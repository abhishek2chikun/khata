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

    expect(database.schemaVersion, 11);
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
          'hybrid_cache_settings',
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
          'hsn_code',
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
          'whatsapp_number',
        ]));
    expect(
        _columnNames(database, 'buyers'),
        containsAll(<String>[
          'state',
          'state_code',
          'is_active',
          'whatsapp_number',
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
          'gst_flag',
        ]));
    expect(
        _columnNames(database, 'invoices'),
        containsAll(<String>[
          'request_id',
          'request_hash',
          'customer_name',
          'customer_state_code',
          'company_bank_ifsc',
          'gst_flag',
          'invoice_datetime',
          'tax_regime',
          'payment_state',
          'paid_amount',
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
          'product_item_number',
          'product_item_name',
          'product_category',
          'product_buyer_id',
          'product_company_name',
          'product_hsn_code',
          'buying_price',
          'selling_price',
          'unit',
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
          'hsn_code',
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
    _expectGeneratedRequired(database, 'invoices', 'invoice_datetime');
    _expectGeneratedRequired(database, 'invoices', 'payment_state');
    _expectGeneratedRequired(database, 'invoices', 'paid_amount');
    _expectRequired(database, 'invoices', 'payment_mode');
    expect(_column(database, 'invoices', 'invoice_number'),
        isA<GeneratedColumn<int>>());

    _expectNullable(database, 'stock_movements', 'request_id');
    _expectNullable(database, 'stock_movements', 'request_hash');
    _expectNullable(database, 'customer_transactions', 'request_id');
    _expectNullable(database, 'customer_transactions', 'request_hash');

    _expectRequired(database, 'invoice_items', 'product_code');
    _expectGeneratedRequired(database, 'invoice_items', 'product_item_number');
    _expectGeneratedRequired(database, 'invoice_items', 'product_item_name');
    _expectGeneratedRequired(database, 'invoice_items', 'product_category');
    _expectNullable(database, 'invoice_items', 'product_buyer_id');
    _expectGeneratedRequired(database, 'invoice_items', 'product_company_name');
    _expectGeneratedRequired(database, 'invoice_items', 'buying_price');
    _expectGeneratedRequired(database, 'invoice_items', 'selling_price');
    _expectNullable(database, 'invoice_items', 'unit');
    _expectRequired(database, 'invoice_items', 'company');
    _expectRequired(database, 'invoice_items', 'category');
  });

  test('payment state columns use safe defaults and constraints', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await database.into(database.localUsers).insert(
          LocalUsersCompanion.insert(
            id: 'local-system-user',
            username: 'system',
            passwordHash: 'hash',
            salt: 'salt',
            passwordHashVersion: 1,
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );
    await database.into(database.customers).insert(
          CustomersCompanion.insert(
            id: 'customer-1',
            name: 'Acme Stores',
            address: '1 Market Road',
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );
    await database.into(database.invoices).insert(
          InvoicesCompanion.insert(
            id: 'invoice-default-payment-state',
            requestId: 'request-default-payment-state',
            requestHash: 'hash',
            invoiceNumber: 99,
            customerId: 'customer-1',
            customerName: 'Acme Stores',
            customerAddress: '1 Market Road',
            placeOfSupplyState: 'Maharashtra',
            placeOfSupplyStateCode: '27',
            companyName: 'Khata Traders',
            companyAddress: '10 Market Road',
            companyCity: 'Mumbai',
            companyState: 'Maharashtra',
            companyStateCode: '27',
            invoiceDate: '2026-01-10',
            taxRegime: 'INTRA_STATE',
            status: 'ACTIVE',
            paymentMode: 'CREDIT',
            subtotal: '100',
            discountTotal: '0',
            taxableTotal: '100',
            gstTotal: '18',
            grandTotal: '118',
            createdByUserId: 'local-system-user',
            createdAt: '2026-01-10T00:00:00.000Z',
          ),
        );
    final defaulted = await (database.select(database.invoices)
          ..where(
              (invoice) => invoice.id.equals('invoice-default-payment-state')))
        .getSingle();
    expect(defaulted.paymentState, 'CREDIT');
    expect(defaulted.paidAmount, '0');
    final invalidInsert = database.into(database.invoices).insert(
          InvoicesCompanion.insert(
            id: 'invoice-invalid-payment-state',
            requestId: 'request-invalid-payment-state',
            requestHash: 'hash',
            invoiceNumber: 1,
            customerId: 'missing-customer',
            customerName: 'Acme Stores',
            customerAddress: '1 Market Road',
            placeOfSupplyState: 'Maharashtra',
            placeOfSupplyStateCode: '27',
            companyName: 'Khata Traders',
            companyAddress: '10 Market Road',
            companyCity: 'Mumbai',
            companyState: 'Maharashtra',
            companyStateCode: '27',
            invoiceDate: '2026-01-10',
            taxRegime: 'INTRA_STATE',
            status: 'ACTIVE',
            paymentState: const Value('CASH'),
            paidAmount: const Value('0'),
            paymentMode: 'CASH',
            subtotal: '100',
            discountTotal: '0',
            taxableTotal: '100',
            gstTotal: '18',
            grandTotal: '118',
            createdByUserId: 'missing-user',
            createdAt: '2026-01-10T00:00:00.000Z',
          ),
        );
    await expectLater(
      () => invalidInsert,
      throwsA(predicate((Object error) =>
          error.toString().contains('payment_state') ||
          error.toString().contains('CHECK constraint failed'))),
    );
  });

  test('invoice payment state constraints reject invalid paid amounts',
      () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await database.into(database.localUsers).insert(
          LocalUsersCompanion.insert(
            id: 'local-system-user',
            username: 'system',
            passwordHash: 'hash',
            salt: 'salt',
            passwordHashVersion: 1,
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );
    await database.into(database.customers).insert(
          CustomersCompanion.insert(
            id: 'customer-1',
            name: 'Acme Stores',
            address: '1 Market Road',
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );

    Future<void> expectRejected({
      required String id,
      required String paymentState,
      required String paidAmount,
      String grandTotal = '118',
    }) async {
      await expectLater(
        () => database.customStatement(
          """
          INSERT INTO invoices (
            id, request_id, request_hash, invoice_number, customer_id,
            customer_name, customer_address, place_of_supply_state,
            place_of_supply_state_code, company_name, company_address,
            company_city, company_state, company_state_code, invoice_date,
            tax_regime, status, payment_state, paid_amount, payment_mode,
            subtotal, discount_total, taxable_total, gst_total, grand_total,
            created_by_user_id, created_at
          ) VALUES (
            '$id', 'request-$id', 'hash', ${id.hashCode.abs()}, 'customer-1',
            'Acme Stores', '1 Market Road', 'Maharashtra', '27',
            'Khata Traders', '10 Market Road', 'Mumbai', 'Maharashtra', '27',
            '2026-01-10', 'INTRA_STATE', 'ACTIVE', '$paymentState',
            '$paidAmount', '$paymentState', '100', '0', '100', '18',
            '$grandTotal', 'local-system-user', '2026-01-10T00:00:00.000Z'
          )
          """,
        ),
        throwsA(predicate((Object error) =>
            error.toString().contains('CHECK constraint failed'))),
      );
    }

    await expectRejected(
        id: 'negative-paid', paymentState: 'PARTIAL_PAID', paidAmount: '-1');
    await expectRejected(
        id: 'credit-paid', paymentState: 'CREDIT', paidAmount: '1');
    await expectRejected(
        id: 'total-underpaid', paymentState: 'TOTAL_PAID', paidAmount: '117');
    await expectRejected(
        id: 'partial-zero', paymentState: 'PARTIAL_PAID', paidAmount: '0');
    await expectRejected(
        id: 'partial-full', paymentState: 'PARTIAL_PAID', paidAmount: '118');
    await expectRejected(
        id: 'malformed-paid', paymentState: 'CREDIT', paidAmount: 'abc');
  });

  test('migration normalizes unknown legacy payment modes to CREDIT', () async {
    final directory = await Directory.systemTemp.createTemp('khata-v4-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/local.sqlite');
    _seedSchemaV4InvoiceDatabase(file, paymentMode: 'CASH');

    final database = LocalDatabase.forConnection(NativeDatabase(file));
    addTearDown(database.close);

    final invoice = await database.select(database.invoices).getSingle();
    expect(invoice.paymentState, 'CREDIT');
    expect(invoice.paidAmount, '0');
    expect(invoice.invoiceDatetime, '2026-01-10T00:00:00.000Z');
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
          product_item_number,
          product_item_name,
          product_category,
          product_buyer_id,
          product_company_name,
          buying_price,
          selling_price,
          unit,
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
          'MISSING-1',
          'Missing Product',
          'Missing Category',
          NULL,
          'Missing Company',
          '8',
          '11.8',
          NULL,
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

void _expectGeneratedRequired(
    LocalDatabase database, String tableName, String columnName) {
  final column = _column(database, tableName, columnName);
  expect(column.$nullable, isFalse,
      reason: '$tableName.$columnName should be NOT NULL');
  expect(column.requiredDuringInsert, isFalse,
      reason:
          '$tableName.$columnName should have a generated migration default');
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

void _seedSchemaV4InvoiceDatabase(File file, {required String paymentMode}) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('''
      CREATE TABLE local_users (
        id TEXT NOT NULL PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NULL,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        salt TEXT NOT NULL,
        password_hash_version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE customers (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        state TEXT NULL,
        state_code TEXT NULL,
        phone TEXT NULL,
        gstin TEXT NULL,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE invoices (
        id TEXT NOT NULL PRIMARY KEY,
        request_id TEXT NOT NULL UNIQUE,
        request_hash TEXT NOT NULL,
        invoice_number INTEGER NOT NULL UNIQUE,
        customer_id TEXT NOT NULL REFERENCES customers(id),
        customer_name TEXT NOT NULL,
        customer_address TEXT NOT NULL,
        customer_state TEXT NULL,
        customer_state_code TEXT NULL,
        customer_phone TEXT NULL,
        customer_gstin TEXT NULL,
        place_of_supply_state TEXT NOT NULL,
        place_of_supply_state_code TEXT NOT NULL,
        company_name TEXT NOT NULL,
        company_address TEXT NOT NULL,
        company_city TEXT NOT NULL,
        company_state TEXT NOT NULL,
        company_state_code TEXT NOT NULL,
        company_gstin TEXT NULL,
        company_phone TEXT NULL,
        company_email TEXT NULL,
        company_bank_name TEXT NULL,
        company_bank_account TEXT NULL,
        company_bank_ifsc TEXT NULL,
        company_bank_branch TEXT NULL,
        company_jurisdiction TEXT NULL,
        invoice_date TEXT NOT NULL,
        tax_regime TEXT NOT NULL,
        status TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        subtotal TEXT NOT NULL,
        discount_total TEXT NOT NULL,
        taxable_total TEXT NOT NULL,
        gst_total TEXT NOT NULL,
        grand_total TEXT NOT NULL,
        notes TEXT NULL,
        created_by_user_id TEXT NOT NULL REFERENCES local_users(id),
        cancel_request_id TEXT NULL UNIQUE,
        cancel_request_hash TEXT NULL,
        canceled_by_user_id TEXT NULL REFERENCES local_users(id),
        cancel_reason TEXT NULL,
        canceled_at TEXT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      INSERT INTO local_users (
        id, username, password_hash, display_name, is_active, salt,
        password_hash_version, created_at, updated_at
      ) VALUES (
        'local-system-user', 'system', 'hash', 'System', 1, 'salt', 1,
        '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'
      )
    ''');
    database.execute('''
      INSERT INTO customers (
        id, name, address, state, state_code, phone, gstin, is_active,
        created_at, updated_at
      ) VALUES (
        'customer-1', 'Acme Stores', '1 Market Road', 'Maharashtra', '27',
        '9999999999', NULL, 1,
        '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'
      )
    ''');
    database.execute('''
      INSERT INTO invoices (
        id, request_id, request_hash, invoice_number, customer_id,
        customer_name, customer_address, customer_state, customer_state_code,
        customer_phone, customer_gstin, place_of_supply_state,
        place_of_supply_state_code, company_name, company_address, company_city,
        company_state, company_state_code, company_gstin, company_phone,
        company_email, company_bank_name, company_bank_account,
        company_bank_ifsc, company_bank_branch, company_jurisdiction,
        invoice_date, tax_regime, status, payment_mode, subtotal,
        discount_total, taxable_total, gst_total, grand_total, notes,
        created_by_user_id, cancel_request_id, cancel_request_hash,
        canceled_by_user_id, cancel_reason, canceled_at, created_at
      ) VALUES (
        'invoice-1', 'request-1', 'hash', 1, 'customer-1',
        'Acme Stores', '1 Market Road', 'Maharashtra', '27',
        '9999999999', NULL, 'Maharashtra', '27', 'Khata Traders',
        '10 Market Road', 'Mumbai', 'Maharashtra', '27', NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-10', 'INTRA_STATE',
        'ACTIVE', '$paymentMode', '100', '0', '100', '18', '118', NULL,
        'local-system-user', NULL, NULL, NULL, NULL, NULL,
        '2026-01-10T00:00:00.000Z'
      )
    ''');
    database.execute('PRAGMA user_version = 4');
  } finally {
    database.dispose();
  }
}
