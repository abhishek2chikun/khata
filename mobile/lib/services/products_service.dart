import 'dart:convert';

import '../models/product.dart';
import 'api_client.dart';

class ProductFilter {
  const ProductFilter({
    this.company,
    this.category,
    this.search,
    this.active,
    this.lowStockOnly,
  });

  final String? company;
  final String? category;
  final String? search;
  final bool? active;
  final bool? lowStockOnly;

  Map<String, String?> toQueryParameters() {
    return <String, String?>{
      'company': company,
      'category': category,
      'search': search,
      'active': active == null ? null : active.toString(),
      'low_stock_only': lowStockOnly == null ? null : lowStockOnly.toString(),
    };
  }
}

class CreateProductInput {
  const CreateProductInput({
    required this.company,
    required this.category,
    required this.itemName,
    required this.itemCode,
    required this.defaultSellingPriceExclTax,
    required this.defaultGstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  });

  final String company;
  final String category;
  final String itemName;
  final String itemCode;
  final double defaultSellingPriceExclTax;
  final double defaultGstRate;
  final double quantityOnHand;
  final double lowStockThreshold;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company': company,
      'category': category,
      'item_name': itemName,
      'item_code': itemCode,
      'default_selling_price_excl_tax': defaultSellingPriceExclTax,
      'default_gst_rate': defaultGstRate,
      'quantity_on_hand': quantityOnHand,
      'low_stock_threshold': lowStockThreshold,
    };
  }
}

class UpdateProductInput {
  const UpdateProductInput({
    required this.company,
    required this.category,
    required this.itemName,
    required this.itemCode,
    required this.defaultSellingPriceExclTax,
    required this.defaultGstRate,
    required this.lowStockThreshold,
  });

  final String company;
  final String category;
  final String itemName;
  final String itemCode;
  final double defaultSellingPriceExclTax;
  final double defaultGstRate;
  final double lowStockThreshold;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'company': company,
      'category': category,
      'item_name': itemName,
      'item_code': itemCode,
      'default_selling_price_excl_tax': defaultSellingPriceExclTax,
      'default_gst_rate': defaultGstRate,
      'low_stock_threshold': lowStockThreshold,
    };
  }
}

abstract class ProductsService {
  Future<List<Product>> fetchProducts({ProductFilter? filter});

  Future<Product> createProduct(CreateProductInput input);

  Future<Product> updateProduct({required String id, required UpdateProductInput input});
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
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  @override
  Future<Product> updateProduct({required String id, required UpdateProductInput input}) async {
    final response = await _apiClient.put('/products/$id', body: input.toJson());
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
