import 'dart:convert';

import '../models/seller.dart';
import '../models/seller_ledger.dart';
import 'api_client.dart';

class CreateSellerInput {
  const CreateSellerInput({
    required this.name,
    required this.address,
    this.phone,
    this.gstin,
    this.state,
    this.stateCode,
  });

  final String name;
  final String address;
  final String? phone;
  final String? gstin;
  final String? state;
  final String? stateCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'gstin': gstin,
      'state': state,
      'state_code': stateCode,
    };
  }
}

abstract class SellersService {
  Future<List<Seller>> fetchSellers({String search = ''});

  Future<Seller> createSeller(CreateSellerInput input);

  Future<SellerLedger> fetchSellerLedger(String sellerId);
}

class ApiSellersService implements SellersService {
  ApiSellersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Seller> createSeller(CreateSellerInput input) async {
    final response = await _apiClient.post('/sellers', body: input.toJson());
    return Seller.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) async {
    final response = await _apiClient.get('/sellers/$sellerId/ledger');
    return SellerLedger.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Seller>> fetchSellers({String search = ''}) async {
    final response = await _apiClient.get('/sellers');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>().map(Seller.fromJson).toList();
  }
}
