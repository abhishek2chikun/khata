import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_sync_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:supabase_flutter/supabase_flutter.dart';

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
          ..where(
              (row) => row.id.equals(HybridCacheRepository.hybridSettingsId)))
        .getSingleOrNull();

    expect(settings?.initialized, isTrue);
    expect(settings?.lastSyncedAt, timestamp);
  });

  test('countActiveProducts returns active local product row count', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final now = DateTime.utc(2026, 1, 1).toIso8601String();

    expect(await repository.countActiveProducts(), 0);

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

    expect(await repository.countActiveProducts(), 1);
  });

  test('syncPaginatedTable fetches all pages until short page', () async {
    final upserted = <Map<String, dynamic>>[];
    var fetchCalls = 0;

    final total = await syncPaginatedTable(
      pageSize: 1000,
      fetchPage: (from, to) async {
        fetchCalls += 1;
        if (from == 0) {
          return List<Map<String, dynamic>>.generate(
            1000,
            (index) => {'id': 'row-$index'},
          );
        }
        if (from == 1000) {
          return List<Map<String, dynamic>>.generate(
            528,
            (index) => {'id': 'row-${index + 1000}'},
          );
        }
        return const <Map<String, dynamic>>[];
      },
      upsert: (row) async {
        upserted.add(row);
      },
    );

    expect(total, 1528);
    expect(fetchCalls, 2);
    expect(upserted.length, 1528);
  });

  test('applyRpcResult hydrates product cache without full sync', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final service = HybridSyncService(
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      cacheRepository: repository,
    );
    final now = DateTime.utc(2026, 6, 19).toIso8601String();

    await service.applyRpcResult('create_product', <String, dynamic>{
      'id': 'product-1',
      'item_number': 'P-1',
      'item_name': 'Widget',
      'category': 'General',
      'buyer_id': null,
      'company_name': 'Acme',
      'buying_price': 10,
      'selling_price': 12,
      'unit': null,
      'gst_rate': 0,
      'hsn_code': null,
      'quantity_on_hand': 8,
      'low_stock_threshold': 1,
      'is_active': true,
      'created_at': now,
      'updated_at': now,
    });

    final products = await database.select(database.products).get();
    expect(products.single.id, 'product-1');
    expect(products.single.quantityOnHand, '8');
  });

  test('batchCollectionNotesFilter matches RPC batch marker format', () {
    expect(
      batchCollectionNotesFilter('550e8400-e29b-41d4-a716-446655440000'),
      '__batch__|550e8400-e29b-41d4-a716-446655440000|%',
    );
  });

  test('upsertProductIfNewer keeps fresher local cache row', () async {
    final database = db.LocalDatabase.memory();
    final repository = HybridCacheRepository(database);
    final stale = DateTime.utc(2026, 6, 18).toIso8601String();
    final fresh = DateTime.utc(2026, 6, 20).toIso8601String();

    await database.into(database.products).insert(
          db.ProductsCompanion.insert(
            id: 'product-1',
            itemNumber: 'P-1',
            itemName: 'Fresh local',
            category: 'General',
            companyName: 'Acme',
            buyingPrice: '10.000',
            sellingPrice: '12.000',
            gstRate: '18.00',
            quantityOnHand: '99',
            lowStockThreshold: '0',
            createdAt: stale,
            updatedAt: fresh,
          ),
        );

    await repository.upsertProductIfNewer(<String, dynamic>{
      'id': 'product-1',
      'item_number': 'P-1',
      'item_name': 'Stale remote',
      'category': 'General',
      'buyer_id': null,
      'company_name': 'Acme',
      'buying_price': 10,
      'selling_price': 12,
      'unit': null,
      'gst_rate': 18,
      'hsn_code': null,
      'quantity_on_hand': 1,
      'low_stock_threshold': 0,
      'is_active': true,
      'created_at': stale,
      'updated_at': stale,
    });

    final products = await database.select(database.products).get();
    expect(products.single.itemName, 'Fresh local');
    expect(products.single.quantityOnHand, '99');
  });
}
