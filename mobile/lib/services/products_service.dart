import 'dart:convert';

import '../models/product.dart';
import 'api_client.dart';

class ProductFilter {
  const ProductFilter({
    this.companyName,
    this.category,
    this.search,
    this.active,
    this.lowStockOnly,
  });

  final String? companyName;
  final String? category;
  final String? search;
  final bool? active;
  final bool? lowStockOnly;

  Map<String, String?> toQueryParameters() {
    return <String, String?>{
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
  });

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
      'quantity_on_hand': quantityOnHand,
      'low_stock_threshold': lowStockThreshold,
    };
    return json;
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
    required this.lowStockThreshold,
  });

  final String companyName;
  final String category;
  final String itemName;
  final String itemNumber;
  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
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

  @override
  Future<Product> archiveProduct({required String id}) async {
    final response = await _apiClient.delete('/products/$id');
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Product> reactivateProduct({required String id}) {
    throw UnsupportedError('Product reactivation is only available locally.');
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) async {
    final response = await _apiClient.post(
      '/products/$id/adjust-stock',
      body: input.toJson(),
    );
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
