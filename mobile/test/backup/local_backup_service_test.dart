import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/backup/backup_crypto.dart';
import 'package:internal_billing_khata_mobile/backup/backup_models.dart';
import 'package:internal_billing_khata_mobile/backup/local_backup_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('exports and imports encrypted local tables with exact decimal and IDs',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source);

    final package = await LocalBackupService(database: source).exportEncrypted(
      password: 'backup-password',
    );
    final payload = LocalBackupPayload.decode(
      await BackupCrypto()
          .decrypt(package: package, password: 'backup-password'),
    );

    expect(package.version, LocalBackupPackage.currentVersion);
    expect(payload.schemaVersion, 3);
    expect(payload.tables, contains('buyers'));
    expect(payload.tables, contains('buyer_transactions'));
    expect(package.payloadCiphertext, isNot(contains('product-0001')));
    expect(package.payloadCiphertext, isNot(contains('123.4500')));

    await LocalBackupService(database: target).importEncrypted(
      package: package,
      password: 'backup-password',
    );

    final products = await target.select(target.products).get();
    final sellers = await target.select(target.sellers).get();
    final invoices = await target.select(target.invoices).get();
    final items = await target.select(target.invoiceItems).get();
    final buyers = await target.select(target.buyers).get();
    final buyerTransactions =
        await target.select(target.buyerTransactions).get();

    expect(products.single.id, 'product-0001');
    expect(products.single.itemNumber, 'PEN-product-0001');
    expect(products.single.companyName, 'Acme');
    expect(products.single.buyingPrice, '99.9900');
    expect(products.single.sellingPrice, '123.4500');
    expect(products.single.unit, 'box');
    expect(products.single.gstRate, '18.000');
    expect(products.single.quantityOnHand, '7.500');
    expect(sellers.single.id, 'seller-0001');
    expect(invoices.single.id, 'invoice-0001');
    expect(invoices.single.grandTotal, '145.6710');
    expect(items.single.id, 'invoice-item-0001');
    expect(items.single.quantity, '1.250');
    expect(buyers.single.id, 'buyer-0001');
    expect(buyerTransactions.single.buyerId, 'buyer-0001');
    expect(buyerTransactions.single.amount, '123.45');
  });

  test('import clears and restores buyer ledger tables before local users',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedRoundTripData(target, productId: 'target-product');

    final package = await LocalBackupService(database: source).exportEncrypted(
      password: 'backup-password',
    );

    await LocalBackupService(database: target).importEncrypted(
      package: package,
      password: 'backup-password',
    );

    final buyers = await target.select(target.buyers).get();
    final buyerTransactions =
        await target.select(target.buyerTransactions).get();
    expect(buyers.map((buyer) => buyer.id), <String>['buyer-0001']);
    expect(buyerTransactions.map((transaction) => transaction.id),
        <String>['buyer-transaction-0001']);
    expect((await target.select(target.localUsers).get()).single.username,
        'system-source-product');
  });

  test('rejects unsupported schema versions before replacing existing data',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'existing-product');

    final service = LocalBackupService(database: target);
    await _seedRoundTripData(target, productId: 'target-product');
    final package = await LocalBackupService(database: source).exportEncrypted(
      password: 'backup-password',
      schemaVersion: LocalBackupPayload.currentSchemaVersion + 1,
    );

    await expectLater(
      () => service.importEncrypted(
        package: package,
        password: 'backup-password',
      ),
      throwsA(isA<UnsupportedBackupVersionException>()),
    );

    final products = await target.select(target.products).get();
    expect(products.single.id, 'target-product');
  });

  test('rejects backend compatibility mismatches before replacing data',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedRoundTripData(target, productId: 'target-product');

    final package = await _tamperPayloadPackage(
      database: source,
      password: 'backup-password',
      mutate: (payload) {
        payload['backend_compatibility_version'] = 'future-local-v2';
      },
    );

    await expectLater(
      () => LocalBackupService(database: target).importEncrypted(
        package: package,
        password: 'backup-password',
      ),
      throwsA(isA<UnsupportedBackupVersionException>()),
    );

    final products = await target.select(target.products).get();
    expect(products.single.id, 'target-product');
  });

  test('rejects missing required table payloads before replacing data',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedRoundTripData(target, productId: 'target-product');

    final package = await _tamperPayloadPackage(
      database: source,
      password: 'backup-password',
      mutate: (payload) {
        final tables = payload['tables'] as Map<String, Object?>;
        tables.remove('buyer_transactions');
      },
    );

    await expectLater(
      () => LocalBackupService(database: target).importEncrypted(
        package: package,
        password: 'backup-password',
      ),
      throwsA(isA<InvalidBackupPayloadException>()),
    );

    final products = await target.select(target.products).get();
    expect(products.single.id, 'target-product');
  });

  test('rejects unexpected columns before replacing existing data', () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedRoundTripData(target, productId: 'target-product');

    final package = await _tamperPayloadPackage(
      database: source,
      password: 'backup-password',
      mutate: (payload) {
        final tables = payload['tables'] as Map<String, Object?>;
        final products = tables['products'] as List<Object?>;
        final product = products.single as Map<String, Object?>;
        product['evil_column'] = 'evil';
      },
    );

    await expectLater(
      () => LocalBackupService(database: target).importEncrypted(
        package: package,
        password: 'backup-password',
      ),
      throwsA(isA<InvalidBackupPayloadException>()),
    );

    final products = await target.select(target.products).get();
    expect(products.single.id, 'target-product');
  });

  test('rejects SQL-looking column keys before executing injected SQL',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedRoundTripData(target, productId: 'target-product');

    final package = await _tamperPayloadPackage(
      database: source,
      password: 'backup-password',
      mutate: (payload) {
        final tables = payload['tables'] as Map<String, Object?>;
        final products = tables['products'] as List<Object?>;
        final product = products.single as Map<String, Object?>;
        product['item_name) VALUES (?); DELETE FROM products; --'] = 'evil';
      },
    );

    await expectLater(
      () => LocalBackupService(database: target).importEncrypted(
        package: package,
        password: 'backup-password',
      ),
      throwsA(isA<InvalidBackupPayloadException>()),
    );

    final products = await target.select(target.products).get();
    expect(products.single.id, 'target-product');
  });

  test('does not export sessions and clears existing sessions on import',
      () async {
    final source = db.LocalDatabase.memory();
    final target = db.LocalDatabase.memory();
    addTearDown(source.close);
    addTearDown(target.close);
    await _seedRoundTripData(source, productId: 'source-product');
    await _seedLocalSession(source, id: 'source-session');
    await _seedRoundTripData(target, productId: 'target-product');
    await _seedLocalSession(target, id: 'target-session');

    final package = await LocalBackupService(database: source).exportEncrypted(
      password: 'backup-password',
    );
    final crypto = BackupCrypto();
    final payload = LocalBackupPayload.decode(
      await crypto.decrypt(package: package, password: 'backup-password'),
    );

    expect(payload.tables, isNot(contains('local_sessions')));

    await LocalBackupService(database: target).importEncrypted(
      package: package,
      password: 'backup-password',
    );

    expect(await target.select(target.localSessions).get(), isEmpty);
    expect((await target.select(target.products).get()).single.id,
        'source-product');
  });
}

Future<LocalBackupPackage> _tamperPayloadPackage({
  required db.LocalDatabase database,
  required String password,
  required void Function(Map<String, Object?> payload) mutate,
}) async {
  final service = LocalBackupService(database: database);
  final crypto = BackupCrypto();
  final package = await service.exportEncrypted(password: password);
  final payload = LocalBackupPayload.decode(
    await crypto.decrypt(package: package, password: password),
  ).toJson();
  mutate(payload);
  return crypto.encrypt(
    payloadBytes: utf8.encode(jsonEncode(payload)),
    password: password,
  );
}

Future<void> _seedRoundTripData(
  db.LocalDatabase database, {
  String productId = 'product-0001',
}) async {
  await database.into(database.localUsers).insert(
        db.LocalUsersCompanion.insert(
          id: 'local-system-user',
          username: 'system-$productId',
          passwordHash: 'hash',
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
          displayName: const Value('System'),
        ),
      );
  await database.into(database.products).insert(
        db.ProductsCompanion.insert(
          id: productId,
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-$productId',
          buyingPrice: '99.9900',
          sellingPrice: '123.4500',
          unit: const Value('box'),
          gstRate: '18.000',
          quantityOnHand: '7.500',
          lowStockThreshold: '2.00',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.sellers).insert(
        db.SellersCompanion.insert(
          id: 'seller-0001',
          name: 'Acme Stores $productId',
          address: '1 Market Road',
          state: const Value('Maharashtra'),
          stateCode: const Value('27'),
          phone: Value('9999$productId'),
          gstin: const Value('27ABCDE1234F1Z5'),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.buyers).insert(
        db.BuyersCompanion.insert(
          id: 'buyer-0001',
          name: 'Global Suppliers $productId',
          address: '9 Wholesale Market',
          state: const Value('Maharashtra'),
          stateCode: const Value('27'),
          phone: Value('8888$productId'),
          gstin: const Value('27ABCDE1234F1Z5'),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
  await database.into(database.buyerTransactions).insert(
        db.BuyerTransactionsCompanion.insert(
          id: 'buyer-transaction-0001',
          buyerId: 'buyer-0001',
          requestId: Value('buyer-request-$productId'),
          requestHash: const Value('buyer-request-hash'),
          entryType: 'PURCHASE_AMOUNT',
          amount: '123.45',
          occurredAt: '2026-01-02T10:30:00+05:30',
          notes: const Value('Purchase bill'),
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-02T05:00:00.000Z',
        ),
      );
  await database.into(database.invoices).insert(
        db.InvoicesCompanion.insert(
          id: 'invoice-0001',
          requestId: 'request-$productId',
          requestHash: 'request-hash',
          invoiceNumber: 1,
          sellerId: 'seller-0001',
          sellerName: 'Acme Stores $productId',
          sellerAddress: '1 Market Road',
          sellerState: const Value('Maharashtra'),
          sellerStateCode: const Value('27'),
          sellerPhone: Value('9999$productId'),
          sellerGstin: const Value('27ABCDE1234F1Z5'),
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
          subtotal: '123.4500',
          discountTotal: '0.0000',
          taxableTotal: '123.4500',
          gstTotal: '22.2210',
          grandTotal: '145.6710',
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-10T00:00:00.000Z',
        ),
      );
  await database.into(database.invoiceItems).insert(
        db.InvoiceItemsCompanion.insert(
          id: 'invoice-item-0001',
          invoiceId: 'invoice-0001',
          productId: productId,
          lineNumber: 1,
          productName: 'Blue Pen',
          productCode: 'PEN-$productId',
          company: 'Acme',
          category: 'Pens',
          quantity: '1.250',
          pricingMode: 'PRE_TAX',
          enteredUnitPrice: '123.4500',
          unitPriceExclTax: '123.4500',
          unitPriceInclTax: '145.6710',
          gstRate: '18.000',
          cgstRate: '9.000',
          sgstRate: '9.000',
          igstRate: '0.000',
          discountPercent: '0.000',
          discountAmount: '0.0000',
          taxableAmount: '123.4500',
          gstAmount: '22.2210',
          cgstAmount: '11.1105',
          sgstAmount: '11.1105',
          igstAmount: '0.0000',
          lineTotal: '145.6710',
        ),
      );
}

Future<void> _seedLocalSession(
  db.LocalDatabase database, {
  required String id,
}) {
  return database.into(database.localSessions).insert(
        db.LocalSessionsCompanion.insert(
          id: id,
          localUserId: 'local-system-user',
          sessionTokenHash: 'session-hash-$id',
          refreshTokenHash: 'refresh-hash-$id',
          createdAt: '2026-01-02T00:00:00.000Z',
        ),
      );
}
