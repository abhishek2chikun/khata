import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';

void main() {
  group('Product canonical JSON', () {
    test('requires canonical V2 fields', () {
      for (final key in <String>[
        'id',
        'company_name',
        'category',
        'item_name',
        'item_number',
        'buying_price',
        'selling_price',
        'gst_rate',
        'quantity_on_hand',
        'low_stock_threshold',
        'is_active',
      ]) {
        expect(
          () => Product.fromJson(_productJson()..remove(key)),
          throwsA(isA<FormatException>()),
          reason: '$key should be required',
        );
      }
    });

    test('preserves nullable buyer id', () {
      final product = Product.fromJson(
        _productJson(buyerId: '11111111-1111-4111-8111-111111111111'),
      );

      expect(product.buyerId, '11111111-1111-4111-8111-111111111111');
      expect(Product.fromJson(_productJson()).buyerId, isNull);
    });

    test('rejects invalid canonical numeric fields', () {
      expect(
        () => Product.fromJson(_productJson()..['buying_price'] = 'invalid'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _productJson({String? buyerId}) {
  return <String, dynamic>{
    'id': 'p1',
    'company_name': 'Acme',
    'category': 'Pens',
    'item_name': 'Blue Pen',
    'item_number': 'PEN-1',
    'buyer_id': buyerId,
    'buying_price': '8',
    'selling_price': '10',
    'unit': null,
    'gst_rate': '18',
    'quantity_on_hand': '5',
    'low_stock_threshold': '2',
    'is_active': true,
  };
}
