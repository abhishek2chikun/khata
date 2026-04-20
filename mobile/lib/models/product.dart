class Product {
  const Product({
    required this.id,
    required this.company,
    required this.category,
    required this.itemName,
    required this.itemCode,
    required this.defaultSellingPriceExclTax,
    required this.defaultGstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.isActive,
  });

  final String id;
  final String company;
  final String category;
  final String itemName;
  final String itemCode;
  final double defaultSellingPriceExclTax;
  final double defaultGstRate;
  final double quantityOnHand;
  final double lowStockThreshold;
  final bool isActive;

  bool get isLowStock => quantityOnHand <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      company: json['company'] as String? ?? '',
      category: json['category'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      defaultSellingPriceExclTax: _toDouble(json['default_selling_price_excl_tax']),
      defaultGstRate: _toDouble(json['default_gst_rate']),
      quantityOnHand: _toDouble(json['quantity_on_hand']),
      lowStockThreshold: _toDouble(json['low_stock_threshold']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
