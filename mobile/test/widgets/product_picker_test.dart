import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/widgets/product_picker.dart';

void main() {
  testWidgets('product picker lazily renders bounded initial list for 1199 products',
      (tester) async {
    final products = List<Product>.generate(1199, (index) {
      return Product(
        id: 'product-$index',
        companyName: 'Company ${index % 7}',
        category: 'General',
        itemName: 'Item $index',
        itemNumber: 'SKU-$index',
        buyingPrice: 10,
        sellingPrice: 12.345,
        gstRate: 18,
        hsnCode: index.isEven ? '9608$index' : null,
        quantityOnHand: 5,
        lowStockThreshold: 1,
        isActive: true,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductPicker(
            fieldKey: const Key('productPickerField'),
            products: products,
            selectedProduct: null,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('productPickerField')));
    await tester.pumpAndSettle();

    expect(find.byType(SimpleDialogOption), findsNothing);
    expect(find.byKey(const Key('productSearchField')), findsOneWidget);
    expect(find.byKey(const Key('productSearchResultCount')), findsOneWidget);
    expect(find.text('50 results'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
    expect(find.byType(ListTile).evaluate().length, lessThan(60));
    expect(find.byType(ListTile).evaluate().length, greaterThan(0));
  });

  testWidgets('product picker matches name item number company and hsn',
      (tester) async {
    final products = <Product>[
      const Product(
        id: 'product-1',
        companyName: 'Acme',
        category: 'Pens',
        itemName: 'Blue Pen',
        itemNumber: 'PEN-1',
        buyingPrice: 10,
        sellingPrice: 12.345,
        gstRate: 18,
        hsnCode: '960810',
        quantityOnHand: 5,
        lowStockThreshold: 1,
        isActive: true,
      ),
      const Product(
        id: 'product-2',
        companyName: 'Globex',
        category: 'Pens',
        itemName: 'Red Pen',
        itemNumber: 'PEN-2',
        buyingPrice: 10,
        sellingPrice: 15,
        gstRate: 18,
        quantityOnHand: 5,
        lowStockThreshold: 1,
        isActive: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductPicker(
            fieldKey: const Key('productPickerField'),
            products: products,
            selectedProduct: null,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('productPickerField')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('productSearchField')), 'pen-1');
    await tester.pump();

    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Blue Pen'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('productSearchField')), 'globex');
    await tester.pump();

    expect(find.text('Red Pen'), findsOneWidget);
    expect(find.text('Blue Pen'), findsNothing);

    await tester.enterText(find.byKey(const Key('productSearchField')), '960810');
    await tester.pump();

    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Red Pen'), findsNothing);
  });

  testWidgets('product picker shows no-result state and selects product',
      (tester) async {
    final products = <Product>[
      const Product(
        id: 'product-1',
        companyName: 'Acme',
        category: 'Pens',
        itemName: 'Blue Pen',
        itemNumber: 'PEN-1',
        buyingPrice: 10,
        sellingPrice: 12.345,
        gstRate: 18,
        quantityOnHand: 5,
        lowStockThreshold: 1,
        isActive: true,
      ),
    ];

    Product? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductPicker(
            fieldKey: const Key('productPickerField'),
            products: products,
            selectedProduct: null,
            onSelected: (product) => selected = product,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('productPickerField')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('productSearchField')), 'missing-product');
    await tester.pump();

    expect(find.byKey(const Key('productSearchNoResults')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('productSearchField')), 'Blue');
    await tester.pump();
    await tester.tap(find.text('Blue Pen'));
    await tester.pumpAndSettle();

    expect(selected?.itemName, 'Blue Pen');
  });
}
