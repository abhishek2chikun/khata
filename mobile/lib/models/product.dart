class Product {
  const Product({
    required this.id,
    required this.companyName,
    required this.category,
    required this.itemName,
    required this.itemNumber,
    this.buyerId,
    required this.buyingPrice,
    required this.sellingPrice,
    this.unit,
    required this.gstRate,
    this.hsnCode,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    required this.isActive,
  });

  final String id;
  final String companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  final String? buyerId;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  final String? hsnCode;
  final double quantityOnHand;
  final double lowStockThreshold;
  final bool isActive;

  bool get isLowStock => quantityOnHand <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _requireString(json, 'id'),
      companyName: _requireString(json, 'company_name'),
      category: _requireString(json, 'category'),
      itemName: _requireString(json, 'item_name'),
      itemNumber: _requireString(json, 'item_number'),
      buyerId: _optionalString(json, 'buyer_id'),
      buyingPrice: _requireDouble(json, 'buying_price'),
      sellingPrice: _requireDouble(json, 'selling_price'),
      unit: json['unit'] as String?,
      gstRate: _requireDouble(json, 'gst_rate'),
      hsnCode: _optionalString(json, 'hsn_code'),
      quantityOnHand: _requireDouble(json, 'quantity_on_hand'),
      lowStockThreshold: _requireDouble(json, 'low_stock_threshold'),
      isActive: _requireBool(json, 'is_active'),
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Missing required product field: $key');
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('Invalid product field: $key');
  }

  static bool _requireBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('Missing required product field: $key');
  }

  static double _requireDouble(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key) || json[key] == null) {
      throw FormatException('Missing required product field: $key');
    }
    final value = _toDouble(json[key]);
    if (value == null) {
      throw FormatException('Invalid product field: $key');
    }
    return value;
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
