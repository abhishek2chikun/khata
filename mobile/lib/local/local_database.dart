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
  TextColumn get company => text()();
  TextColumn get category => text()();
  TextColumn get itemName => text()();
  TextColumn get itemCode => text()();
  TextColumn get buyingPriceExclTax => text().nullable()();
  TextColumn get buyingGstRate => text().nullable()();
  TextColumn get defaultSellingPriceExclTax => text()();
  TextColumn get defaultGstRate => text()();
  TextColumn get quantityOnHand => text()();
  TextColumn get lowStockThreshold => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {company, category, itemName},
        {itemCode},
      ];
}

class Sellers extends Table {
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
  TextColumn get sellerId => text().references(Sellers, #id)();
  TextColumn get sellerName => text()();
  TextColumn get sellerAddress => text()();
  TextColumn get sellerState => text().nullable()();
  TextColumn get sellerStateCode => text().nullable()();
  TextColumn get sellerPhone => text().nullable()();
  TextColumn get sellerGstin => text().nullable()();
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
  TextColumn get taxRegime => text()();
  TextColumn get status => text()();
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

class SellerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get sellerId => text().references(Sellers, #id)();
  TextColumn get invoiceId => text().nullable().references(Invoices, #id)();
  TextColumn get requestId => text().nullable()();
  TextColumn get requestHash => text().nullable()();
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
      ];
}

class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get lineNumber => integer()();
  TextColumn get productName => text()();
  TextColumn get productCode => text()();
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
  TextColumn get lastBackupAt => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  LocalUsers,
  Products,
  StockMovements,
  Sellers,
  SellerTransactions,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
