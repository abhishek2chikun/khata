import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/buyer.dart' as buyer_model;
import '../models/buyer_ledger.dart';
import '../services/buyers_service.dart';
import '../services/money_validator.dart';
import 'local_database.dart';
import 'local_sellers_service.dart';

class LocalBuyersService implements BuyersService {
  LocalBuyersService({required LocalDatabase database}) : _database = database;

  static const _systemUserId = 'local-system-user';

  final LocalDatabase _database;

  @override
  Future<buyer_model.Buyer> createBuyer(CreateBuyerInput input) async {
    await _throwIfDuplicate(name: input.name, phone: input.phone);

    final now = DateTime.now().toUtc().toIso8601String();
    final id = generateLocalUuid();
    try {
      await _database.into(_database.buyers).insert(
            BuyersCompanion.insert(
              id: id,
              name: input.name,
              address: input.address,
              phone: Value(input.phone),
              gstin: Value(input.gstin),
              state: Value(input.state),
              stateCode: Value(input.stateCode),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object catch (error) {
      if (await _hasDuplicate(name: input.name, phone: input.phone)) {
        throw _duplicateBuyerError();
      }
      throw error;
    }

    final buyer = await (_database.select(_database.buyers)
          ..where((buyer) => buyer.id.equals(id)))
        .getSingle();
    return _toBuyer(buyer, pendingPayable: 0);
  }

  @override
  Future<List<buyer_model.Buyer>> fetchBuyers({String search = ''}) async {
    final query = _database.select(_database.buyers)
      ..orderBy([
        (buyer) => OrderingTerm.asc(buyer.name),
      ]);
    var buyers = await query.get();
    if (search.isNotEmpty) {
      final normalizedSearch = search.toLowerCase();
      buyers = buyers
          .where(
            (buyer) =>
                buyer.name.toLowerCase().contains(normalizedSearch) ||
                buyer.address.toLowerCase().contains(normalizedSearch) ||
                (buyer.phone?.toLowerCase().contains(normalizedSearch) ??
                    false) ||
                (buyer.gstin?.toLowerCase().contains(normalizedSearch) ??
                    false),
          )
          .toList();
    }

    final balances = await _pendingPayablesByBuyerId();
    return buyers
        .map(
          (buyer) => _toBuyer(
            buyer,
            pendingPayable: balances[buyer.id] ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) async {
    final buyer = await _getBuyer(buyerId);
    final transactions = await (_database.select(_database.buyerTransactions)
          ..where((transaction) => transaction.buyerId.equals(buyerId))
          ..orderBy([
            (transaction) => OrderingTerm.asc(transaction.occurredAt),
            (transaction) => OrderingTerm.asc(transaction.createdAt),
          ]))
        .get();
    final pendingPayable = _pendingPayable(transactions);
    return BuyerLedger(
      buyer: _toBuyer(buyer, pendingPayable: pendingPayable),
      transactions: transactions.map(_toLedgerTransaction).toList(),
    );
  }

  @override
  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _insertTransaction(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'OPENING_PAYABLE',
      amount: input.amount,
      occurredAt: input.occurredAt,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _insertTransaction(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'PURCHASE_AMOUNT',
      amount: input.amount,
      occurredAt: input.occurredAt,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) {
    return _insertTransaction(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: 'PAYMENT_MADE',
      amount: input.amount,
      occurredAt: input.occurredAt,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  }) {
    final entryType = switch (input.direction) {
      'INCREASE' => 'PAYABLE_INCREASE_ADJUSTMENT',
      'DECREASE' => 'PAYABLE_DECREASE_ADJUSTMENT',
      _ => throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'direction must be INCREASE or DECREASE',
          statusCode: 422,
        ),
    };
    return _insertTransaction(
      buyerId: buyerId,
      requestId: input.requestId,
      entryType: entryType,
      amount: input.amount,
      occurredAt: input.occurredAt,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  Future<void> _insertTransaction({
    required String buyerId,
    required String requestId,
    required String entryType,
    required String amount,
    required String occurredAt,
    required String? notes,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureActiveBuyer(buyerId);
    _validateRequestId(requestId);
    _validateOccurredAt(occurredAt);
    final normalizedAmount = validateMoneyAmount(amount);

    final requestHash = _entryHash(<String, dynamic>{
      'buyer_id': buyerId,
      'entry_type': entryType,
      ...payload,
    });
    final existing = await (_database.select(_database.buyerTransactions)
          ..where((transaction) => transaction.requestId.equals(requestId)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.requestHash != requestHash) {
        throw _idempotencyConflictError();
      }
      return;
    }
    if (entryType == 'OPENING_PAYABLE' &&
        await _hasOpeningPayable(buyerId: buyerId)) {
      throw _openingPayableExistsError();
    }
    await _ensureSystemUser();

    try {
      await _database.into(_database.buyerTransactions).insert(
            BuyerTransactionsCompanion.insert(
              id: generateLocalUuid(),
              buyerId: buyerId,
              requestId: Value(requestId),
              requestHash: Value(requestHash),
              openingPayableBuyerId: Value(
                entryType == 'OPENING_PAYABLE' ? buyerId : null,
              ),
              entryType: entryType,
              amount: normalizedAmount,
              occurredAt: occurredAt,
              notes: Value(notes),
              createdByUserId: _systemUserId,
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
    } on Object catch (error) {
      final existing = await (_database.select(_database.buyerTransactions)
            ..where((transaction) => transaction.requestId.equals(requestId)))
          .getSingleOrNull();
      if (existing != null && existing.requestHash == requestHash) {
        return;
      }
      if (entryType == 'OPENING_PAYABLE' &&
          await _hasOpeningPayable(buyerId: buyerId)) {
        throw _openingPayableExistsError();
      }
      throw error;
    }
  }

  Future<Buyer> _getBuyer(String buyerId) async {
    final buyer = await (_database.select(_database.buyers)
          ..where((buyer) => buyer.id.equals(buyerId)))
        .getSingleOrNull();
    if (buyer == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Buyer not found',
        statusCode: 404,
      );
    }
    return buyer;
  }

  Future<void> _ensureActiveBuyer(String buyerId) async {
    final buyer = await _getBuyer(buyerId);
    if (!buyer.isActive) {
      throw const ApiError(
        code: 'BUYER_ARCHIVED',
        message: 'Archived buyer cannot be updated',
        statusCode: 400,
      );
    }
  }

  Future<void> _throwIfDuplicate({required String name, String? phone}) async {
    if (await _hasDuplicate(name: name, phone: phone)) {
      throw _duplicateBuyerError();
    }
  }

  Future<bool> _hasDuplicate({required String name, String? phone}) async {
    if (phone == null) {
      return false;
    }
    final duplicates = await (_database.select(_database.buyers)
          ..where(
            (buyer) => buyer.name.equals(name) & buyer.phone.equals(phone),
          ))
        .get();
    return duplicates.isNotEmpty;
  }

  Future<bool> _hasOpeningPayable({required String buyerId}) async {
    final openingPayable = await (_database.select(_database.buyerTransactions)
          ..where(
            (transaction) =>
                transaction.buyerId.equals(buyerId) &
                transaction.entryType.equals('OPENING_PAYABLE'),
          ))
        .getSingleOrNull();
    return openingPayable != null;
  }

  Future<Map<String, double>> _pendingPayablesByBuyerId() async {
    final transactions =
        await _database.select(_database.buyerTransactions).get();
    final balances = <String, double>{};
    for (final transaction in transactions) {
      balances.update(
        transaction.buyerId,
        (balance) => balance + _signedAmount(transaction),
        ifAbsent: () => _signedAmount(transaction),
      );
    }
    return balances;
  }

  double _pendingPayable(List<BuyerTransaction> transactions) {
    return transactions.fold<double>(
      0,
      (balance, transaction) => balance + _signedAmount(transaction),
    );
  }

  double _signedAmount(BuyerTransaction transaction) {
    final amount = double.parse(transaction.amount);
    return switch (transaction.entryType) {
      'OPENING_PAYABLE' ||
      'PURCHASE_AMOUNT' ||
      'PAYABLE_INCREASE_ADJUSTMENT' =>
        amount,
      _ => -amount,
    };
  }

  buyer_model.Buyer _toBuyer(Buyer buyer, {required double pendingPayable}) {
    return buyer_model.Buyer(
      id: buyer.id,
      name: buyer.name,
      address: buyer.address,
      phone: buyer.phone,
      gstin: buyer.gstin,
      state: buyer.state,
      stateCode: buyer.stateCode,
      isActive: buyer.isActive,
      pendingPayable: pendingPayable,
    );
  }

  BuyerLedgerTransaction _toLedgerTransaction(BuyerTransaction transaction) {
    return BuyerLedgerTransaction(
      id: transaction.id,
      entryType: transaction.entryType,
      amount: transaction.amount,
      occurredAt: transaction.occurredAt,
      notes: transaction.notes,
    );
  }

  Future<void> _ensureSystemUser() async {
    final existing = await (_database.select(_database.localUsers)
          ..where((user) => user.id.equals(_systemUserId)))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.localUsers).insert(
          LocalUsersCompanion.insert(
            id: _systemUserId,
            username: 'local-system',
            passwordHash: 'not-used',
            displayName: const Value('Local System'),
            salt: 'not-used',
            passwordHashVersion: 1,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  void _validateRequestId(String requestId) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuidPattern.hasMatch(requestId)) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'request_id must be a valid UUID',
        statusCode: 422,
      );
    }
  }

  void _validateOccurredAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !_hasTimezone(value)) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'occurred_at must include timezone information',
        statusCode: 422,
      );
    }
  }

  bool _hasTimezone(String value) {
    return value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
  }

  String _entryHash(Map<String, dynamic> payload) {
    final sorted = Map<String, dynamic>.fromEntries(
      payload.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
    return sha256.convert(utf8.encode(jsonEncode(sorted))).toString();
  }

  ApiError _duplicateBuyerError() {
    return const ApiError(
      code: 'DUPLICATE_BUYER',
      message: 'Buyer already exists',
      statusCode: 409,
    );
  }

  ApiError _openingPayableExistsError() {
    return const ApiError(
      code: 'OPENING_PAYABLE_EXISTS',
      message: 'Opening payable already exists',
      statusCode: 409,
    );
  }

  ApiError _idempotencyConflictError() {
    return const ApiError(
      code: 'IDEMPOTENCY_CONFLICT',
      message: 'request_id already used with different payload',
      statusCode: 409,
    );
  }
}
