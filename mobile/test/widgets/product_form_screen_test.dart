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
    expect(find.text('Company or buyer is required.'), findsOneWidget);
    expect(find.text('Category is required.'), findsOneWidget);
    expect(find.text('Item name is required.'), findsOneWidget);
    expect(find.text('Item number is required.'), findsOneWidget);
    expect(find.text('Buying price is required.'), findsOneWidget);
    expect(find.text('Selling price is required.'), findsOneWidget);
    expect(find.text('GST rate is required.'), findsOneWidget);
    expect(find.text('Quantity on hand is required.'), findsOneWidget);
    expect(find.text('Low stock threshold is required.'), findsOneWidget);
  });

  testWidgets('unit is optional when creating product', (tester) async {
    final productsService = FakeProductsService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(productsService: productsService),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Company / buyer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item number'), 'PEN-1');
    await tester.enterText(find.bySemanticsLabel('Buying price'), '8');
    await tester.enterText(find.bySemanticsLabel('Selling price'), '10');
    await tester.enterText(find.bySemanticsLabel('GST rate'), '18');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pumpAndSettle();

    expect(productsService.createdInputs.single.unit, isNull);
  });

  testWidgets('invalid prices show clear validation without saving',
      (tester) async {
    final productsService = FakeProductsService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(productsService: productsService),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Company / buyer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item number'), 'PEN-1');
    await tester.enterText(find.bySemanticsLabel('Buying price'), 'free');
    await tester.enterText(find.bySemanticsLabel('Selling price'), '-1');
    await tester.enterText(find.bySemanticsLabel('GST rate'), 'abc');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pump();

    expect(productsService.createdInputs, isEmpty);
    expect(find.text('Buying price must be a valid amount.'), findsOneWidget);
    expect(find.text('Selling price must be zero or greater.'), findsOneWidget);
    expect(find.text('GST rate must be a valid percentage.'), findsOneWidget);
  });

  testWidgets('valid fields submit current product fields', (tester) async {
    final productsService = FakeProductsService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(productsService: productsService),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Company / buyer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item number'), 'PEN-1');
    await tester.enterText(find.bySemanticsLabel('Buying price'), '8.25');
    await tester.enterText(
      find.bySemanticsLabel('Selling price'),
      '10.5',
    );
    await tester.enterText(find.bySemanticsLabel('Unit'), 'box');
    await tester.enterText(find.bySemanticsLabel('GST rate'), '18');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3.25');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pumpAndSettle();

    expect(productsService.createdInputs, hasLength(1));
    final input = productsService.createdInputs.single;
    expect(input.companyName, 'Acme');
    expect(input.category, 'Pens');
    expect(input.itemName, 'Blue Pen');
    expect(input.itemNumber, 'PEN-1');
    expect(input.buyingPrice, 8.25);
    expect(input.sellingPrice, 10.5);
    expect(input.unit, 'box');
    expect(input.gstRate, 18);
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
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemNumber: 'PEN-1',
            buyingPrice: 10,
            sellingPrice: 10,
            gstRate: 18,
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

  testWidgets('edit form preserves buying price and unit unless changed',
      (tester) async {
    final productsService = FakeProductsService();
    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(
          productsService: productsService,
          product: const Product(
            id: '1',
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemNumber: 'PEN-1',
            buyingPrice: 8.25,
            sellingPrice: 10.5,
            unit: 'box',
            gstRate: 18,
            quantityOnHand: 5,
            lowStockThreshold: 2,
            isActive: true,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextField, 'Buying price'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Unit'), findsOneWidget);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(productsService.updatedInputs, hasLength(1));
    final update = productsService.updatedInputs.single;
    expect(update.buyingPrice, 8.25);
    expect(update.sellingPrice, 10.5);
    expect(update.unit, 'box');
  });

  testWidgets('save pops with created product for inventory refresh',
      (tester) async {
    final productsService = FakeProductsService();
    Product? returnedProduct;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                returnedProduct = await Navigator.of(context).push<Product>(
                  MaterialPageRoute<Product>(
                    builder: (_) => ProductFormScreen(
                      productsService: productsService,
                    ),
                  ),
                );
              },
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Company / buyer'), 'Acme');
    await tester.enterText(find.bySemanticsLabel('Category'), 'Pens');
    await tester.enterText(find.bySemanticsLabel('Item name'), 'Blue Pen');
    await tester.enterText(find.bySemanticsLabel('Item number'), 'PEN-1');
    await tester.enterText(find.bySemanticsLabel('Buying price'), '8');
    await tester.enterText(find.bySemanticsLabel('Selling price'), '10');
    await tester.enterText(find.bySemanticsLabel('GST rate'), '18');
    await tester.enterText(find.bySemanticsLabel('Quantity on hand'), '3');
    await tester.enterText(find.bySemanticsLabel('Low stock threshold'), '2');
    await tester.ensureVisible(find.text('Create product'));
    await tester.tap(find.text('Create product'));
    await tester.pumpAndSettle();

    expect(returnedProduct?.itemNumber, 'PEN-1');
    expect(find.text('Open form'), findsOneWidget);
  });
}

class FakeProductsService implements ProductsService {
  final List<CreateProductInput> createdInputs = <CreateProductInput>[];
  final List<UpdateProductInput> updatedInputs = <UpdateProductInput>[];

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    createdInputs.add(input);
    return Product(
      id: 'product-${createdInputs.length}',
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
      buyingPrice: input.buyingPrice,
      sellingPrice: input.sellingPrice,
      unit: input.unit,
      gstRate: input.gstRate,
      quantityOnHand: input.quantityOnHand,
      lowStockThreshold: input.lowStockThreshold,
      isActive: true,
    );
  }

  @override
  Future<Product> adjustQuantity({required String id, required double delta}) {
    throw ApiError(message: 'not used');
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    throw ApiError(message: 'not used');
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) async {
    updatedInputs.add(input);
    return Product(
      id: id,
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
      buyingPrice: input.buyingPrice,
      sellingPrice: input.sellingPrice,
      unit: input.unit,
      gstRate: input.gstRate,
      quantityOnHand: 5,
      lowStockThreshold: input.lowStockThreshold,
      isActive: true,
    );
  }
}
