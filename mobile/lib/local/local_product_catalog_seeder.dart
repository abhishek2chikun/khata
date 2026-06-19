import 'dart:convert';

import 'package:drift/drift.dart';

import 'local_database.dart';

typedef CatalogJsonLoader = Future<String> Function();

class LocalProductCatalogSeeder {
  LocalProductCatalogSeeder({
    required LocalDatabase database,
    CatalogJsonLoader? loadCatalogJson,
    DateTime Function()? clock,
  })  : _database = database,
        _loadCatalogJson = loadCatalogJson,
        _clock = clock ?? DateTime.now;

  static const catalogAssetPath = 'assets/catalog/preinstalled_catalog.json';
  static const _settingsId = 'preinstalled-catalog';
  static const _seedTimestamp = '2026-06-13T00:00:00.000Z';

  final LocalDatabase _database;
  final CatalogJsonLoader? _loadCatalogJson;
  final DateTime Function() _clock;

  Future<void> seedIfNeeded({String? catalogJson}) async {
    final resolvedCatalogJson = catalogJson ?? await _loadCatalogJson?.call();
    if (resolvedCatalogJson == null) {
      return;
    }

    final payload = jsonDecode(resolvedCatalogJson) as Map<String, dynamic>;
    final catalogVersion = _readCatalogVersion(payload['catalog_version']);
    final storedVersion = await _readStoredCatalogVersion();
    if (storedVersion >= catalogVersion) {
      return;
    }

    final buyers = _readBuyerRecords(payload['buyers']);
    final products = _readProductRecords(payload['products']);
    final now = _clock().toUtc().toIso8601String();

    await _database.transaction(() async {
      final buyerIdsByName = await _seedBuyers(buyers, now: now);
      await _seedProducts(
        products,
        buyerIdsByName: buyerIdsByName,
        now: now,
        storedVersion: storedVersion,
        catalogVersion: catalogVersion,
      );
      await _writeStoredCatalogVersion(catalogVersion, now: now);
    });
  }

  Future<Map<String, String>> _seedBuyers(
    List<_CatalogBuyer> buyers, {
    required String now,
  }) async {
    final buyerIdsByName = <String, String>{};
    for (final buyer in buyers) {
      final existing = await (_database.select(_database.buyers)
            ..where((row) => row.name.equals(buyer.name)))
          .getSingleOrNull();
      if (existing != null) {
        buyerIdsByName[buyer.name] = existing.id;
        continue;
      }

      await _database.into(_database.buyers).insert(
            BuyersCompanion.insert(
              id: buyer.id,
              name: buyer.name,
              address: buyer.address,
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      buyerIdsByName[buyer.name] = buyer.id;
    }
    return buyerIdsByName;
  }

  Future<void> _seedProducts(
    List<_CatalogProduct> products, {
    required Map<String, String> buyerIdsByName,
    required String now,
    required int storedVersion,
    required int catalogVersion,
  }) async {
    for (final product in products) {
      final existing = await (_database.select(_database.products)
            ..where((row) => row.itemNumber.equals(product.itemNumber)))
          .getSingleOrNull();
      if (existing == null) {
        final buyerId = buyerIdsByName[product.companyName];
        await _database.into(_database.products).insert(
              ProductsCompanion.insert(
                id: product.id,
                itemNumber: product.itemNumber,
                itemName: product.itemName,
                category: product.category,
                buyerId: Value(buyerId),
                companyName: product.companyName,
                buyingPrice: product.buyingPrice,
                sellingPrice: product.sellingPrice,
                unit: Value(product.unit),
                gstRate: product.gstRate,
                hsnCode: Value(product.hsnCode),
                quantityOnHand: product.quantityOnHand,
                lowStockThreshold: product.lowStockThreshold,
                createdAt: _seedTimestamp,
                updatedAt: _seedTimestamp,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        continue;
      }

      if (storedVersion < catalogVersion) {
        await (_database.update(_database.products)
              ..where((row) => row.itemNumber.equals(product.itemNumber)))
            .write(
          ProductsCompanion(
            buyingPrice: Value(product.buyingPrice),
            sellingPrice: Value(product.sellingPrice),
            hsnCode: Value(product.hsnCode),
            updatedAt: Value(now),
          ),
        );
      }
    }
  }

  Future<int> _readStoredCatalogVersion() async {
    final settings = await (_database.select(_database.catalogCacheSettings)
          ..where((row) => row.id.equals(_settingsId)))
        .getSingleOrNull();
    return settings?.catalogVersion ?? 0;
  }

  Future<void> _writeStoredCatalogVersion(
    int catalogVersion, {
    required String now,
  }) {
    return _database
        .into(_database.catalogCacheSettings)
        .insertOnConflictUpdate(
          CatalogCacheSettingsCompanion.insert(
            id: _settingsId,
            catalogVersion: Value(catalogVersion),
            updatedAt: now,
          ),
        );
  }

  int _readCatalogVersion(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    throw FormatException('Invalid catalog_version: $value');
  }

  List<_CatalogBuyer> _readBuyerRecords(Object? value) {
    if (value is! List<Object?>) {
      throw const FormatException('Invalid buyers payload');
    }
    return value.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid buyer entry');
      }
      return _CatalogBuyer(
        id: _requireString(entry, 'id'),
        name: _requireString(entry, 'name'),
        address: _readString(entry, 'address') ?? '',
      );
    }).toList();
  }

  List<_CatalogProduct> _readProductRecords(Object? value) {
    if (value is! List<Object?>) {
      throw const FormatException('Invalid products payload');
    }
    return value.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid product entry');
      }
      return _CatalogProduct(
        id: _requireString(entry, 'id'),
        itemNumber: _requireString(entry, 'item_number'),
        itemName: _requireString(entry, 'item_name'),
        category: _requireString(entry, 'category'),
        companyName: _requireString(entry, 'company_name'),
        buyingPrice: _requireString(entry, 'buying_price'),
        sellingPrice: _requireString(entry, 'selling_price'),
        unit: _optionalString(entry, 'unit'),
        gstRate: _requireString(entry, 'gst_rate'),
        hsnCode: _optionalString(entry, 'hsn_code'),
        quantityOnHand: _requireString(entry, 'quantity_on_hand'),
        lowStockThreshold: _requireString(entry, 'low_stock_threshold'),
      );
    }).toList();
  }

  String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Missing required catalog field: $key');
  }

  String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    if (value == null) {
      return null;
    }
    throw FormatException('Invalid catalog field: $key');
  }

  String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    throw FormatException('Invalid catalog field: $key');
  }
}

class _CatalogBuyer {
  const _CatalogBuyer({
    required this.id,
    required this.name,
    required this.address,
  });

  final String id;
  final String name;
  final String address;
}

class _CatalogProduct {
  const _CatalogProduct({
    required this.id,
    required this.itemNumber,
    required this.itemName,
    required this.category,
    required this.companyName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.unit,
    required this.gstRate,
    this.hsnCode,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  });

  final String id;
  final String itemNumber;
  final String itemName;
  final String category;
  final String companyName;
  final String buyingPrice;
  final String sellingPrice;
  final String? unit;
  final String gstRate;
  final String? hsnCode;
  final String quantityOnHand;
  final String lowStockThreshold;
}
