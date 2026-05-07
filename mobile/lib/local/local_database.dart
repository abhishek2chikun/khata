import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'local_database_connection.dart';

part 'local_database.g.dart';

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get gstRate => text().nullable()();
  TextColumn get salePrice => text().nullable()();
  TextColumn get purchasePrice => text().nullable()();
  TextColumn get currentStock => text().withDefault(const Constant('0'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get movementType => text()();
  TextColumn get quantity => text()();
  TextColumn get note => text().nullable()();
  TextColumn get occurredAt => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Sellers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get balance => text().withDefault(const Constant('0'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SellerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get sellerId => text()();
  TextColumn get transactionType => text()();
  TextColumn get amount => text()();
  TextColumn get note => text().nullable()();
  TextColumn get occurredAt => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CompanyProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get sellerId => text().nullable()();
  TextColumn get invoiceNumber => text()();
  TextColumn get invoiceDate => text()();
  TextColumn get subtotal => text()();
  TextColumn get gstTotal => text()();
  TextColumn get grandTotal => text()();
  TextColumn get status => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get description => text()();
  TextColumn get quantity => text()();
  TextColumn get unitPrice => text()();
  TextColumn get gstRate => text()();
  TextColumn get lineTotal => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSessions extends Table {
  TextColumn get id => text()();
  TextColumn get localUserId => text()();
  TextColumn get sessionTokenHash => text()();
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
  TextColumn get automaticBackupsEnabled => text().withDefault(const Constant('false'))();
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
}
