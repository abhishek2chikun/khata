import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/product_form_screen.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets('empty required fields show validation without creating product',
      (tester) async {
    final productsService = FakeProductsService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(productsService: productsService),
      ),
    );

    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pump();

    expect(productsService.createdInputs, isEmpty);
    expect(find.text('Company is required.'), findsOneWidget);
    expect(find.text('Category is required.'), findsOneWidget);
    expect(find.text('Item name is required.'), findsOneWidget);
    expect(find.text('Item code is required.'), findsOneWidget);
    expect(find.text('Selling price is required.'), findsOneWidget);
    expect(find.text('GST rate is required.'), findsOneWidget);
    expect(find.text('Quantity on hand is required.'), findsOneWidget);
    expect(find.text('Low stock threshold is required.'), findsOneWidget);
  });

  testWidgets('valid fields submit current product fields', (tester) async {
    final productsService = FakeProductsService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(productsService: productsService),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Company'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item code'), 'PEN-1');
    await tester.enterText(
      find.bySemanticsLabel('Selling price (excl tax)'),
      '10.5',
    );
    await tester.enterText(find.bySemanticsLabel('GST rate'), '18');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3.25');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pumpAndSettle();

    expect(productsService.createdInputs, hasLength(1));
    final input = productsService.createdInputs.single;
    expect(input.company, 'Acme');
    expect(input.category, 'Pens');
    expect(input.itemName, 'Blue Pen');
    expect(input.itemCode, 'PEN-1');
    expect(input.defaultSellingPriceExclTax, 10.5);
    expect(input.defaultGstRate, 18);
    expect(input.quantityOnHand, 3.25);
    expect(input.lowStockThreshold, 2);
  });

  testWidgets('edit form hides unsupported stock and archive controls',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(
          productsService: FakeProductsService(),
          product: const Product(
            id: '1',
            company: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemCode: 'PEN-1',
            defaultSellingPriceExclTax: 10,
            defaultGstRate: 18,
            quantityOnHand: 5,
            lowStockThreshold: 2,
            isActive: true,
          ),
        ),
      ),
    );

    expect(find.text('Quantity on hand'), findsNothing);
    expect(find.text('Active product'), findsNothing);
  });
}

class FakeProductsService implements ProductsService {
  final List<CreateProductInput> createdInputs = <CreateProductInput>[];

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    createdInputs.add(input);
    return Product(
      id: 'product-${createdInputs.length}',
      company: input.company,
      category: input.category,
      itemName: input.itemName,
      itemCode: input.itemCode,
      defaultSellingPriceExclTax: input.defaultSellingPriceExclTax,
      defaultGstRate: input.defaultGstRate,
      quantityOnHand: input.quantityOnHand,
      lowStockThreshold: input.lowStockThreshold,
      isActive: true,
    );
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    throw ApiError(message: 'not used');
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
    throw ApiError(message: 'not used');
  }
}
