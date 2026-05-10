import 'dart:convert';

import '../models/customer.dart';
import '../models/customer_ledger.dart';
import 'api_client.dart';

class CreateCustomerInput {
  const CreateCustomerInput({
    required this.name,
    required this.address,
    this.phone,
    this.gstin,
    this.state,
    this.stateCode,
    this.whatsappNumber,
  });

  final String name;
  final String address;
  final String? phone;
  final String? gstin;
  final String? state;
  final String? stateCode;
  final String? whatsappNumber;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'gstin': gstin,
      'state': state,
      'state_code': stateCode,
      'whatsapp_number': whatsappNumber,
    };
  }
}

class UpdateCustomerInput {
  const UpdateCustomerInput({
    required this.name,
    required this.address,
    this.phone,
    this.whatsappNumber,
    this.gstin,
    this.state,
    this.stateCode,
  });

  final String name;
  final String address;
  final String? phone;
  final String? whatsappNumber;
  final String? gstin;
  final String? state;
  final String? stateCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'whatsapp_number': whatsappNumber,
      'gstin': gstin,
      'state': state,
      'state_code': stateCode,
    };
  }
}

abstract class CustomersService {
  Future<List<Customer>> fetchCustomers({String search = ''});

  Future<Customer> createCustomer(CreateCustomerInput input);

  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  });

  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate});
}

class ApiCustomersService implements CustomersService {
  ApiCustomersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) async {
    final response = await _apiClient.post('/customers', body: input.toJson());
    return Customer.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) async {
    final response =
        await _apiClient.put('/customers/$id', body: input.toJson());
    return Customer.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) async {
    final query = onDate == null ? '' : '?on_date=$onDate';
    final response =
        await _apiClient.get('/customers/$customerId/ledger$query');
    return CustomerLedger.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async {
    final response = await _apiClient.get('/customers');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>().map(Customer.fromJson).toList();
  }
}
