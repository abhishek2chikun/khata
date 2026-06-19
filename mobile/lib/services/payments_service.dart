import 'dart:math';

class RecordCollectionInput {
  const RecordCollectionInput({
    required this.requestId,
    required this.customerId,
    required this.amount,
    required this.occurredOn,
    this.notes,
  });

  final String requestId;
  final String customerId;
  final double amount;
  final String occurredOn;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'customer_id': customerId,
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

class CollectionGridCustomerRow {
  const CollectionGridCustomerRow({
    required this.id,
    required this.name,
    required this.pendingBalance,
    required this.existingTotals,
  });

  final String id;
  final String name;
  final double pendingBalance;
  final Map<String, double> existingTotals;

  factory CollectionGridCustomerRow.fromJson(Map<String, dynamic> json) {
    final totals = <String, double>{};
    final rawTotals = json['existing_totals'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    for (final entry in rawTotals.entries) {
      totals[entry.key] = _parseAmount(entry.value);
    }
    return CollectionGridCustomerRow(
      id: json['id'] as String,
      name: json['name'] as String,
      pendingBalance: _parseAmount(json['pending_balance']),
      existingTotals: totals,
    );
  }
}

class CollectionGridData {
  const CollectionGridData({
    required this.fromDate,
    required this.toDate,
    required this.dates,
    required this.customers,
  });

  final String fromDate;
  final String toDate;
  final List<String> dates;
  final List<CollectionGridCustomerRow> customers;

  factory CollectionGridData.fromJson(Map<String, dynamic> json) {
    return CollectionGridData(
      fromDate: json['from_date'] as String,
      toDate: json['to_date'] as String,
      dates: (json['dates'] as List<dynamic>).cast<String>(),
      customers: (json['customers'] as List<dynamic>)
          .map((row) =>
              CollectionGridCustomerRow.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BatchCollectionEntryInput {
  const BatchCollectionEntryInput({
    required this.customerId,
    required this.occurredOn,
    required this.amount,
  });

  final String customerId;
  final String occurredOn;
  final double amount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customer_id': customerId,
      'occurred_on': occurredOn,
      'amount': amount,
    };
  }
}

class BatchCollectionInput {
  const BatchCollectionInput({
    required this.requestId,
    required this.entries,
  });

  final String requestId;
  final List<BatchCollectionEntryInput> entries;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request_id': requestId,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }
}

class BatchCollectionResult {
  const BatchCollectionResult({
    required this.requestId,
    required this.entryCount,
    required this.totalAmount,
    required this.affectedCustomers,
  });

  final String requestId;
  final int entryCount;
  final double totalAmount;
  final int affectedCustomers;

  factory BatchCollectionResult.fromJson(Map<String, dynamic> json) {
    return BatchCollectionResult(
      requestId: json['request_id'] as String,
      entryCount: json['entry_count'] as int,
      totalAmount: _parseAmount(json['total_amount']),
      affectedCustomers: json['affected_customers'] as int,
    );
  }
}

double _parseAmount(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value as String);
}

abstract class PaymentsService {
  Future<void> recordCollection(RecordCollectionInput input);

  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  });

  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  });

  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  });

  Future<BatchCollectionResult> recordCollectionBatch(
      BatchCollectionInput input);
}

String generateRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
