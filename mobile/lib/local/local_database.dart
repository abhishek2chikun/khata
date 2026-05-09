import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'local_database_connection.dart';

part 'local_database.g.dart';

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get passwordHash => text()();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get salt => text()();
  IntColumn get passwordHashVersion => integer()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {username},
      ];
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get itemNumber => text()();
  TextColumn get itemName => text()();
  TextColumn get category => text()();
  TextColumn get buyerId => text().nullable()();
  TextColumn get companyName => text()();
  TextColumn get buyingPrice => text()();
  TextColumn get sellingPrice => text()();
  TextColumn get unit => text().nullable()();
  TextColumn get gstRate => text()();
  TextColumn get quantityOnHand => text()();
  TextColumn get lowStockThreshold => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {itemNumber},
        {companyName, itemName, category},
      ];
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get state => text().nullable()();
  TextColumn get stateCode => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get gstin => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {name, phone},
      ];
}

class Buyers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get state => text().nullable()();
  TextColumn get stateCode => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get gstin => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {name, phone},
      ];
}

class CompanyProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get city => text()();
  TextColumn get state => text()();
  TextColumn get stateCode => text()();
  TextColumn get gstin => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccount => text().nullable()();
  TextColumn get bankIfsc => text().nullable()();
  TextColumn get bankBranch => text().nullable()();
  TextColumn get jurisdiction => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text()();
  TextColumn get requestHash => text()();
  IntColumn get invoiceNumber => integer()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get customerName => text()();
  TextColumn get customerAddress => text()();
  TextColumn get customerState => text().nullable()();
  TextColumn get customerStateCode => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerGstin => text().nullable()();
  TextColumn get placeOfSupplyState => text()();
  TextColumn get placeOfSupplyStateCode => text()();
  TextColumn get companyName => text()();
  TextColumn get companyAddress => text()();
  TextColumn get companyCity => text()();
  TextColumn get companyState => text()();
  TextColumn get companyStateCode => text()();
  TextColumn get companyGstin => text().nullable()();
  TextColumn get companyPhone => text().nullable()();
  TextColumn get companyEmail => text().nullable()();
  TextColumn get companyBankName => text().nullable()();
  TextColumn get companyBankAccount => text().nullable()();
  TextColumn get companyBankIfsc => text().nullable()();
  TextColumn get companyBankBranch => text().nullable()();
  TextColumn get companyJurisdiction => text().nullable()();
  TextColumn get invoiceDate => text()();
  TextColumn get invoiceDatetime =>
      text().customConstraint("NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'")();
  TextColumn get taxRegime => text()();
  TextColumn get status => text()();
  TextColumn get paymentState => text().customConstraint(
      "NOT NULL DEFAULT 'CREDIT' CHECK (payment_state IN ('CREDIT','TOTAL_PAID','PARTIAL_PAID'))")();
  TextColumn get paidAmount =>
      text().customConstraint("NOT NULL DEFAULT '0'")();
  TextColumn get paymentMode => text()();
  TextColumn get subtotal => text()();
  TextColumn get discountTotal => text()();
  TextColumn get taxableTotal => text()();
  TextColumn get gstTotal => text()();
  TextColumn get grandTotal => text()();
  TextColumn get notes => text().nullable()();
  @ReferenceName('createdInvoices')
  TextColumn get createdByUserId => text().references(LocalUsers, #id)();
  TextColumn get cancelRequestId => text().nullable()();
  TextColumn get cancelRequestHash => text().nullable()();
  @ReferenceName('canceledInvoices')
  TextColumn get canceledByUserId =>
      text().nullable().references(LocalUsers, #id)();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get canceledAt => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {requestId},
        {invoiceNumber},
        {cancelRequestId},
      ];
}

class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get invoiceId => text().nullable().references(Invoices, #id)();
  TextColumn get requestId => text().nullable()();
  TextColumn get requestHash => text().nullable()();
  TextColumn get movementType => text()();
  TextColumn get quantityDelta => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get createdByUserId => text().references(LocalUsers, #id)();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CustomerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get invoiceId => text().nullable().references(Invoices, #id)();
  TextColumn get requestId => text().nullable()();
  TextColumn get requestHash => text().nullable()();
  TextColumn get openingBalanceCustomerId => text().nullable()();
  TextColumn get entryType => text()();
  TextColumn get amount => text()();
  TextColumn get occurredOn => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdByUserId => text().references(LocalUsers, #id)();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {requestId},
        {openingBalanceCustomerId},
      ];
}

class BuyerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get buyerId => text().references(Buyers, #id)();
  TextColumn get requestId => text().nullable()();
  TextColumn get requestHash => text().nullable()();
  TextColumn get openingPayableBuyerId => text().nullable()();
  TextColumn get entryType => text()();
  TextColumn get amount => text()();
  TextColumn get occurredAt => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdByUserId => text().references(LocalUsers, #id)();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {requestId},
        {openingPayableBuyerId},
      ];
}

class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get lineNumber => integer()();
  TextColumn get productName => text()();
  TextColumn get productCode => text()();
  TextColumn get productItemNumber => text().withDefault(const Constant(''))();
  TextColumn get productItemName => text().withDefault(const Constant(''))();
  TextColumn get productCategory => text().withDefault(const Constant(''))();
  TextColumn get productBuyerId => text().nullable()();
  TextColumn get productCompanyName => text().withDefault(const Constant(''))();
  TextColumn get buyingPrice => text().withDefault(const Constant(''))();
  TextColumn get sellingPrice => text().withDefault(const Constant(''))();
  TextColumn get unit => text().nullable()();
  TextColumn get company => text()();
  TextColumn get category => text()();
  TextColumn get quantity => text()();
  TextColumn get pricingMode => text()();
  TextColumn get enteredUnitPrice => text()();
  TextColumn get unitPriceExclTax => text()();
  TextColumn get unitPriceInclTax => text()();
  TextColumn get gstRate => text()();
  TextColumn get cgstRate => text()();
  TextColumn get sgstRate => text()();
  TextColumn get igstRate => text()();
  TextColumn get discountPercent => text()();
  TextColumn get discountAmount => text()();
  TextColumn get taxableAmount => text()();
  TextColumn get gstAmount => text()();
  TextColumn get cgstAmount => text()();
  TextColumn get sgstAmount => text()();
  TextColumn get igstAmount => text()();
  TextColumn get lineTotal => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSessions extends Table {
  TextColumn get id => text()();
  TextColumn get localUserId => text().references(LocalUsers, #id)();
  TextColumn get sessionTokenHash => text()();
  TextColumn get refreshTokenHash => text()();
  TextColumn get createdAt => text()();
  TextColumn get expiresAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BackupEvents extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get status => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get message => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BackupSettings extends Table {
  TextColumn get id => text()();
  TextColumn get backupDirectory => text().nullable()();
  BoolColumn get automaticBackupsEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get dailyBackupTime =>
      text().withDefault(const Constant('00:00'))();
  TextColumn get lastBackupAt => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  LocalUsers,
  Products,
  StockMovements,
  Customers,
  CustomerTransactions,
  Buyers,
  BuyerTransactions,
  CompanyProfiles,
  Invoices,
  InvoiceItems,
  LocalSessions,
  BackupEvents,
  BackupSettings,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(openLocalDatabaseConnection());

  LocalDatabase.memory() : super(NativeDatabase.memory());

  LocalDatabase.forConnection(super.connection);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement('PRAGMA foreign_keys = OFF');
            await customStatement('''
              CREATE TABLE products_v2 (
                id TEXT NOT NULL PRIMARY KEY,
                item_number TEXT NOT NULL UNIQUE,
                item_name TEXT NOT NULL,
                category TEXT NOT NULL,
                buyer_id TEXT NULL,
                company_name TEXT NOT NULL,
                buying_price TEXT NOT NULL,
                selling_price TEXT NOT NULL,
                unit TEXT NULL,
                gst_rate TEXT NOT NULL,
                quantity_on_hand TEXT NOT NULL,
                low_stock_threshold TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE (company_name, item_name, category)
              )
            ''');
            await customStatement('''
              INSERT INTO products_v2 (
                id,
                item_number,
                item_name,
                category,
                buyer_id,
                company_name,
                buying_price,
                selling_price,
                unit,
                gst_rate,
                quantity_on_hand,
                low_stock_threshold,
                is_active,
                created_at,
                updated_at
              )
              SELECT
                id,
                item_code,
                item_name,
                category,
                NULL,
                company,
                RTRIM(RTRIM(CAST(
                  ROUND(
                    CAST(COALESCE(buying_price_excl_tax, '0') AS REAL)
                    * (1 + CAST(COALESCE(buying_gst_rate, '0') AS REAL) / 100),
                    2
                  ) AS TEXT
                ), '0'), '.'),
                RTRIM(RTRIM(CAST(
                  ROUND(
                    CAST(default_selling_price_excl_tax AS REAL)
                    * (1 + CAST(default_gst_rate AS REAL) / 100),
                    2
                  ) AS TEXT
                ), '0'), '.'),
                NULL,
                default_gst_rate,
                quantity_on_hand,
                low_stock_threshold,
                is_active,
                created_at,
                updated_at
              FROM products
            ''');
            await customStatement('DROP TABLE products');
            await customStatement('ALTER TABLE products_v2 RENAME TO products');
            await customStatement('PRAGMA foreign_keys = ON');
          }
          if (from < 3) {
            await m.createTable(buyers);
            await m.createTable(buyerTransactions);
          }
          if (from < 4) {
            await customStatement('PRAGMA foreign_keys = OFF');
            if (await _tableExists('sellers')) {
              await customStatement('ALTER TABLE sellers RENAME TO customers');
            }
            if (await _tableExists('seller_transactions')) {
              await customStatement(
                  'ALTER TABLE seller_transactions RENAME TO customer_transactions');
            }
            if (await _columnExists('customer_transactions', 'seller_id')) {
              await customStatement(
                  'ALTER TABLE customer_transactions RENAME COLUMN seller_id TO customer_id');
            }
            if (await _columnExists(
                'customer_transactions', 'opening_balance_seller_id')) {
              await customStatement(
                  'ALTER TABLE customer_transactions RENAME COLUMN opening_balance_seller_id TO opening_balance_customer_id');
            }
            if (await _columnExists('invoices', 'seller_id')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_id TO customer_id');
            }
            if (await _columnExists('invoices', 'seller_name')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_name TO customer_name');
            }
            if (await _columnExists('invoices', 'seller_address')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_address TO customer_address');
            }
            if (await _columnExists('invoices', 'seller_state')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_state TO customer_state');
            }
            if (await _columnExists('invoices', 'seller_state_code')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_state_code TO customer_state_code');
            }
            if (await _columnExists('invoices', 'seller_phone')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_phone TO customer_phone');
            }
            if (await _columnExists('invoices', 'seller_gstin')) {
              await customStatement(
                  'ALTER TABLE invoices RENAME COLUMN seller_gstin TO customer_gstin');
            }
            if (await _tableExists('customer_transactions')) {
              await customStatement(
                  "UPDATE customer_transactions SET entry_type = 'COLLECTION' WHERE entry_type = 'PAYMENT'");
            }
            await customStatement('PRAGMA foreign_keys = ON');
          }
          if (from < 5) {
            if (await _tableExists('invoices')) {
              await m.addColumn(invoices, invoices.invoiceDatetime);
              await m.addColumn(invoices, invoices.paymentState);
              await m.addColumn(invoices, invoices.paidAmount);
              await customStatement(
                  "UPDATE invoices SET invoice_datetime = invoice_date || 'T00:00:00.000Z' WHERE invoice_datetime = '1970-01-01T00:00:00.000Z'");
              await customStatement(
                  "UPDATE invoices SET payment_state = CASE WHEN payment_mode = 'PAID' THEN 'TOTAL_PAID' WHEN payment_mode = 'TOTAL_PAID' THEN 'TOTAL_PAID' WHEN payment_mode = 'PARTIAL_PAID' THEN 'PARTIAL_PAID' ELSE 'CREDIT' END WHERE payment_state = 'CREDIT'");
              await customStatement(
                  "UPDATE invoices SET paid_amount = CASE WHEN payment_state = 'TOTAL_PAID' THEN grand_total ELSE '0' END WHERE paid_amount = '0'");
            }
            if (await _tableExists('invoice_items')) {
              await m.addColumn(invoiceItems, invoiceItems.productItemNumber);
              await m.addColumn(invoiceItems, invoiceItems.productItemName);
              await m.addColumn(invoiceItems, invoiceItems.productCategory);
              await m.addColumn(invoiceItems, invoiceItems.productBuyerId);
              await m.addColumn(invoiceItems, invoiceItems.productCompanyName);
              await m.addColumn(invoiceItems, invoiceItems.buyingPrice);
              await m.addColumn(invoiceItems, invoiceItems.sellingPrice);
              await m.addColumn(invoiceItems, invoiceItems.unit);
              await customStatement(
                  "UPDATE invoice_items SET product_item_number = product_code WHERE product_item_number = ''");
              await customStatement(
                  "UPDATE invoice_items SET product_item_name = product_name WHERE product_item_name = ''");
              await customStatement(
                  "UPDATE invoice_items SET product_category = category WHERE product_category = ''");
              await customStatement(
                  "UPDATE invoice_items SET product_company_name = company WHERE product_company_name = ''");
              await customStatement(
                  "UPDATE invoice_items SET buying_price = '0' WHERE buying_price = ''");
              await customStatement(
                  "UPDATE invoice_items SET selling_price = unit_price_incl_tax WHERE selling_price = ''");
            }
          }
        },
        beforeOpen: (_) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<bool> _tableExists(String tableName) async {
    final result = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: <Variable<Object>>[Variable<String>(tableName)],
    ).get();
    return result.isNotEmpty;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    if (!await _tableExists(tableName)) {
      return false;
    }
    final result = await customSelect('PRAGMA table_info($tableName)').get();
    return result.any((row) => row.read<String>('name') == columnName);
  }
}
