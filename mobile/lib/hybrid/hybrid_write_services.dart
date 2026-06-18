import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/buyer.dart';
import '../models/buyer_ledger.dart';
import '../models/company_profile.dart';
import '../models/customer.dart';
import '../models/customer_ledger.dart';
import '../models/product.dart';
import '../services/buyers_service.dart';
import '../services/company_profile_service.dart';
import '../services/customers_service.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import 'hybrid_rpc_client.dart';

typedef HybridRefresh = Future<void> Function();

class HybridProductsService implements ProductsService {
  HybridProductsService({
    required ProductsService localProductsService,
    required HybridRpcExecutor rpcClient,
    required HybridRefresh refreshAfterWrite,
  })  : _localProductsService = localProductsService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final ProductsService _localProductsService;
  final HybridRpcExecutor _rpcClient;
  final HybridRefresh _refreshAfterWrite;

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) {
    return _localProductsService.fetchProducts(filter: filter);
  }

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    final payload = input.toJson();
    payload['id'] = _generateUuid();
    final row = await _invokeRow('create_product', payload);
    return Product.fromJson(row);
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductInput input,
  }) async {
    final payload = input.toJson();
    payload['id'] = id;
    final row = await _invokeRow('update_product', payload);
    return Product.fromJson(row);
  }

  @override
  Future<Product> archiveProduct({required String id}) async {
    final row = await _invokeIdRow('archive_product', 'p_product_id', id);
    return Product.fromJson(row);
  }

  @override
  Future<Product> reactivateProduct({required String id}) async {
    final row = await _invokeIdRow('reactivate_product', 'p_product_id', id);
    return Product.fromJson(row);
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) async {
    final payload = input.toJson();
    payload['product_id'] = id;
    final result = await _rpcClient.invokeWrite(
      'adjust_stock',
      _params(
        requestId: input.requestId,
        payload: payload,
        payloadParam: 'p_adjustment',
      ),
    );
    await _refreshAfterWrite();
    final products = await _localProductsService.fetchProducts(
      filter: const ProductFilter(active: null),
    );
    return products.firstWhere(
      (product) => product.id == id,
      orElse: () => Product.fromJson(
        Map<String, dynamic>.from(result['product'] as Map),
      ),
    );
  }

  Future<Map<String, dynamic>> _invokeRow(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final result = await _rpcClient.invokeWrite(
      functionName,
      _params(
        requestId: _generateUuid(),
        payload: payload,
        payloadParam: 'p_product',
      ),
    );
    await _refreshAfterWrite();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> _invokeIdRow(
    String functionName,
    String idParam,
    String id,
  ) async {
    final payload = <String, dynamic>{idParam: id};
    final result = await _rpcClient.invokeWrite(
      functionName,
      <String, dynamic>{
        'p_request_id': _generateUuid(),
        'p_request_hash': _hash(payload),
        idParam: id,
      },
    );
    await _refreshAfterWrite();
    return Map<String, dynamic>.from(result);
  }
}

class HybridCustomersService implements CustomersService {
  HybridCustomersService({
    required CustomersService localCustomersService,
    required HybridRpcExecutor rpcClient,
    required HybridRefresh refreshAfterWrite,
  })  : _localCustomersService = localCustomersService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final CustomersService _localCustomersService;
  final HybridRpcExecutor _rpcClient;
  final HybridRefresh _refreshAfterWrite;

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) {
    return _localCustomersService.fetchCustomers(search: search);
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) {
    return _localCustomersService.fetchCustomerLedger(customerId,
        onDate: onDate);
  }

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) async {
    final payload = input.toJson();
    payload['id'] = _generateUuid();
    final row = await _invokeCustomer('create_customer', payload);
    return Customer.fromJson(row);
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) async {
    final payload = input.toJson();
    payload['id'] = id;
    final row = await _invokeCustomer('update_customer', payload);
    return Customer.fromJson(row);
  }

  Future<Map<String, dynamic>> _invokeCustomer(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final result = await _rpcClient.invokeWrite(
      functionName,
      _params(
        requestId: _generateUuid(),
        payload: payload,
        payloadParam: 'p_customer',
      ),
    );
    await _refreshAfterWrite();
    return Map<String, dynamic>.from(result);
  }
}

class HybridBuyersService implements BuyersService {
  HybridBuyersService({
    required BuyersService localBuyersService,
    required HybridRpcExecutor rpcClient,
    required HybridRefresh refreshAfterWrite,
  })  : _localBuyersService = localBuyersService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final BuyersService _localBuyersService;
  final HybridRpcExecutor _rpcClient;
  final HybridRefresh _refreshAfterWrite;

  @override
  Future<List<Buyer>> fetchBuyers({String search = ''}) {
    return _localBuyersService.fetchBuyers(search: search);
  }

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) {
    return _localBuyersService.fetchBuyerLedger(buyerId);
  }

  @override
  Future<Buyer> createBuyer(CreateBuyerInput input) async {
    final payload = input.toJson();
    payload['id'] = _generateUuid();
    final row = await _invokeBuyer('create_buyer', payload);
    return Buyer.fromJson(row);
  }

  @override
  Future<Buyer> updateBuyer({
    required String id,
    required UpdateBuyerInput input,
  }) async {
    final payload = input.toJson();
    payload['id'] = id;
    final row = await _invokeBuyer('update_buyer', payload);
    return Buyer.fromJson(row);
  }

  @override
  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _addLedgerEntry(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'OPENING_PAYABLE',
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _addLedgerEntry(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'PURCHASE_AMOUNT',
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _addLedgerEntry(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'PAYMENT_MADE',
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  }) {
    final entryType = input.direction == 'INCREASE'
        ? 'PAYABLE_INCREASE_ADJUSTMENT'
        : 'PAYABLE_DECREASE_ADJUSTMENT';
    return _addLedgerEntry(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: entryType,
      payload: input.toJson(),
    );
  }

  Future<Map<String, dynamic>> _invokeBuyer(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final result = await _rpcClient.invokeWrite(
      functionName,
      _params(
        requestId: _generateUuid(),
        payload: payload,
        payloadParam: 'p_buyer',
      ),
    );
    await _refreshAfterWrite();
    return Map<String, dynamic>.from(result);
  }

  Future<void> _addLedgerEntry({
    required String buyerId,
    required String requestId,
    required String entryType,
    required Map<String, dynamic> payload,
  }) async {
    final entry = <String, dynamic>{
      ...payload,
      'buyer_id': buyerId,
      'entry_type': entryType,
    };
    await _rpcClient.invokeWrite(
      'record_buyer_ledger_entry',
      _params(
        requestId: requestId,
        payload: entry,
        payloadParam: 'p_entry',
      ),
    );
    await _refreshAfterWrite();
  }
}

class HybridCompanyProfileService implements CompanyProfileService {
  HybridCompanyProfileService({
    required CompanyProfileService localCompanyProfileService,
    required HybridRpcExecutor rpcClient,
    required HybridRefresh refreshAfterWrite,
  })  : _localCompanyProfileService = localCompanyProfileService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final CompanyProfileService _localCompanyProfileService;
  final HybridRpcExecutor _rpcClient;
  final HybridRefresh _refreshAfterWrite;

  @override
  Future<CompanyProfile> fetchCompanyProfile() {
    return _localCompanyProfileService.fetchCompanyProfile();
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(
    UpsertCompanyProfileInput input,
  ) async {
    final payload = input.toJson();
    final result = await _rpcClient.invokeWrite(
      'upsert_company_profile',
      _params(
        requestId: _generateUuid(),
        payload: payload,
        payloadParam: 'p_profile',
      ),
    );
    await _refreshAfterWrite();
    return CompanyProfile.fromJson(Map<String, dynamic>.from(result));
  }
}

class HybridPaymentsService implements PaymentsService {
  HybridPaymentsService({
    required PaymentsService localPaymentsService,
    required HybridRpcExecutor rpcClient,
    required HybridRefresh refreshAfterWrite,
  })  : _localPaymentsService = localPaymentsService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final PaymentsService _localPaymentsService;
  final HybridRpcExecutor _rpcClient;
  final HybridRefresh _refreshAfterWrite;

  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) {
    return _localPaymentsService.loadCollectionGrid(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {
    await _rpcClient.invokeWrite(
      'record_collection',
      _params(
        requestId: input.requestId,
        payload: input.toJson(),
        payloadParam: 'p_collection',
      ),
    );
    await _refreshAfterWrite();
  }

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) {
    return _recordCustomerLedgerEntry(
      customerId: customerId,
      requestId: input.requestId,
      entryType: 'OPENING_BALANCE',
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) {
    final entryType = input.direction == 'INCREASE'
        ? 'BALANCE_INCREASE_ADJUSTMENT'
        : 'BALANCE_DECREASE_ADJUSTMENT';
    return _recordCustomerLedgerEntry(
      customerId: customerId,
      requestId: input.requestId,
      entryType: entryType,
      payload: input.toJson(),
    );
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(
    BatchCollectionInput input,
  ) async {
    final result = await _rpcClient.invokeWrite(
      'record_batch_collections',
      _params(
        requestId: input.requestId,
        payload: input.toJson(),
        payloadParam: 'p_batch',
      ),
    );
    await _refreshAfterWrite();
    return BatchCollectionResult.fromJson(result);
  }

  Future<void> _recordCustomerLedgerEntry({
    required String customerId,
    required String requestId,
    required String entryType,
    required Map<String, dynamic> payload,
  }) async {
    final entry = <String, dynamic>{
      ...payload,
      'customer_id': customerId,
      'entry_type': entryType,
    };
    await _rpcClient.invokeWrite(
      'record_customer_ledger_entry',
      _params(
        requestId: requestId,
        payload: entry,
        payloadParam: 'p_entry',
      ),
    );
    await _refreshAfterWrite();
  }
}

Map<String, dynamic> _params({
  required String requestId,
  required Map<String, dynamic> payload,
  required String payloadParam,
}) {
  return <String, dynamic>{
    'p_request_id': requestId,
    'p_request_hash': _hash(payload),
    payloadParam: payload,
  };
}

String _hash(Map<String, dynamic> payload) {
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

String _generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
