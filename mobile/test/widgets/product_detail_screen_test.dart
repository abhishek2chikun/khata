import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/product_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets('detail shows all inventory fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: _product,
          productsService: FakeProductsService(product: _product),
          onEditProduct: (_) async => false,
          supportsProductReactivation: true,
        ),
      ),
    );

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('PEN-1'), findsOneWidget);
    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Acme Traders'), findsOneWidget);
    expect(find.text('Pens'), findsOneWidget);
    expect(find.text('Buying price'), findsOneWidget);
    expect(find.text('8.00'), findsOneWidget);
    expect(find.text('Selling price'), findsOneWidget);
    expect(find.text('10.50'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('box'), findsOneWidget);
    expect(find.text('GST'), findsOneWidget);
    expect(find.text('18%'), findsOneWidget);
    expect(find.text('Stock on hand'), findsOneWidget);
    expect(find.text('3 box'), findsOneWidget);
    expect(find.text('Low stock threshold'), findsOneWidget);
    expect(find.text('2 box'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('edit opens product form callback', (tester) async {
    Product? editedProduct;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: _product,
          productsService: FakeProductsService(product: _product),
          onEditProduct: (product) async {
            editedProduct = product;
            return false;
          },
          supportsProductReactivation: true,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('editProductButton')));
    await tester.tap(find.byKey(const Key('editProductButton')));
    await tester.pump();

    expect(editedProduct?.id, _product.id);
  });

  testWidgets('archive marks product inactive and returns refresh result',
      (tester) async {
    final service = FakeProductsService(product: _product);
    Product? returnedProduct;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                returnedProduct = await Navigator.of(context).push<Product>(
                  MaterialPageRoute<Product>(
                    builder: (_) => ProductDetailScreen(
                      product: _product,
                      productsService: service,
                      onEditProduct: (_) async => false,
                      supportsProductReactivation: true,
                    ),
                  ),
                );
              },
              child: const Text('Open detail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('archiveProductButton')));
    await tester.tap(find.byKey(const Key('archiveProductButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();

    expect(service.archiveCalls, 1);
    expect(returnedProduct?.isActive, isFalse);
  });

  testWidgets('reactivate marks archived product active', (tester) async {
    final archived = _product.copyWith(isActive: false);
    final service = FakeProductsService(product: archived);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: archived,
          productsService: service,
          onEditProduct: (_) async => false,
          supportsProductReactivation: true,
        ),
      ),
    );

    await tester
        .ensureVisible(find.byKey(const Key('reactivateProductButton')));
    await tester.tap(find.byKey(const Key('reactivateProductButton')));
    await tester.pumpAndSettle();

    expect(service.reactivateCalls, 1);
    expect(find.text('Product reactivated'), findsOneWidget);
  });

  testWidgets('stock adjustment updates quantity with minimal local path',
      (tester) async {
    final service = FakeProductsService(product: _product);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: _product,
          productsService: service,
          onEditProduct: (_) async => false,
          supportsProductReactivation: true,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('adjustStockButton')));
    await tester.tap(find.byKey(const Key('adjustStockButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('stockAdjustmentField')), '4');
    await tester.tap(find.text('Apply adjustment'));
    await tester.pumpAndSettle();

    expect(service.stockAdjustments.single.quantityDelta, 4);
    expect(service.stockAdjustments.single.requestId, isNotEmpty);
    expect(find.text('7 box'), findsOneWidget);
    expect(find.text('Stock adjusted'), findsOneWidget);
  });

  testWidgets('archived detail explains invoice guard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: _product.copyWith(isActive: false),
          productsService: FakeProductsService(
            product: _product.copyWith(isActive: false),
          ),
          onEditProduct: (_) async => false,
          supportsProductReactivation: false,
        ),
      ),
    );

    expect(find.text('Archived products are hidden from new invoices.'),
        findsOneWidget);
    expect(find.byKey(const Key('reactivateProductButton')), findsNothing);
    expect(find.text('Reactivation is only available in local mode.'),
        findsOneWidget);
  });

  testWidgets('archive uses archive service method', (tester) async {
    final service = FakeProductsService(product: _product);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: _product,
          productsService: service,
          onEditProduct: (_) async => false,
          supportsProductReactivation: false,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('archiveProductButton')));
    await tester.tap(find.byKey(const Key('archiveProductButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();

    expect(service.archiveCalls, 1);
    expect(service.updatedInputs, isEmpty);
  });
}

const _product = Product(
  id: 'product-1',
  companyName: 'Acme Traders',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemNumber: 'PEN-1',
  buyingPrice: 8,
  sellingPrice: 10.5,
  unit: 'box',
  gstRate: 18,
  quantityOnHand: 3,
  lowStockThreshold: 2,
  isActive: true,
);

extension on Product {
  Product copyWith({bool? isActive, double? quantityOnHand}) {
    return Product(
      id: id,
      companyName: companyName,
      category: category,
      itemName: itemName,
      itemNumber: itemNumber,
      buyerId: buyerId,
      buyingPrice: buyingPrice,
      sellingPrice: sellingPrice,
      unit: unit,
      gstRate: gstRate,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      lowStockThreshold: lowStockThreshold,
      isActive: isActive ?? this.isActive,
    );
  }
}

class FakeProductsService implements ProductsService {
  FakeProductsService({required this.product});

  Product product;
  final List<UpdateProductInput> updatedInputs = <UpdateProductInput>[];
  final List<bool?> activeChanges = <bool?>[];
  final List<AdjustStockInput> stockAdjustments = <AdjustStockInput>[];
  var archiveCalls = 0;
  var reactivateCalls = 0;

  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async =>
      <Product>[product];

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductInput input,
  }) async {
    updatedInputs.add(input);
    product = Product(
      id: id,
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
      buyingPrice: input.buyingPrice,
      sellingPrice: input.sellingPrice,
      unit: input.unit,
      gstRate: input.gstRate,
      quantityOnHand: product.quantityOnHand,
      lowStockThreshold: input.lowStockThreshold,
      isActive: product.isActive,
    );
    return product;
  }

  @override
  Future<Product> archiveProduct({required String id}) async {
    archiveCalls += 1;
    product = product.copyWith(isActive: false);
    return product;
  }

  @override
  Future<Product> reactivateProduct({required String id}) async {
    reactivateCalls += 1;
    product = product.copyWith(isActive: true);
    return product;
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) async {
    stockAdjustments.add(input);
    product = product.copyWith(
      quantityOnHand: product.quantityOnHand + input.quantityDelta,
    );
    return product;
  }
}
