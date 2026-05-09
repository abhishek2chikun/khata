import 'dart:convert';

import '../models/product.dart';
import 'api_client.dart';

class ProductFilter {
  const ProductFilter({
    String? companyName,
    String? company,
    this.category,
    this.search,
    this.active,
    this.lowStockOnly,
  }) : companyName = companyName ?? company;

  final String? companyName;
  String? get company => companyName;
  final String? category;
  final String? search;
  final bool? active;
  final bool? lowStockOnly;

  Map<String, String?> toQueryParameters() {
    return <String, String?>{
      'company': company,
      'company_name': companyName,
      'category': category,
      'search': search,
      'active': active == null ? null : active.toString(),
      'low_stock_only': lowStockOnly == null ? null : lowStockOnly.toString(),
    };
  }
}

class CreateProductInput {
  const CreateProductInput({
    String? companyName,
    String? company,
    required this.category,
    required this.itemName,
    String? itemNumber,
    String? itemCode,
    double? buyingPrice,
    double? sellingPrice,
    double? defaultSellingPriceExclTax,
    this.unit,
    double? gstRate,
    double? defaultGstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  })  : companyName = companyName ?? company ?? '',
        itemNumber = itemNumber ?? itemCode ?? '',
        buyingPrice =
            buyingPrice ?? sellingPrice ?? defaultSellingPriceExclTax ?? 0,
        sellingPrice = sellingPrice ?? defaultSellingPriceExclTax ?? 0,
        gstRate = gstRate ?? defaultGstRate ?? 0;

  final String companyName;
  String get company => companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  String get itemCode => itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  double get defaultSellingPriceExclTax => sellingPrice;
  double get defaultGstRate => gstRate;
  final double quantityOnHand;
  final double lowStockThreshold;

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
      'quantity_on_hand': quantityOnHand,
      'low_stock_threshold': lowStockThreshold,
    };
  }
}

class UpdateProductInput {
  const UpdateProductInput({
    String? companyName,
    String? company,
    required this.category,
    required this.itemName,
    String? itemNumber,
    String? itemCode,
    double? buyingPrice,
    double? sellingPrice,
    double? defaultSellingPriceExclTax,
    this.unit,
    double? gstRate,
    double? defaultGstRate,
    required this.lowStockThreshold,
  })  : companyName = companyName ?? company ?? '',
        itemNumber = itemNumber ?? itemCode ?? '',
        buyingPrice =
            buyingPrice ?? sellingPrice ?? defaultSellingPriceExclTax ?? 0,
        sellingPrice = sellingPrice ?? defaultSellingPriceExclTax ?? 0,
        gstRate = gstRate ?? defaultGstRate ?? 0;

  final String companyName;
  String get company => companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  String get itemCode => itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  double get defaultSellingPriceExclTax => sellingPrice;
  double get defaultGstRate => gstRate;
  final double lowStockThreshold;

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
      'low_stock_threshold': lowStockThreshold,
    };
  }
}

abstract class ProductsService {
  Future<List<Product>> fetchProducts({ProductFilter? filter});

  Future<Product> createProduct(CreateProductInput input);

  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input});
}

class ApiProductsService implements ProductsService {
  ApiProductsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    final response = await _apiClient.post('/products', body: input.toJson());
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async {
    final response = await _apiClient.get(
      '/products',
      queryParameters: filter?.toQueryParameters(),
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>().map(Product.fromJson).toList();
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) async {
    final response =
        await _apiClient.put('/products/$id', body: input.toJson());
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
