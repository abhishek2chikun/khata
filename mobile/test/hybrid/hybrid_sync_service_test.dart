import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_sync_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;

void main() {
  test('clearBusinessCache removes business rows', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final now = DateTime.utc(2026, 1, 1).toIso8601String();

    await database.into(database.products).insert(
          db.ProductsCompanion.insert(
            id: 'product-1',
            itemNumber: 'P-1',
            itemName: 'Widget',
            category: 'General',
            companyName: 'Acme',
            buyingPrice: '10.000',
            sellingPrice: '12.000',
            gstRate: '18.00',
            quantityOnHand: '5',
            lowStockThreshold: '0',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repository.clearBusinessCache();

    final products = await database.select(database.products).get();
    expect(products, isEmpty);
  });

  test('initializeHybridCacheIfNeeded clears stale cache once', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final now = DateTime.utc(2026, 1, 1).toIso8601String();

    await database.into(database.products).insert(
          db.ProductsCompanion.insert(
            id: 'stale-product',
            itemNumber: 'P-OLD',
            itemName: 'Stale',
            category: 'General',
            companyName: 'Acme',
            buyingPrice: '10.000',
            sellingPrice: '12.000',
            gstRate: '18.00',
            quantityOnHand: '1',
            lowStockThreshold: '0',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(await repository.isHybridInitialized(), isFalse);

    await repository.clearBusinessCache();
    await repository.markHybridInitialized();

    expect(await repository.isHybridInitialized(), isTrue);
    final products = await database.select(database.products).get();
    expect(products, isEmpty);
  });

  test('hybrid cache settings survive business cache clear', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final timestamp = DateTime.utc(2026, 6, 18).toIso8601String();

    await repository.markHybridInitialized(lastSyncedAt: timestamp);
    await repository.clearBusinessCache();

    final settings = await (database.select(database.hybridCacheSettings)
          ..where((row) => row.id.equals(HybridCacheRepository.hybridSettingsId)))
        .getSingleOrNull();

    expect(settings?.initialized, isTrue);
    expect(settings?.lastSyncedAt, timestamp);
  });
}
