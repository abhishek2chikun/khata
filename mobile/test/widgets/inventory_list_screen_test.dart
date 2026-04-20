import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/inventory_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets('loads products, filters by search text, and shows low stock warning', (tester) async {
    final service = FakeProductsService(
      products: <Product>[
        Product(
          id: '1',
          company: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemCode: 'PEN-1',
          defaultSellingPriceExclTax: 10,
          defaultGstRate: 18,
          quantityOnHand: 2,
          lowStockThreshold: 5,
          isActive: true,
        ),
        Product(
          id: '2',
          company: 'Acme',
          category: 'Books',
          itemName: 'Ledger Book',
          itemCode: 'BOOK-1',
          defaultSellingPriceExclTax: 50,
          defaultGstRate: 12,
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
          onEditProduct: (_) async => false,
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
          company: 'Acme',
          category: 'Pens',
          itemName: 'Blue Pen',
          itemCode: 'PEN-1',
          defaultSellingPriceExclTax: 10,
          defaultGstRate: 18,
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
          onEditProduct: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('companyFilterField')), 'Acme');
    await tester.pumpAndSettle();
    expect(service.lastFilter?.company, 'Acme');

    await tester.enterText(find.byKey(const Key('categoryFilterField')), 'Pens');
    await tester.pumpAndSettle();
    expect(service.lastFilter?.category, 'Pens');
  });

  testWidgets('refreshes product list after add flow returns success', (tester) async {
    final service = SequencedProductsService(
      responses: <List<Product>>[
        <Product>[
          Product(
            id: '1',
            company: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemCode: 'PEN-1',
            defaultSellingPriceExclTax: 10,
            defaultGstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
        <Product>[
          Product(
            id: '1',
            company: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemCode: 'PEN-1',
            defaultSellingPriceExclTax: 10,
            defaultGstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
          Product(
            id: '2',
            company: 'Acme',
            category: 'Books',
            itemName: 'Ledger Book',
            itemCode: 'BOOK-1',
            defaultSellingPriceExclTax: 50,
            defaultGstRate: 12,
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
          onEditProduct: (_) async => false,
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

  testWidgets('refreshes product list after edit flow returns success', (tester) async {
    final service = SequencedProductsService(
      responses: <List<Product>>[
        <Product>[
          Product(
            id: '1',
            company: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen',
            itemCode: 'PEN-1',
            defaultSellingPriceExclTax: 10,
            defaultGstRate: 18,
            quantityOnHand: 2,
            lowStockThreshold: 5,
            isActive: true,
          ),
        ],
        <Product>[
          Product(
            id: '1',
            company: 'Acme',
            category: 'Pens',
            itemName: 'Blue Pen Updated',
            itemCode: 'PEN-1',
            defaultSellingPriceExclTax: 10,
            defaultGstRate: 18,
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
          onEditProduct: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue Pen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editProductButton-1')));
    await tester.pumpAndSettle();

    expect(service.fetchCount, 2);
    expect(find.text('Blue Pen Updated'), findsOneWidget);
  });

  testWidgets('shows archived products as blocked and disables archived edit action', (tester) async {
    final archivedProduct = Product(
      id: '9',
      company: 'Acme',
      category: 'Pens',
      itemName: 'Old Pen',
      itemCode: 'OLD-1',
      defaultSellingPriceExclTax: 8,
      defaultGstRate: 18,
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
          onEditProduct: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Editing disabled for archived products'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('editProductButton-9'))).onPressed,
      isNull,
    );
  });

  testWidgets('opens add and edit product flows through callbacks', (tester) async {
    final product = Product(
      id: '1',
      company: 'Acme',
      category: 'Pens',
      itemName: 'Blue Pen',
      itemCode: 'PEN-1',
      defaultSellingPriceExclTax: 10,
      defaultGstRate: 18,
      quantityOnHand: 2,
      lowStockThreshold: 5,
      isActive: true,
    );
    Product? editedProduct;
    var addTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryListScreen(
          productsService: FakeProductsService(products: <Product>[product]),
          onAddProduct: () async {
            addTapped = true;
            return false;
          },
          onEditProduct: (value) async {
            editedProduct = value;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pump();
    expect(addTapped, isTrue);

    await tester.tap(find.byKey(const Key('editProductButton-1')));
    await tester.pump();
    expect(editedProduct?.id, '1');
  });
}

class FakeProductsService implements ProductsService {
  FakeProductsService({required this.products, this.error});

  final List<Product> products;
  final ApiError? error;
  ProductFilter? lastFilter;

  @override
  Future<Product> createProduct(CreateProductInput input) {
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
      final company = filter?.company?.toLowerCase();
      final category = filter?.category?.toLowerCase();

      final matchesSearch = search == null || search.isEmpty
          ? true
          : product.itemName.toLowerCase().contains(search) ||
              product.itemCode.toLowerCase().contains(search);
      final matchesCompany = company == null || company.isEmpty
          ? true
          : product.company.toLowerCase() == company;
      final matchesCategory = category == null || category.isEmpty
          ? true
          : product.category.toLowerCase() == category;
      return matchesSearch && matchesCompany && matchesCategory;
    }).toList();
  }

  @override
  Future<Product> updateProduct({required String id, required UpdateProductInput input}) {
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
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async {
    final index = fetchCount < responses.length ? fetchCount : responses.length - 1;
    fetchCount += 1;
    return responses[index];
  }

  @override
  Future<Product> updateProduct({required String id, required UpdateProductInput input}) {
    throw UnimplementedError();
  }
}
