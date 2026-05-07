import 'package:flutter_test/flutter_test.dart';
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

  test('creates a product and persists backend-compatible decimal strings',
      () async {
    final product = await service.createProduct(_createProductInput());

    expect(product.id, isNotEmpty);
    expect(product.company, 'Acme');
    expect(product.category, 'Pens');
    expect(product.itemName, 'Blue Pen');
    expect(product.itemCode, 'PEN-1');
    expect(product.defaultSellingPriceExclTax, 10.5);
    expect(product.defaultGstRate, 18);
    expect(product.quantityOnHand, 3.25);
    expect(product.lowStockThreshold, 2);
    expect(product.isActive, isTrue);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.id, product.id);
    expect(storedProduct.defaultSellingPriceExclTax, '10.5');
    expect(storedProduct.defaultGstRate, '18');
    expect(storedProduct.quantityOnHand, '3.25');
    expect(storedProduct.lowStockThreshold, '2');
    expect(storedProduct.buyingPriceExclTax, isNull);
    expect(storedProduct.buyingGstRate, isNull);
  });

  test('lists active products ordered by item name', () async {
    final marker = await service.createProduct(
      _createProductInput(itemName: 'Marker', itemCode: 'MRK-1'),
    );
    final pen = await service.createProduct(
      _createProductInput(itemName: 'Blue Pen', itemCode: 'PEN-1'),
    );
    await database.customStatement(
      "UPDATE products SET is_active = 0 WHERE id = '${marker.id}'",
    );

    final products = await service.fetchProducts();

    expect(products.map((product) => product.id), <String>[pen.id]);
  });

  test('searches active products by item name and item code case-insensitively',
      () async {
    final pen = await service.createProduct(
      _createProductInput(itemName: 'Blue Pen', itemCode: 'PEN-1'),
    );
    await service.createProduct(
      _createProductInput(itemName: 'A5 Notebook', itemCode: 'NOTE-1'),
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
      _createProductInput(company: 'Acme', category: 'Pens', itemCode: 'PEN-1'),
    );
    await service.createProduct(
      _createProductInput(
          company: 'Acme', category: 'Files', itemCode: 'FILE-1'),
    );
    await service.createProduct(
      _createProductInput(
          company: 'Globex', category: 'Pens', itemCode: 'PEN-2'),
    );

    final products = await service.fetchProducts(
      filter: const ProductFilter(company: 'Acme', category: 'Pens'),
    );

    expect(products.map((product) => product.id), <String>[expected.id]);
  });

  test('filters active products with low stock only', () async {
    final lowStock = await service.createProduct(
      _createProductInput(
        itemName: 'Blue Pen',
        itemCode: 'PEN-1',
        quantityOnHand: 2,
        lowStockThreshold: 2,
      ),
    );
    await service.createProduct(
      _createProductInput(
        itemName: 'Marker',
        itemCode: 'MRK-1',
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
        company: 'Acme Updated',
        category: 'Markers',
        itemName: 'Permanent Marker',
        itemCode: 'MRK-1',
        defaultSellingPriceExclTax: 22.75,
        defaultGstRate: 12,
        lowStockThreshold: 4,
      ),
    );

    expect(updated.id, product.id);
    expect(updated.company, 'Acme Updated');
    expect(updated.category, 'Markers');
    expect(updated.itemName, 'Permanent Marker');
    expect(updated.itemCode, 'MRK-1');
    expect(updated.defaultSellingPriceExclTax, 22.75);
    expect(updated.defaultGstRate, 12);
    expect(updated.quantityOnHand, 3.25);
    expect(updated.lowStockThreshold, 4);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.defaultSellingPriceExclTax, '22.75');
    expect(storedProduct.defaultGstRate, '12');
    expect(storedProduct.quantityOnHand, '3.25');
    expect(storedProduct.lowStockThreshold, '4');
  });

  test('rejects duplicate product identity and duplicate item code', () async {
    await service.createProduct(_createProductInput());

    await expectLater(
      () => service.createProduct(_createProductInput(itemCode: 'PEN-2')),
      throwsA(_duplicateProductError()),
    );
    await expectLater(
      () => service.createProduct(
        _createProductInput(itemName: 'Black Pen', itemCode: 'PEN-1'),
      ),
      throwsA(_duplicateProductError()),
    );
    expect(await database.select(database.products).get(), hasLength(1));
  });
}

CreateProductInput _createProductInput({
  String company = 'Acme',
  String category = 'Pens',
  String itemName = 'Blue Pen',
  String itemCode = 'PEN-1',
  double defaultSellingPriceExclTax = 10.5,
  double defaultGstRate = 18,
  double quantityOnHand = 3.25,
  double lowStockThreshold = 2,
}) {
  return CreateProductInput(
    company: company,
    category: category,
    itemName: itemName,
    itemCode: itemCode,
    defaultSellingPriceExclTax: defaultSellingPriceExclTax,
    defaultGstRate: defaultGstRate,
    quantityOnHand: quantityOnHand,
    lowStockThreshold: lowStockThreshold,
  );
}

Matcher _duplicateProductError() {
  return isA<ApiError>()
      .having((error) => error.code, 'code', 'DUPLICATE_PRODUCT')
      .having((error) => error.statusCode, 'statusCode', 409);
}
