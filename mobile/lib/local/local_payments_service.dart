import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../services/money_validator.dart';
import '../services/payments_service.dart';
import 'local_database.dart';
import 'local_customers_service.dart';

class LocalPaymentsService implements PaymentsService {
  LocalPaymentsService({required LocalDatabase database})
      : _database = database;

  static const _systemUserId = 'local-system-user';

  final LocalDatabase _database;

  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) async {
    final entryType = switch (input.direction) {
      'INCREASE' => 'BALANCE_INCREASE_ADJUSTMENT',
      'DECREASE' => 'BALANCE_DECREASE_ADJUSTMENT',
      _ => throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'direction must be INCREASE or DECREASE',
          statusCode: 422,
        ),
    };
    await _insertManualTransaction(
      customerId: customerId,
      requestId: input.requestId,
      entryType: entryType,
      amount: input.amount,
      occurredOn: input.occurredOn,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) async {
    await _insertManualTransaction(
      customerId: customerId,
      requestId: input.requestId,
      entryType: 'OPENING_BALANCE',
      amount: input.amount,
      occurredOn: input.occurredOn,
      notes: null,
      payload: input.toJson(),
    );
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {
    await _insertManualTransaction(
      customerId: input.customerId,
      requestId: input.requestId,
      entryType: 'COLLECTION',
      amount: input.amount,
      occurredOn: input.occurredOn,
      notes: input.notes,
      payload: input.toJson(),
    );
  }

  Future<void> _insertManualTransaction({
    required String customerId,
    required String requestId,
    required String entryType,
    required double amount,
    required String occurredOn,
    required String? notes,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureActiveCustomer(customerId);
    _validateRequestId(requestId);
    _validateDateOnly(occurredOn);
    _validatePositiveAmount(amount);

    final requestHash = _entryHash(<String, dynamic>{
      'customer_id': customerId,
      'entry_type': entryType,
      ...payload,
    });
    final existing = await (_database.select(_database.customerTransactions)
          ..where((transaction) => transaction.requestId.equals(requestId)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.requestHash != requestHash) {
        throw _idempotencyConflictError();
      }
      return;
    }
    if (entryType == 'OPENING_BALANCE' &&
        await _hasOpeningBalance(customerId: customerId)) {
      throw const ApiError(
        code: 'OPENING_BALANCE_EXISTS',
        message: 'Opening balance already exists',
        statusCode: 409,
      );
    }
    await _ensureSystemUser();

    try {
      await _database.into(_database.customerTransactions).insert(
            CustomerTransactionsCompanion.insert(
              id: generateLocalUuid(),
              customerId: customerId,
              requestId: Value(requestId),
              requestHash: Value(requestHash),
              openingBalanceCustomerId: Value(
                entryType == 'OPENING_BALANCE' ? customerId : null,
              ),
              entryType: entryType,
              amount: _normalizeDecimal(amount),
              occurredOn: occurredOn,
              notes: Value(notes),
              createdByUserId: _systemUserId,
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
    } on Object catch (error) {
      final existing = await (_database.select(_database.customerTransactions)
            ..where((transaction) => transaction.requestId.equals(requestId)))
          .getSingleOrNull();
      if (existing != null && existing.requestHash == requestHash) {
        return;
      }
      if (entryType == 'OPENING_BALANCE' &&
          await _hasOpeningBalance(customerId: customerId)) {
        throw const ApiError(
          code: 'OPENING_BALANCE_EXISTS',
          message: 'Opening balance already exists',
          statusCode: 409,
        );
      }
      throw error;
    }
  }

  Future<void> _ensureActiveCustomer(String customerId) async {
    final customer = await (_database.select(_database.customers)
          ..where((customer) => customer.id.equals(customerId)))
        .getSingleOrNull();
    if (customer == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Customer not found',
        statusCode: 404,
      );
    }
    if (!customer.isActive) {
      throw const ApiError(
        code: 'CUSTOMER_ARCHIVED',
        message: 'Archived customer cannot be updated',
        statusCode: 400,
      );
    }
  }

  Future<bool> _hasOpeningBalance({required String customerId}) async {
    final openingBalance =
        await (_database.select(_database.customerTransactions)
              ..where(
                (transaction) =>
                    transaction.customerId.equals(customerId) &
                    transaction.entryType.equals('OPENING_BALANCE'),
              ))
            .getSingleOrNull();
    return openingBalance != null;
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

  void _validatePositiveAmount(double amount) {
    if (!amount.isFinite || amount <= 0 || amount > 999999999999.99) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'amount must be greater than zero',
        statusCode: 422,
      );
    }
    validateMoneyAmount(amount.toString());
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

  void _validateDateOnly(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'occurred_on must be a valid date',
        statusCode: 422,
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'occurred_on must be a valid date',
        statusCode: 422,
      );
    }
  }

  ApiError _idempotencyConflictError() {
    return const ApiError(
      code: 'IDEMPOTENCY_CONFLICT',
      message: 'request_id already used with different payload',
      statusCode: 409,
    );
  }

  String _entryHash(Map<String, dynamic> payload) {
    final sorted = Map<String, dynamic>.fromEntries(
      payload.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
    return sha256.convert(utf8.encode(jsonEncode(sorted))).toString();
  }

  String _normalizeDecimal(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Decimal value must be finite');
    }
    return value.toStringAsFixed(2);
  }
}
