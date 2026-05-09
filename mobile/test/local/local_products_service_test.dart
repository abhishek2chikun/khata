import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  late LocalDatabase database;
  late LocalProductsService service;

  setUp(() {
    database = LocalDatabase.memory();
    service = LocalProductsService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates a product and persists canonical V2 decimal strings', () async {
    final product = await service.createProduct(_createProductInput());

    expect(product.id, isNotEmpty);
    expect(product.companyName, 'Acme');
    expect(product.category, 'Pens');
    expect(product.itemName, 'Blue Pen');
    expect(product.itemNumber, 'PEN-1');
    expect(product.buyingPrice, 8.25);
    expect(product.sellingPrice, 10.5);
    expect(product.unit, 'box');
    expect(product.gstRate, 18);
    expect(product.quantityOnHand, 3.25);
    expect(product.lowStockThreshold, 2);
    expect(product.isActive, isTrue);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.id, product.id);
    expect(storedProduct.companyName, 'Acme');
    expect(storedProduct.itemNumber, 'PEN-1');
    expect(storedProduct.buyingPrice, '8.25');
    expect(storedProduct.sellingPrice, '10.5');
    expect(storedProduct.unit, 'box');
    expect(storedProduct.gstRate, '18');
    expect(storedProduct.quantityOnHand, '3.25');
    expect(storedProduct.lowStockThreshold, '2');
  });

  test(
      'unfiltered list includes active and inactive products ordered by item name',
      () async {
    final marker = await service.createProduct(
      _createProductInput(itemName: 'Marker', itemNumber: 'MRK-1'),
    );
    final pen = await service.createProduct(
      _createProductInput(itemName: 'Blue Pen', itemNumber: 'PEN-1'),
    );
    await database.customStatement(
      "UPDATE products SET is_active = 0 WHERE id = '${marker.id}'",
    );

    final products = await service.fetchProducts();

    expect(products.map((product) => product.id), <String>[pen.id, marker.id]);
    expect(products.map((product) => product.isActive), <bool>[true, false]);
  });

  test('active filter returns active or inactive products when provided',
      () async {
    final inactive = await service.createProduct(
      _createProductInput(itemName: 'Marker', itemNumber: 'MRK-1'),
    );
    final active = await service.createProduct(
      _createProductInput(itemName: 'Blue Pen', itemNumber: 'PEN-1'),
    );
    await database.customStatement(
      "UPDATE products SET is_active = 0 WHERE id = '${inactive.id}'",
    );

    final activeProducts = await service.fetchProducts(
      filter: const ProductFilter(active: true),
    );
    final inactiveProducts = await service.fetchProducts(
      filter: const ProductFilter(active: false),
    );

    expect(activeProducts.map((product) => product.id), <String>[active.id]);
    expect(
        inactiveProducts.map((product) => product.id), <String>[inactive.id]);
  });

  test('searches products by item name and item number case-insensitively',
      () async {
    final pen = await service.createProduct(
      _createProductInput(itemName: 'Blue Pen', itemNumber: 'PEN-1'),
    );
    await service.createProduct(
      _createProductInput(itemName: 'A5 Notebook', itemNumber: 'NOTE-1'),
    );

    final nameMatches = await service.fetchProducts(
      filter: const ProductFilter(search: 'blue'),
    );
    final codeMatches = await service.fetchProducts(
      filter: const ProductFilter(search: 'pen-1'),
    );

    expect(nameMatches.map((product) => product.id), <String>[pen.id]);
    expect(codeMatches.map((product) => product.id), <String>[pen.id]);
  });

  test('filters active products by company and category', () async {
    final expected = await service.createProduct(
      _createProductInput(
          companyName: 'Acme', category: 'Pens', itemNumber: 'PEN-1'),
    );
    await service.createProduct(
      _createProductInput(
          companyName: 'Acme', category: 'Files', itemNumber: 'FILE-1'),
    );
    await service.createProduct(
      _createProductInput(
          companyName: 'Globex', category: 'Pens', itemNumber: 'PEN-2'),
    );

    final products = await service.fetchProducts(
      filter: const ProductFilter(companyName: 'Acme', category: 'Pens'),
    );

    expect(products.map((product) => product.id), <String>[expected.id]);
  });

  test('filters active products with low stock only', () async {
    final lowStock = await service.createProduct(
      _createProductInput(
        itemName: 'Blue Pen',
        itemNumber: 'PEN-1',
        quantityOnHand: 2,
        lowStockThreshold: 2,
      ),
    );
    await service.createProduct(
      _createProductInput(
        itemName: 'Marker',
        itemNumber: 'MRK-1',
        quantityOnHand: 5,
        lowStockThreshold: 2,
      ),
    );

    final products = await service.fetchProducts(
      filter: const ProductFilter(lowStockOnly: true),
    );

    expect(products.map((product) => product.id), <String>[lowStock.id]);
  });

  test('updates active products without changing quantity on hand', () async {
    final product = await service.createProduct(_createProductInput());

    final updated = await service.updateProduct(
      id: product.id,
      input: const UpdateProductInput(
        companyName: 'Acme Updated',
        category: 'Markers',
        itemName: 'Permanent Marker',
        itemNumber: 'MRK-1',
        buyingPrice: 18.25,
        sellingPrice: 22.75,
        unit: 'pcs',
        gstRate: 12,
        lowStockThreshold: 4,
      ),
    );

    expect(updated.id, product.id);
    expect(updated.companyName, 'Acme Updated');
    expect(updated.category, 'Markers');
    expect(updated.itemName, 'Permanent Marker');
    expect(updated.itemNumber, 'MRK-1');
    expect(updated.buyingPrice, 18.25);
    expect(updated.sellingPrice, 22.75);
    expect(updated.unit, 'pcs');
    expect(updated.gstRate, 12);
    expect(updated.quantityOnHand, 3.25);
    expect(updated.lowStockThreshold, 4);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.buyingPrice, '18.25');
    expect(storedProduct.sellingPrice, '22.75');
    expect(storedProduct.unit, 'pcs');
    expect(storedProduct.gstRate, '12');
    expect(storedProduct.quantityOnHand, '3.25');
    expect(storedProduct.lowStockThreshold, '4');
  });

  test('updates inactive products by id without changing quantity on hand',
      () async {
    await _seedInactiveProduct(database);

    final updated = await service.updateProduct(
      id: 'inactive-product',
      input: const UpdateProductInput(
        companyName: 'Acme Updated',
        category: 'Markers',
        itemName: 'Permanent Marker',
        itemNumber: 'MRK-1',
        buyingPrice: 18.25,
        sellingPrice: 22.75,
        unit: null,
        gstRate: 12,
        lowStockThreshold: 4,
      ),
    );

    expect(updated.id, 'inactive-product');
    expect(updated.companyName, 'Acme Updated');
    expect(updated.category, 'Markers');
    expect(updated.itemName, 'Permanent Marker');
    expect(updated.itemNumber, 'MRK-1');
    expect(updated.buyingPrice, 18.25);
    expect(updated.sellingPrice, 22.75);
    expect(updated.unit, isNull);
    expect(updated.gstRate, 12);
    expect(updated.quantityOnHand, 0);
    expect(updated.lowStockThreshold, 4);
    expect(updated.isActive, isFalse);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.buyingPrice, '18.25');
    expect(storedProduct.sellingPrice, '22.75');
    expect(storedProduct.unit, isNull);
    expect(storedProduct.gstRate, '12');
    expect(storedProduct.quantityOnHand, '0');
    expect(storedProduct.lowStockThreshold, '4');
    expect(storedProduct.isActive, isFalse);
  });

  test('rejects duplicate company/name/category', () async {
    await service.createProduct(_createProductInput());

    await expectLater(
      () => service.createProduct(_createProductInput(itemNumber: 'PEN-2')),
      throwsA(_duplicateProductError()),
    );
    expect(await database.select(database.products).get(), hasLength(1));
  });

  test('rejects duplicate item number', () async {
    await service.createProduct(_createProductInput());

    await expectLater(
      () => service.createProduct(
        _createProductInput(itemName: 'Black Pen', itemNumber: 'PEN-1'),
      ),
      throwsA(_duplicateProductError()),
    );
    expect(await database.select(database.products).get(), hasLength(1));
  });

  test('maps inactive duplicate create conflicts to duplicate product error',
      () async {
    await _seedInactiveProduct(database);

    await expectLater(
      () => service.createProduct(_createProductInput(itemNumber: 'PEN-2')),
      throwsA(_duplicateProductError()),
    );
    await expectLater(
      () => service.createProduct(
        _createProductInput(itemName: 'Black Pen', itemNumber: 'PEN-1'),
      ),
      throwsA(_duplicateProductError()),
    );
  });

  test('maps inactive duplicate update conflicts to duplicate product error',
      () async {
    await _seedInactiveProduct(database);
    final product = await service.createProduct(
      _createProductInput(
        companyName: 'Globex',
        category: 'Markers',
        itemName: 'Marker',
        itemNumber: 'MRK-1',
      ),
    );

    await expectLater(
      () => service.updateProduct(
        id: product.id,
        input: const UpdateProductInput(
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'MRK-2',
          buyingPrice: 8,
          sellingPrice: 10,
          unit: 'box',
          gstRate: 18,
          lowStockThreshold: 2,
        ),
      ),
      throwsA(_duplicateProductError()),
    );
    await expectLater(
      () => service.updateProduct(
        id: product.id,
        input: const UpdateProductInput(
          companyName: 'Globex',
          category: 'Markers',
          itemName: 'Marker',
          itemNumber: 'PEN-1',
          buyingPrice: 8,
          sellingPrice: 10,
          unit: 'box',
          gstRate: 18,
          lowStockThreshold: 2,
        ),
      ),
      throwsA(_duplicateProductError()),
    );
  });
}

CreateProductInput _createProductInput({
  String companyName = 'Acme',
  String category = 'Pens',
  String itemName = 'Blue Pen',
  String itemNumber = 'PEN-1',
  double buyingPrice = 8.25,
  double sellingPrice = 10.5,
  String? unit = 'box',
  double gstRate = 18,
  double quantityOnHand = 3.25,
  double lowStockThreshold = 2,
}) {
  return CreateProductInput(
    companyName: companyName,
    category: category,
    itemName: itemName,
    itemNumber: itemNumber,
    buyingPrice: buyingPrice,
    sellingPrice: sellingPrice,
    unit: unit,
    gstRate: gstRate,
    quantityOnHand: quantityOnHand,
    lowStockThreshold: lowStockThreshold,
  );
}

Matcher _duplicateProductError() {
  return isA<ApiError>()
      .having((error) => error.code, 'code', 'DUPLICATE_PRODUCT')
      .having((error) => error.statusCode, 'statusCode', 409);
}

Future<void> _seedInactiveProduct(LocalDatabase database) {
  return database.into(database.products).insert(
        ProductsCompanion.insert(
          id: 'inactive-product',
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-1',
          buyingPrice: '8',
          sellingPrice: '10',
          unit: const Value('box'),
          gstRate: '18',
          quantityOnHand: '0',
          lowStockThreshold: '2',
          isActive: const Value(false),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
}
