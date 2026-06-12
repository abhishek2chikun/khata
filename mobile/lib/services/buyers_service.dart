import 'dart:convert';
import 'dart:math';

import '../models/buyer.dart';
import '../models/buyer_ledger.dart';
import 'api_client.dart';
import 'money_validator.dart';

class CreateBuyerInput {
  const CreateBuyerInput({
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

class UpdateBuyerInput {
  const UpdateBuyerInput({
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

class BuyerLedgerEntryInput {
  const BuyerLedgerEntryInput({
    required this.requestId,
    required this.amount,
    required this.occurredAt,
    this.notes,
  });

  final String requestId;
  final String amount;
  final String occurredAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'amount': validateMoneyAmount(amount),
      'occurred_at': occurredAt,
      'notes': notes,
    };
  }
}

class BuyerPayableAdjustmentInput extends BuyerLedgerEntryInput {
  const BuyerPayableAdjustmentInput({
    required super.requestId,
    required this.direction,
    required super.amount,
    required super.occurredAt,
    super.notes,
  });

  final String direction;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJson(),
      'direction': direction,
    };
  }
}

abstract class BuyersService {
  Future<List<Buyer>> fetchBuyers({String search = ''});

  Future<Buyer> createBuyer(CreateBuyerInput input);

  Future<Buyer> updateBuyer(
      {required String id, required UpdateBuyerInput input});

  Future<BuyerLedger> fetchBuyerLedger(String buyerId);

  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  });

  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  });

  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  });

  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  });
}

class ApiBuyersService implements BuyersService {
  ApiBuyersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Buyer> createBuyer(CreateBuyerInput input) async {
    final response = await _apiClient.post('/buyers', body: input.toJson());
    return Buyer.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Buyer> updateBuyer(
      {required String id, required UpdateBuyerInput input}) async {
    final response =
        await _apiClient.put('/buyers/$id', body: input.toJson());
    return Buyer.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Buyer>> fetchBuyers({String search = ''}) async {
    final path = search.trim().isEmpty
        ? '/buyers'
        : '/buyers?search=${Uri.encodeQueryComponent(search.trim())}';
    final response = await _apiClient.get(path);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>().map(Buyer.fromJson).toList();
  }

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) async {
    final response = await _apiClient.get('/buyers/$buyerId/ledger');
    return BuyerLedger.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {
    await _apiClient.post('/buyers/$buyerId/opening-payable',
        body: input.toJson());
  }

  @override
  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  }) async {
    await _apiClient.post('/buyers/$buyerId/payable-adjustments',
        body: input.toJson());
  }

  @override
  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {
    await _apiClient.post('/buyers/$buyerId/payments-made',
        body: input.toJson());
  }

  @override
  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {
    await _apiClient.post('/buyers/$buyerId/purchase-amounts',
        body: input.toJson());
  }
}

String generateBuyerRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
