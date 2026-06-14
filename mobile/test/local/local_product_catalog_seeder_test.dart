import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_product_catalog_seeder.dart';
import 'package:path/path.dart' as p;

void main() {
  const fixtureCatalog = '''
{
  "catalog_version": 1,
  "generated_at": "2026-06-13T00:00:00.000Z",
  "buyers": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "name": "Acemark Stationers",
      "address": ""
    }
  ],
  "products": [
    {
      "id": "22222222-2222-4222-8222-222222222222",
      "item_number": "ACEMARK-0001",
      "item_name": "A4 College Note Book 404P Ace",
      "category": "Notebook",
      "company_name": "Acemark Stationers",
      "buying_price": "92.8",
      "selling_price": "69.6",
      "unit": "pcs",
      "gst_rate": "12",
      "quantity_on_hand": "6",
      "low_stock_threshold": "0"
    }
  ]
}
''';

  test('seeds buyers and products from bundled catalog fixture', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await LocalProductCatalogSeeder(database: database).seedIfNeeded(
      catalogJson: fixtureCatalog,
    );

    final buyers = await database.select(database.buyers).get();
    final products = await database.select(database.products).get();

    expect(buyers, hasLength(1));
    expect(buyers.single.name, 'Acemark Stationers');

    expect(products, hasLength(1));
    expect(products.single.itemNumber, 'ACEMARK-0001');
    expect(products.single.itemName, 'A4 College Note Book 404P Ace');
    expect(products.single.category, 'Notebook');
    expect(products.single.companyName, 'Acemark Stationers');
    expect(products.single.buyingPrice, '92.8');
    expect(products.single.sellingPrice, '69.6');
    expect(products.single.unit, 'pcs');
    expect(products.single.gstRate, '12');
    expect(products.single.quantityOnHand, '6');
    expect(products.single.lowStockThreshold, '0');
    expect(products.single.buyerId, buyers.single.id);
  });

  test('re-seeding is idempotent', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);
    final seeder = LocalProductCatalogSeeder(database: database);

    await seeder.seedIfNeeded(catalogJson: fixtureCatalog);
    await seeder.seedIfNeeded(catalogJson: fixtureCatalog);

    final buyers = await database.select(database.buyers).get();
    final products = await database.select(database.products).get();
    expect(buyers, hasLength(1));
    expect(products, hasLength(1));
  });

  test('re-seeding preserves user edits', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);
    final seeder = LocalProductCatalogSeeder(database: database);

    await seeder.seedIfNeeded(catalogJson: fixtureCatalog);
    await (database.update(database.products)
          ..where((product) => product.itemNumber.equals('ACEMARK-0001')))
        .write(
      const ProductsCompanion(
        itemName: Value('Edited Notebook Name'),
      ),
    );

    await seeder.seedIfNeeded(catalogJson: fixtureCatalog);

    final product = await (database.select(database.products)
          ..where((product) => product.itemNumber.equals('ACEMARK-0001')))
        .getSingle();
    expect(product.itemName, 'Edited Notebook Name');
  });

  test('full bundled catalog seeds expected counts', () async {
    final catalogPath = p.join(
      Directory.current.path,
      'assets',
      'catalog',
      'preinstalled_catalog.json',
    );
    final catalogJson = File(catalogPath).readAsStringSync();
    final payload = jsonDecode(catalogJson) as Map<String, dynamic>;

    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await LocalProductCatalogSeeder(database: database).seedIfNeeded(
      catalogJson: catalogJson,
    );

    final buyers = await database.select(database.buyers).get();
    final products = await database.select(database.products).get();
    expect(buyers, hasLength((payload['buyers'] as List).length));
    expect(products, hasLength((payload['products'] as List).length));
  });
}
