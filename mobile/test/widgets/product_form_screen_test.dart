import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/screens/product_form_screen.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  testWidgets('edit form hides unsupported stock and archive controls', (tester) async {
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
  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw ApiError(message: 'not used');
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    throw ApiError(message: 'not used');
  }

  @override
  Future<Product> updateProduct({required String id, required UpdateProductInput input}) {
    throw ApiError(message: 'not used');
  }
}
