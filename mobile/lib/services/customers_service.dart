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

abstract class CustomersService {
  Future<List<Customer>> fetchCustomers({String search = ''});

  Future<Customer> createCustomer(CreateCustomerInput input);

  Future<CustomerLedger> fetchCustomerLedger(String customerId);
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
  Future<CustomerLedger> fetchCustomerLedger(String customerId) async {
    final response = await _apiClient.get('/customers/$customerId/ledger');
    return CustomerLedger.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async {
    final response = await _apiClient.get('/customers');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>().map(Customer.fromJson).toList();
  }
}
