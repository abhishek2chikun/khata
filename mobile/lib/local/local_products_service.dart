import 'dart:math';

import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/product.dart' as product_model;
import '../services/products_service.dart';
import 'local_database.dart';
import 'local_customers_service.dart';

class LocalProductsService implements ProductsService {
  LocalProductsService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;
  static const _systemUserId = 'local-system-user';

  @override
  Future<product_model.Product> createProduct(CreateProductInput input) async {
    await _throwIfDuplicate(
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final id = _generateUuid();
    try {
      await _database.into(_database.products).insert(
            ProductsCompanion.insert(
              id: id,
              companyName: input.companyName,
              category: input.category,
              itemName: input.itemName,
              itemNumber: input.itemNumber,
              buyerId: Value(input.buyerId),
              buyingPrice: _normalizeDecimal(input.buyingPrice),
              sellingPrice: _normalizeDecimal(input.sellingPrice),
              unit: Value(input.unit),
              gstRate: _normalizeDecimal(input.gstRate),
              quantityOnHand: _normalizeDecimal(input.quantityOnHand),
              lowStockThreshold: _normalizeDecimal(input.lowStockThreshold),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object catch (error) {
      if (await _hasDuplicate(
        companyName: input.companyName,
        category: input.category,
        itemName: input.itemName,
        itemNumber: input.itemNumber,
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
    final query = _database.select(_database.products);
    if (filter?.active case final active?) {
      query.where((product) => product.isActive.equals(active));
    }
    if (filter?.companyName case final company? when company.isNotEmpty) {
      query.where((product) => product.companyName.equals(company));
    }
    if (filter?.category case final category? when category.isNotEmpty) {
      query.where((product) => product.category.equals(category));
    }
    if (filter?.buyerId case final buyerId?) {
      query.where((product) => product.buyerId.equals(buyerId));
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
                product.itemNumber.toLowerCase().contains(normalizedSearch),
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
          ..where((product) => product.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Product not found',
        statusCode: 404,
      );
    }

    await _throwIfDuplicate(
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
      excludeId: id,
    );

    try {
      await (_database.update(_database.products)
            ..where((product) => product.id.equals(id)))
          .write(
        ProductsCompanion(
          companyName: Value(input.companyName),
          category: Value(input.category),
          itemName: Value(input.itemName),
          itemNumber: Value(input.itemNumber),
          buyerId: Value(input.buyerId),
          buyingPrice: Value(_normalizeDecimal(input.buyingPrice)),
          sellingPrice: Value(_normalizeDecimal(input.sellingPrice)),
          unit: Value(input.unit),
          gstRate: Value(_normalizeDecimal(input.gstRate)),
          lowStockThreshold: Value(_normalizeDecimal(input.lowStockThreshold)),
          updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
        ),
      );
    } on Object catch (error) {
      if (await _hasDuplicate(
        companyName: input.companyName,
        category: input.category,
        itemName: input.itemName,
        itemNumber: input.itemNumber,
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

  @override
  Future<product_model.Product> archiveProduct({required String id}) {
    return _setActive(id: id, isActive: false);
  }

  @override
  Future<product_model.Product> reactivateProduct({required String id}) {
    return _setActive(id: id, isActive: true);
  }

  @override
  Future<product_model.Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) async {
    final existing = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Product not found',
        statusCode: 404,
      );
    }

    if (!existing.isActive) {
      throw const ApiError(
        code: 'PRODUCT_ARCHIVED',
        message: 'Archived product cannot be adjusted',
        statusCode: 400,
      );
    }

    if (input.requestId.trim().isEmpty) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'request_id is required',
        statusCode: 400,
      );
    }

    if (input.quantityDelta == 0) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'quantity_delta must be non-zero',
        statusCode: 400,
      );
    }

    final existingMovement = await (_database.select(_database.stockMovements)
          ..where((movement) => movement.requestId.equals(input.requestId)))
        .getSingleOrNull();
    if (existingMovement != null) {
      final matchesExistingPayload = existingMovement.productId == id &&
          existingMovement.quantityDelta ==
              _normalizeDecimal(input.quantityDelta) &&
          existingMovement.reason == input.reason;
      if (!matchesExistingPayload) {
        throw const ApiError(
          code: 'IDEMPOTENCY_CONFLICT',
          message: 'request_id already used with different payload',
          statusCode: 409,
        );
      }
      final product = await (_database.select(_database.products)
            ..where((product) => product.id.equals(id)))
          .getSingle();
      return _toProduct(product);
    }

    await _ensureSystemUser();
    await _database.transaction(() async {
      final now = DateTime.now().toUtc().toIso8601String();
      final nextQuantity =
          double.parse(existing.quantityOnHand) + input.quantityDelta;
      await (_database.update(_database.products)
            ..where((product) => product.id.equals(id)))
          .write(
        ProductsCompanion(
          quantityOnHand: Value(_normalizeDecimal(nextQuantity)),
          updatedAt: Value(now),
        ),
      );
      await _database.into(_database.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: generateLocalUuid(),
              productId: id,
              requestId: Value(input.requestId),
              movementType: 'MANUAL_ADJUSTMENT',
              quantityDelta: _normalizeDecimal(input.quantityDelta),
              reason: Value(input.reason),
              createdByUserId: _systemUserId,
              createdAt: now,
            ),
          );
    });

    final product = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingle();
    return _toProduct(product);
  }

  Future<product_model.Product> _setActive({
    required String id,
    required bool isActive,
  }) async {
    final existing = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Product not found',
        statusCode: 404,
      );
    }

    await (_database.update(_database.products)
          ..where((product) => product.id.equals(id)))
        .write(
      ProductsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
    final product = await (_database.select(_database.products)
          ..where((product) => product.id.equals(id)))
        .getSingle();
    return _toProduct(product);
  }

  Future<void> _ensureSystemUser() async {
    final existing = await (_database.select(_database.localUsers)
          ..where((user) => user.id.equals(_systemUserId)))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.localUsers).insert(
          LocalUsersCompanion.insert(
            id: _systemUserId,
            username: 'local-system',
            passwordHash: 'not-used',
            displayName: const Value('Local System'),
            salt: 'not-used',
            passwordHashVersion: 1,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _throwIfDuplicate({
    required String companyName,
    required String category,
    required String itemName,
    required String itemNumber,
    String? excludeId,
  }) async {
    if (await _hasDuplicate(
      companyName: companyName,
      category: category,
      itemName: itemName,
      itemNumber: itemNumber,
      excludeId: excludeId,
    )) {
      throw _duplicateProductError();
    }
  }

  Future<bool> _hasDuplicate({
    required String companyName,
    required String category,
    required String itemName,
    required String itemNumber,
    String? excludeId,
  }) async {
    final duplicate = await (_database.select(_database.products)
          ..where(
            (product) =>
                product.companyName.equals(companyName) &
                    product.category.equals(category) &
                    product.itemName.equals(itemName) |
                product.itemNumber.equals(itemNumber),
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
      companyName: product.companyName,
      category: product.category,
      itemName: product.itemName,
      itemNumber: product.itemNumber,
      buyerId: product.buyerId,
      buyingPrice: double.parse(product.buyingPrice),
      sellingPrice: double.parse(product.sellingPrice),
      unit: product.unit,
      gstRate: double.parse(product.gstRate),
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
