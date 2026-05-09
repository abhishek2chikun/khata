class Product {
  const Product({
    required this.id,
    required this.companyName,
    required this.category,
    required this.itemName,
    required this.itemNumber,
    required this.buyingPrice,
    required this.sellingPrice,
    this.unit,
    required this.gstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.isActive,
  });

  final String id;
  final String companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  final double quantityOnHand;
  final double lowStockThreshold;
  final bool isActive;

  bool get isLowStock => quantityOnHand <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      companyName: _requireString(json, 'company_name'),
      category: json['category'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      itemNumber: _requireString(json, 'item_number'),
      buyingPrice: _toDouble(json['buying_price']),
      sellingPrice: _toDouble(json['selling_price']),
      unit: json['unit'] as String?,
      gstRate: _toDouble(json['gst_rate']),
      quantityOnHand: _toDouble(json['quantity_on_hand']),
      lowStockThreshold: _toDouble(json['low_stock_threshold']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Missing required product field: $key');
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
