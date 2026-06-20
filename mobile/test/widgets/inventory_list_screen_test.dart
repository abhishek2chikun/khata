import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/inventory_list_screen.dart';
import 'package:internal_billing_khata_mobile/screens/product_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets(
      'loads products, filters by search text, and shows low stock warning',
      (tester) async {
    final service = FakeProductsService(
      products: <Product>[
        Product(
          id: '1',
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-1',
          buyingPrice: 10,
          sellingPrice: 10,
          gstRate: 18,
          quantityOnHand: 2,
          lowStockThreshold: 5,
          isActive: true,
        ),
        Product(
          id: '2',
          companyName: 'Acme',
          category: 'Books',
          itemName: 'Ledger Book',
          itemNumber: 'BOOK-1',
          buyingPrice: 50,
          sellingPrice: 50,
          gstRate: 12,
          quantityOnHand: 20,
          lowStockThreshold: 5,
          isActive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => false,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('Ledger Book'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('searchFilterField')), 'blue');
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Ledger Book'), findsNothing);
    expect(service.lastFilter?.search, 'blue');
  });

  testWidgets('filters by company and category inputs', (tester) async {
    final service = FakeProductsService(
      products: <Product>[
        Product(
          id: '1',
          companyName: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemNumber: 'PEN-1',
          buyingPrice: 10,
          sellingPrice: 10,
          gstRate: 18,
          quantityOnHand: 2,
          lowStockThreshold: 5,
          isActive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => false,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('companyFilterField')), 'Acme');
    await tester.pumpAndSettle();
    expect(service.lastFilter?.companyName, 'Acme');

    await tester.enterText(
        find.byKey(const Key('categoryFilterField')), 'Pens');
    await tester.pumpAndSettle();
    expect(service.lastFilter?.category, 'Pens');
  });

  testWidgets('refreshes product list after add flow returns success',
      (tester) async {
    final service = SequencedProductsService(
      responses: <List<Product>>[
        <Product>[
          Product(
            id: '1',
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemNumber: 'PEN-1',
            buyingPrice: 10,
            sellingPrice: 10,
            gstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
        <Product>[
          Product(
            id: '1',
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemNumber: 'PEN-1',
            buyingPrice: 10,
            sellingPrice: 10,
            gstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
          Product(
            id: '2',
            companyName: 'Acme',
            category: 'Books',
            itemName: 'Ledger Book',
            itemNumber: 'BOOK-1',
            buyingPrice: 50,
            sellingPrice: 50,
            gstRate: 12,
            quantityOnHand: 20,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => true,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Ledger Book'), findsNothing);

    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pumpAndSettle();

    expect(service.fetchCount, 2);
    expect(find.text('Ledger Book'), findsOneWidget);
  });

  testWidgets('refreshes product list after detail flow returns success',
      (tester) async {
    final service = SequencedProductsService(
      responses: <List<Product>>[
        <Product>[
          Product(
            id: '1',
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemNumber: 'PEN-1',
            buyingPrice: 10,
            sellingPrice: 10,
            gstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
        <Product>[
          Product(
            id: '1',
            companyName: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen Updated',
            itemNumber: 'PEN-1',
            buyingPrice: 10,
            sellingPrice: 10,
            gstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => false,
          onProductSelected: (product) async => product,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('productRow-1')));
    await tester.pumpAndSettle();

    expect(service.fetchCount, 2);
    expect(find.text('Blue Pen Updated'), findsOneWidget);
  });

  testWidgets(
      'shows archived products as blocked and disables archived edit action',
      (tester) async {
    final archivedProduct = Product(
      id: '9',
      companyName: 'Acme',
      category: 'Pens',
      itemName: 'Old Pen',
      itemNumber: 'OLD-1',
      buyingPrice: 8,
      sellingPrice: 8,
      gstRate: 18,
      quantityOnHand: 0,
      lowStockThreshold: 1,
      isActive: false,
    );
    final service = FakeProductsService(products: <Product>[archivedProduct]);

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => false,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Archived products are hidden behind the Active filter by default.
    expect(find.text('Old Pen'), findsNothing);

    // Switching to the Archived filter reveals them.
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    expect(find.text('Old Pen'), findsOneWidget);
    expect(find.text('Archived'), findsWidgets);
    expect(find.text('Editing disabled for archived products'), findsOneWidget);
    expect(find.byKey(const Key('unarchiveButton-9')), findsOneWidget);
  });

  testWidgets('unarchive button restores an archived product', (tester) async {
    final archivedProduct = Product(
      id: '9',
      companyName: 'Acme',
      category: 'Pens',
      itemName: 'Old Pen',
      itemNumber: 'OLD-1',
      buyingPrice: 8,
      sellingPrice: 8,
      gstRate: 18,
      quantityOnHand: 0,
      lowStockThreshold: 1,
      isActive: false,
    );
    final service = FakeProductsService(products: <Product>[archivedProduct]);

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: service,
          onAddProduct: () async => false,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('unarchiveButton-9')));
    await tester.pumpAndSettle();

    // Confirm dialog appears, then confirm restore.
    expect(find.text('Restore product?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(service.reactivatedId, '9');
  });

  testWidgets('opens add and detail product flows through callbacks',
      (tester) async {
    final product = Product(
      id: '1',
      companyName: 'Acme',
      category: 'Pens',
      itemName: 'Blue Pen',
      itemNumber: 'PEN-1',
      buyingPrice: 10,
      sellingPrice: 10,
      gstRate: 18,
      quantityOnHand: 2,
      lowStockThreshold: 5,
      isActive: true,
    );
    Product? selectedProduct;
    var addTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: FakeProductsService(products: <Product>[product]),
          onAddProduct: () async {
            addTapped = true;
            return false;
          },
          onProductSelected: (value) async {
            selectedProduct = value;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pump();
    expect(addTapped, isTrue);

    await tester.tap(find.byKey(const Key('productRow-1')));
    await tester.pump();
    expect(selectedProduct?.id, '1');
  });

  testWidgets('list row shows all inventory summary fields', (tester) async {
    final product = Product(
      id: '1',
      companyName: 'Acme Traders',
      category: 'Pens',
      itemName: 'Blue Pen',
      itemNumber: 'PEN-1',
      buyingPrice: 8,
      sellingPrice: 10.5,
      unit: 'box',
      gstRate: 18,
      quantityOnHand: 2,
      lowStockThreshold: 5,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: FakeProductsService(products: <Product>[product]),
          onAddProduct: () async => false,
          onProductSelected: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PEN-1'), findsOneWidget);
    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Acme Traders'), findsOneWidget);
    expect(find.text('Pens'), findsOneWidget);
    expect(find.text('Stock 2 box'), findsOneWidget);
    expect(find.text('10.50'), findsOneWidget);
    expect(find.text('GST 18%'), findsOneWidget);
  });

  testWidgets('default list navigation opens product detail screen',
      (tester) async {
    final product = Product(
      id: '1',
      companyName: 'Acme',
      category: 'Pens',
      itemName: 'Blue Pen',
      itemNumber: 'PEN-1',
      buyingPrice: 8,
      sellingPrice: 10,
      gstRate: 18,
      quantityOnHand: 2,
      lowStockThreshold: 5,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: FakeProductsService(products: <Product>[product]),
          onAddProduct: () async => false,
          onProductSelected: (selected) async {
            await tester.state<NavigatorState>(find.byType(Navigator)).push(
                  MaterialPageRoute<Product>(
                    builder: (_) => ProductDetailScreen(
                      product: selected,
                      productsService: FakeProductsService(
                        products: <Product>[selected],
                      ),
                    ),
                  ),
                );
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productRow-1')));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Blue Pen'), findsWidgets);
  });
}

class FakeProductsService implements ProductsService {
  FakeProductsService({required this.products, this.error});

  final List<Product> products;
  final ApiError? error;
  ProductFilter? lastFilter;
  String? reactivatedId;

  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> archiveProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> reactivateProduct({required String id}) async {
    reactivatedId = id;
    return products.firstWhere((product) => product.id == id);
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async {
    lastFilter = filter;
    if (error != null) {
      throw error!;
    }
    return products.where((product) {
      final search = filter?.search?.toLowerCase();
      final company = filter?.companyName?.toLowerCase();
      final category = filter?.category?.toLowerCase();
      final active = filter?.active;

      final matchesActive = active == null || product.isActive == active;
      final matchesSearch = search == null || search.isEmpty
          ? true
          : product.itemName.toLowerCase().contains(search) ||
              product.itemNumber.toLowerCase().contains(search);
      final matchesCompany = company == null || company.isEmpty
          ? true
          : product.companyName.toLowerCase() == company;
      final matchesCategory = category == null || category.isEmpty
          ? true
          : product.category.toLowerCase() == category;
      return matchesActive && matchesSearch && matchesCompany && matchesCategory;
    }).toList();
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
    throw UnimplementedError();
  }
}

class SequencedProductsService implements ProductsService {
  SequencedProductsService({required this.responses});

  final List<List<Product>> responses;
  var fetchCount = 0;

  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> archiveProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> reactivateProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async {
    final index =
        fetchCount < responses.length ? fetchCount : responses.length - 1;
    fetchCount += 1;
    return responses[index];
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
    throw UnimplementedError();
  }
}
