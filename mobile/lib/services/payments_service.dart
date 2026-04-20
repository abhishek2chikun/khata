import 'dart:math';

import 'api_client.dart';

class RecordPaymentInput {
  const RecordPaymentInput({
    required this.requestId,
    required this.sellerId,
    required this.amount,
    required this.occurredOn,
    this.notes,
  });

  final String requestId;
  final String sellerId;
  final double amount;
  final String occurredOn;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'seller_id': sellerId,
      'amount': amount,
      'occurred_on': occurredOn,
      'notes': notes,
    };
  }
}

class OpeningBalanceInput {
  const OpeningBalanceInput({
    required this.requestId,
    required this.amount,
    required this.occurredOn,
  });

  final String requestId;
  final double amount;
  final String occurredOn;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'amount': amount,
      'occurred_on': occurredOn,
    };
  }
}

class BalanceAdjustmentInput {
  const BalanceAdjustmentInput({
    required this.requestId,
    required this.direction,
    required this.amount,
    required this.occurredOn,
    this.notes,
  });

  final String requestId;
  final String direction;
  final double amount;
  final String occurredOn;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'direction': direction,
      'amount': amount,
      'occurred_on': occurredOn,
      'notes': notes,
    };
  }
}

abstract class PaymentsService {
  Future<void> recordPayment(RecordPaymentInput input);

  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  });

  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  });
}

class ApiPaymentsService implements PaymentsService {
  ApiPaymentsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) async {
    await _apiClient.post('/sellers/$sellerId/balance-adjustment', body: input.toJson());
  }

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) async {
    await _apiClient.post('/sellers/$sellerId/opening-balance', body: input.toJson());
  }

  @override
  Future<void> recordPayment(RecordPaymentInput input) async {
    await _apiClient.post('/payments', body: input.toJson());
  }
}

String generateRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
