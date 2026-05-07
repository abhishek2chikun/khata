import 'dart:math';

import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/product.dart' as product_model;
import '../services/products_service.dart';
import 'local_database.dart';

class LocalProductsService implements ProductsService {
  LocalProductsService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

  @override
  Future<product_model.Product> createProduct(CreateProductInput input) async {
    await _throwIfDuplicate(
      company: input.company,
      category: input.category,
      itemName: input.itemName,
      itemCode: input.itemCode,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final id = _generateUuid();
    try {
      await _database.into(_database.products).insert(
            ProductsCompanion.insert(
              id: id,
              company: input.company,
              category: input.category,
              itemName: input.itemName,
              itemCode: input.itemCode,
              defaultSellingPriceExclTax:
                  _normalizeDecimal(input.defaultSellingPriceExclTax),
              defaultGstRate: _normalizeDecimal(input.defaultGstRate),
              quantityOnHand: _normalizeDecimal(input.quantityOnHand),
              lowStockThreshold: _normalizeDecimal(input.lowStockThreshold),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object catch (error) {
      if (await _hasDuplicate(
        company: input.company,
        category: input.category,
        itemName: input.itemName,
        itemCode: input.itemCode,
      )) {
        throw _duplicateProductError();
      }
      throw error;
    }

    final product = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingle();
    return _toProduct(product);
  }

  @override
  Future<List<product_model.Product>> fetchProducts(
      {ProductFilter? filter}) async {
    final query = _database.select(_database.products)
      ..where((product) => product.isActive.equals(filter?.active ?? true));
    if (filter?.company case final company? when company.isNotEmpty) {
      query.where((product) => product.company.equals(company));
    }
    if (filter?.category case final category? when category.isNotEmpty) {
      query.where((product) => product.category.equals(category));
    }
    query.orderBy([
      (product) => OrderingTerm.asc(product.itemName),
    ]);

    var products = (await query.get()).map(_toProduct).toList();
    if (filter?.search case final search? when search.isNotEmpty) {
      final normalizedSearch = search.toLowerCase();
      products = products
          .where(
            (product) =>
                product.itemName.toLowerCase().contains(normalizedSearch) ||
                product.itemCode.toLowerCase().contains(normalizedSearch),
          )
          .toList();
    }
    if (filter?.lowStockOnly ?? false) {
      products = products.where((product) => product.isLowStock).toList();
    }
    return products;
  }

  @override
  Future<product_model.Product> updateProduct({
    required String id,
    required UpdateProductInput input,
  }) async {
    final existing = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id))
          ..where((product) => product.isActive.equals(true)))
        .getSingleOrNull();
    if (existing == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Product not found',
        statusCode: 404,
      );
    }

    await _throwIfDuplicate(
      company: input.company,
      category: input.category,
      itemName: input.itemName,
      itemCode: input.itemCode,
      excludeId: id,
    );

    try {
      await (_database.update(_database.products)
            ..where((product) => product.id.equals(id))
            ..where((product) => product.isActive.equals(true)))
          .write(
        ProductsCompanion(
          company: Value(input.company),
          category: Value(input.category),
          itemName: Value(input.itemName),
          itemCode: Value(input.itemCode),
          defaultSellingPriceExclTax:
              Value(_normalizeDecimal(input.defaultSellingPriceExclTax)),
          defaultGstRate: Value(_normalizeDecimal(input.defaultGstRate)),
          lowStockThreshold: Value(_normalizeDecimal(input.lowStockThreshold)),
          updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
        ),
      );
    } on Object catch (error) {
      if (await _hasDuplicate(
        company: input.company,
        category: input.category,
        itemName: input.itemName,
        itemCode: input.itemCode,
        excludeId: id,
      )) {
        throw _duplicateProductError();
      }
      throw error;
    }

    final product = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingle();
    return _toProduct(product);
  }

  Future<void> _throwIfDuplicate({
    required String company,
    required String category,
    required String itemName,
    required String itemCode,
    String? excludeId,
  }) async {
    if (await _hasDuplicate(
      company: company,
      category: category,
      itemName: itemName,
      itemCode: itemCode,
      excludeId: excludeId,
    )) {
      throw _duplicateProductError();
    }
  }

  Future<bool> _hasDuplicate({
    required String company,
    required String category,
    required String itemName,
    required String itemCode,
    String? excludeId,
  }) async {
    final duplicate = await (_database.select(_database.products)
          ..where(
            (product) =>
                product.company.equals(company) &
                    product.category.equals(category) &
                    product.itemName.equals(itemName) |
                product.itemCode.equals(itemCode),
          ))
        .get();
    return duplicate.any((product) => product.id != excludeId);
  }

  ApiError _duplicateProductError() {
    return const ApiError(
      code: 'DUPLICATE_PRODUCT',
      message: 'Product already exists',
      statusCode: 409,
    );
  }

  product_model.Product _toProduct(Product product) {
    return product_model.Product(
      id: product.id,
      company: product.company,
      category: product.category,
      itemName: product.itemName,
      itemCode: product.itemCode,
      defaultSellingPriceExclTax:
          double.parse(product.defaultSellingPriceExclTax),
      defaultGstRate: double.parse(product.defaultGstRate),
      quantityOnHand: double.parse(product.quantityOnHand),
      lowStockThreshold: double.parse(product.lowStockThreshold),
      isActive: product.isActive,
    );
  }

  String _normalizeDecimal(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Decimal value must be finite');
    }
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
