import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_rpc_client.dart';
import 'package:internal_billing_khata_mobile/hybrid/hybrid_write_services.dart';
import 'package:internal_billing_khata_mobile/models/buyer.dart';
import 'package:internal_billing_khata_mobile/models/buyer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/services/buyers_service.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';

void main() {
  test('product create uses RPC and does not call local write service',
      () async {
    final rpc = _FakeRpcExecutor({
      'create_product': _productRow(),
    });
    var refreshes = 0;
    final service = HybridProductsService(
      localProductsService: _ThrowingProductsService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );

    final created = await service.createProduct(
      const CreateProductInput(
        companyName: 'Acme',
        category: 'General',
        itemName: 'Widget',
        itemNumber: 'W-1',
        buyingPrice: 10,
        sellingPrice: 12,
        gstRate: 18,
        quantityOnHand: 5,
        lowStockThreshold: 1,
      ),
    );

    expect(created.id, 'product-1');
    expect(refreshes, 1);
    expect(rpc.calls.single.functionName, 'create_product');
    expect(rpc.calls.single.params, contains('p_request_id'));
    expect(rpc.calls.single.params, contains('p_request_hash'));
    expect(rpc.calls.single.params['p_product'],
        containsPair('id', isA<String>()));
  });

  test('customer and buyer writes use RPC wrappers', () async {
    final rpc = _FakeRpcExecutor({
      'create_customer': _customerRow(),
      'create_buyer': _buyerRow(),
    });
    var refreshes = 0;
    final customers = HybridCustomersService(
      localCustomersService: _ThrowingCustomersService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );
    final buyers = HybridBuyersService(
      localBuyersService: _ThrowingBuyersService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );

    await customers.createCustomer(
      const CreateCustomerInput(name: 'Shop', address: 'Road'),
    );
    await buyers.createBuyer(
      const CreateBuyerInput(name: 'Supplier', address: 'Lane'),
    );

    expect(rpc.calls.map((call) => call.functionName), [
      'create_customer',
      'create_buyer',
    ]);
    expect(refreshes, 2);
  });

  test('payments and buyer ledger writes preserve caller request IDs',
      () async {
    final rpc = _FakeRpcExecutor({
      'record_collection': <String, dynamic>{'id': 'ct-1'},
      'record_buyer_ledger_entry': <String, dynamic>{'id': 'bt-1'},
    });
    var refreshes = 0;
    final payments = HybridPaymentsService(
      localPaymentsService: _ThrowingPaymentsService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );
    final buyers = HybridBuyersService(
      localBuyersService: _ThrowingBuyersService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );

    await payments.recordCollection(
      const RecordCollectionInput(
        requestId: '11111111-1111-4111-8111-111111111111',
        customerId: 'customer-1',
        amount: 10,
        occurredOn: '2026-06-18',
      ),
    );
    await buyers.addPaymentMade(
      buyerId: 'buyer-1',
      input: const BuyerLedgerEntryInput(
        requestId: '22222222-2222-4222-8222-222222222222',
        amount: '12.00',
        occurredAt: '2026-06-18T00:00:00.000Z',
      ),
    );

    expect(rpc.calls[0].params['p_request_id'],
        '11111111-1111-4111-8111-111111111111');
    expect(rpc.calls[1].params['p_request_id'],
        '22222222-2222-4222-8222-222222222222');
    expect(rpc.calls[1].params['p_entry'],
        containsPair('entry_type', 'PAYMENT_MADE'));
    expect(refreshes, 2);
  });

  test('company profile upsert uses RPC', () async {
    final rpc = _FakeRpcExecutor({
      'upsert_company_profile': _companyProfileRow(),
    });
    var refreshes = 0;
    final service = HybridCompanyProfileService(
      localCompanyProfileService: _ThrowingCompanyProfileService(),
      rpcClient: rpc,
      refreshAfterWrite: (_, __) async => refreshes++,
    );

    final profile = await service.upsertCompanyProfile(
      const UpsertCompanyProfileInput(
        name: 'Khata Co',
        address: 'Road',
        city: 'City',
        state: 'State',
        stateCode: '27',
      ),
    );

    expect(profile.id, 'company-1');
    expect(rpc.calls.single.functionName, 'upsert_company_profile');
    expect(refreshes, 1);
  });
}

class _FakeRpcExecutor implements HybridRpcExecutor {
  _FakeRpcExecutor(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<_RpcCall> calls = [];

  @override
  Future<Map<String, dynamic>> invokeWrite(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    calls.add(_RpcCall(functionName, params));
    return responses[functionName] ?? <String, dynamic>{};
  }
}

class _RpcCall {
  const _RpcCall(this.functionName, this.params);

  final String functionName;
  final Map<String, dynamic> params;
}

class _ThrowingProductsService implements ProductsService {
  @override
  Future<Product> archiveProduct({required String id}) => _localWrite();

  @override
  Future<Product> createProduct(CreateProductInput input) => _localWrite();

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async =>
      [_product()];

  @override
  Future<Product> reactivateProduct({required String id}) => _localWrite();

  @override
  Future<Product> updateProduct(
          {required String id, required UpdateProductInput input}) =>
      _localWrite();

  @override
  Future<Product> adjustStock(
          {required String id, required AdjustStockInput input}) =>
      _localWrite();
}

class _ThrowingCustomersService implements CustomersService {
  @override
  Future<Customer> createCustomer(CreateCustomerInput input) => _localWrite();

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async => const [];

  @override
  Future<Customer> updateCustomer(
          {required String id, required UpdateCustomerInput input}) =>
      _localWrite();
}

class _ThrowingBuyersService implements BuyersService {
  @override
  Future<void> addOpeningPayable(
          {required String buyerId, required BuyerLedgerEntryInput input}) =>
      _localWrite();

  @override
  Future<void> addPayableAdjustment(
          {required String buyerId,
          required BuyerPayableAdjustmentInput input}) =>
      _localWrite();

  @override
  Future<void> addPaymentMade(
          {required String buyerId, required BuyerLedgerEntryInput input}) =>
      _localWrite();

  @override
  Future<void> addPurchaseAmount(
          {required String buyerId, required BuyerLedgerEntryInput input}) =>
      _localWrite();

  @override
  Future<Buyer> createBuyer(CreateBuyerInput input) => _localWrite();

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Buyer>> fetchBuyers({String search = ''}) async => const [];

  @override
  Future<Buyer> updateBuyer(
          {required String id, required UpdateBuyerInput input}) =>
      _localWrite();
}

class _ThrowingCompanyProfileService implements CompanyProfileService {
  @override
  Future<CompanyProfile> fetchCompanyProfile() {
    throw UnimplementedError();
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(
          UpsertCompanyProfileInput input) =>
      _localWrite();
}

class _ThrowingPaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment(
          {required String customerId,
          required BalanceAdjustmentInput input}) =>
      _localWrite();

  @override
  Future<void> addOpeningBalance(
          {required String customerId, required OpeningBalanceInput input}) =>
      _localWrite();

  @override
  Future<CollectionGridData> loadCollectionGrid(
      {required String fromDate, required String toDate}) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) => _localWrite();

  @override
  Future<BatchCollectionResult> recordCollectionBatch(
          BatchCollectionInput input) =>
      _localWrite();
}

Future<T> _localWrite<T>() {
  throw StateError('local write should not be called in hybrid mode');
}

Product _product() => Product.fromJson(_productRow());

Map<String, dynamic> _productRow() => <String, dynamic>{
      'id': 'product-1',
      'company_name': 'Acme',
      'category': 'General',
      'item_name': 'Widget',
      'item_number': 'W-1',
      'buyer_id': null,
      'buying_price': '10.000',
      'selling_price': '12.000',
      'unit': null,
      'gst_rate': '18.00',
      'hsn_code': null,
      'quantity_on_hand': '5',
      'low_stock_threshold': '1',
      'is_active': true,
    };

Map<String, dynamic> _customerRow() => <String, dynamic>{
      'id': 'customer-1',
      'name': 'Shop',
      'address': 'Road',
      'phone': null,
      'gstin': null,
      'state': null,
      'state_code': null,
      'is_active': true,
      'pending_balance': '0',
      'whatsapp_number': null,
    };

Map<String, dynamic> _buyerRow() => <String, dynamic>{
      'id': 'buyer-1',
      'name': 'Supplier',
      'address': 'Lane',
      'phone': null,
      'gstin': null,
      'state': null,
      'state_code': null,
      'is_active': true,
      'pending_payable': '0',
      'whatsapp_number': null,
    };

Map<String, dynamic> _companyProfileRow() => <String, dynamic>{
      'id': 'company-1',
      'name': 'Khata Co',
      'address': 'Road',
      'city': 'City',
      'state': 'State',
      'state_code': '27',
      'gstin': null,
      'gst_flag': false,
      'phone': null,
      'email': null,
      'bank_name': null,
      'bank_account': null,
      'bank_ifsc': null,
      'bank_branch': null,
      'jurisdiction': null,
      'is_active': true,
    };
