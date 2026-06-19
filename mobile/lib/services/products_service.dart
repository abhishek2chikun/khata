import '../models/product.dart';

class ProductFilter {
  const ProductFilter({
    this.companyName,
    this.category,
    this.search,
    this.active,
    this.lowStockOnly,
    this.buyerId,
  });

  final String? companyName;
  final String? category;
  final String? search;
  final bool? active;
  final bool? lowStockOnly;
  final String? buyerId;

  Map<String, String?> toQueryParameters() {
    return <String, String?>{
      'company_name': companyName,
      'category': category,
      'search': search,
      'active': active?.toString(),
      'low_stock_only': lowStockOnly?.toString(),
      'buyer_id': buyerId,
    };
  }
}

class CreateProductInput {
  const CreateProductInput({
    required this.companyName,
    required this.category,
    required this.itemName,
    required this.itemNumber,
    required this.buyingPrice,
    required this.sellingPrice,
    this.unit,
    required this.gstRate,
    this.hsnCode,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    this.buyerId,
  });

  final String companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  final String? hsnCode;
  final double quantityOnHand;
  final double lowStockThreshold;
  final String? buyerId;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'company_name': companyName,
      'category': category,
      'item_name': itemName,
      'item_number': itemNumber,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'unit': unit,
      'gst_rate': gstRate,
      if (hsnCode != null) 'hsn_code': hsnCode,
      'quantity_on_hand': quantityOnHand,
      'low_stock_threshold': lowStockThreshold,
      if (buyerId != null) 'buyer_id': buyerId,
    };
    return json;
  }

  CreateProductInput copyWith({
    String? companyName,
    String? category,
    String? itemName,
    String? itemNumber,
    double? buyingPrice,
    double? sellingPrice,
    String? unit,
    double? gstRate,
    String? hsnCode,
    double? quantityOnHand,
    double? lowStockThreshold,
    String? buyerId,
  }) {
    return CreateProductInput(
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      itemNumber: itemNumber ?? this.itemNumber,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      gstRate: gstRate ?? this.gstRate,
      hsnCode: hsnCode ?? this.hsnCode,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      buyerId: buyerId ?? this.buyerId,
    );
  }
}

class UpdateProductInput {
  const UpdateProductInput({
    required this.companyName,
    required this.category,
    required this.itemName,
    required this.itemNumber,
    required this.buyingPrice,
    required this.sellingPrice,
    this.unit,
    required this.gstRate,
    this.hsnCode,
    required this.lowStockThreshold,
    this.buyerId,
  });

  final String companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  final String? hsnCode;
  final double lowStockThreshold;
  final String? buyerId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company_name': companyName,
      'category': category,
      'item_name': itemName,
      'item_number': itemNumber,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'unit': unit,
      'gst_rate': gstRate,
      if (hsnCode != null) 'hsn_code': hsnCode,
      'low_stock_threshold': lowStockThreshold,
      'buyer_id': buyerId,
    };
  }
}

class AdjustStockInput {
  const AdjustStockInput({
    required this.requestId,
    required this.quantityDelta,
    this.reason,
  });

  final String requestId;
  final double quantityDelta;
  final String? reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'quantity_delta': quantityDelta,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}

abstract class ProductsService {
  Future<List<Product>> fetchProducts({ProductFilter? filter});

  Future<Product> createProduct(CreateProductInput input);

  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input});

  Future<Product> archiveProduct({required String id});

  Future<Product> reactivateProduct({required String id});

  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  });
}
