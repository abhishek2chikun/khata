import '../models/customer.dart';
import '../models/customer_ledger.dart';

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
