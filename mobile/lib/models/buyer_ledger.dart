import 'buyer.dart';

class BuyerLedger {
  const BuyerLedger({
    required this.buyer,
    required this.transactions,
  });

  final Buyer buyer;
  final List<BuyerLedgerTransaction> transactions;

  factory BuyerLedger.fromJson(Map<String, dynamic> json) {
    return BuyerLedger(
      buyer: Buyer.fromJson(json['buyer'] as Map<String, dynamic>),
      transactions:
          (json['transactions'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>()
              .map(BuyerLedgerTransaction.fromJson)
              .toList(),
    );
  }
}

class BuyerLedgerTransaction {
  const BuyerLedgerTransaction({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.occurredAt,
    required this.notes,
  });

  final String id;
  final String entryType;
  final String amount;
  final String occurredAt;
  final String? notes;

  factory BuyerLedgerTransaction.fromJson(Map<String, dynamic> json) {
    return BuyerLedgerTransaction(
      id: json['id'].toString(),
      entryType: json['entry_type'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0',
      occurredAt: json['occurred_at'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}
