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
  static const _batchNotesPrefix = '__batch__|';
  static const _maxCollectionWindowDays = 7;

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

  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) async {
    _validateDateOnly(fromDate);
    _validateDateOnly(toDate);
    final today = _todayString();
    final dates = _validateCollectionWindow(fromDate: fromDate, toDate: toDate, today: today);
    final customers = await (_database.select(_database.customers)
          ..where((customer) => customer.isActive.equals(true))
          ..orderBy([(customer) => OrderingTerm.asc(customer.name)]))
        .get();
    final balances = await _pendingBalancesByCustomerId();
    final rows = <CollectionGridCustomerRow>[];
    for (final customer in customers) {
      final pendingBalance = balances[customer.id] ?? 0;
      if (pendingBalance <= 0) {
        continue;
      }
      final collections = await (_database.select(_database.customerTransactions)
            ..where(
              (transaction) =>
                  transaction.customerId.equals(customer.id) &
                  transaction.entryType.equals('COLLECTION') &
                  transaction.occurredOn.isBiggerOrEqualValue(fromDate) &
                  transaction.occurredOn.isSmallerOrEqualValue(toDate),
            ))
          .get();
      final existingTotals = <String, double>{};
      for (final collection in collections) {
        existingTotals.update(
          collection.occurredOn,
          (total) => total + double.parse(collection.amount),
          ifAbsent: () => double.parse(collection.amount),
        );
      }
      rows.add(
        CollectionGridCustomerRow(
          id: customer.id,
          name: customer.name,
          pendingBalance: pendingBalance,
          existingTotals: existingTotals,
        ),
      );
    }
    return CollectionGridData(
      fromDate: fromDate,
      toDate: toDate,
      dates: dates,
      customers: rows,
    );
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(BatchCollectionInput input) async {
    _validateRequestId(input.requestId);
    if (input.entries.isEmpty) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'At least one collection entry is required',
        statusCode: 400,
      );
    }
    for (final entry in input.entries) {
      _validateDateOnly(entry.occurredOn);
      _validatePositiveAmount(entry.amount);
    }

    final today = _todayString();
    final batchHash = _canonicalBatchHash(input.entries);
    final batchNotes = _batchNotes(input.requestId, batchHash);

    return _database.transaction(() async {
      final conflicting = await (_database.select(_database.customerTransactions)
            ..where(
              (transaction) =>
                  transaction.entryType.equals('COLLECTION') &
                  transaction.notes.like('$_batchNotesPrefix${input.requestId}|%') &
                  transaction.notes.equals(batchNotes).not(),
            )
            ..limit(1))
          .getSingleOrNull();
      if (conflicting != null) {
        throw _idempotencyConflictError();
      }

      final existing = await (_database.select(_database.customerTransactions)
            ..where(
              (transaction) =>
                  transaction.entryType.equals('COLLECTION') &
                  transaction.notes.equals(batchNotes),
            ))
          .get();
      if (existing.isNotEmpty) {
        return _buildBatchResult(input.requestId, existing);
      }

      _validateBatchEntries(input.entries, today: today);
      final customerIds = input.entries.map((entry) => entry.customerId).toSet().toList()
        ..sort();
      final customers = await (_database.select(_database.customers)
            ..where((customer) => customer.id.isIn(customerIds))
            ..orderBy([(customer) => OrderingTerm.asc(customer.id)]))
          .get();
      if (customers.length != customerIds.length) {
        throw const ApiError(
          code: 'NOT_FOUND',
          message: 'Customer not found',
          statusCode: 404,
        );
      }
      final customersById = {for (final customer in customers) customer.id: customer};
      final totalsByCustomer = <String, double>{};
      for (final entry in input.entries) {
        final customer = customersById[entry.customerId];
        if (customer == null || !customer.isActive) {
          throw const ApiError(
            code: 'CUSTOMER_ARCHIVED',
            message: 'Archived customer cannot be updated',
            statusCode: 400,
          );
        }
        totalsByCustomer.update(entry.customerId, (total) => total + entry.amount, ifAbsent: () => entry.amount);
      }

      final balances = await _pendingBalancesByCustomerId();
      for (final entry in totalsByCustomer.entries) {
        final pendingBalance = balances[entry.key] ?? 0;
        if (entry.value > pendingBalance) {
          throw const ApiError(
            code: 'STALE_BALANCE',
            message: 'Collection total exceeds current pending balance',
            statusCode: 409,
          );
        }
      }

      await _ensureSystemUser();
      final sortedEntries = List<BatchCollectionEntryInput>.from(input.entries)
        ..sort((left, right) {
          final customerCompare = left.customerId.compareTo(right.customerId);
          if (customerCompare != 0) {
            return customerCompare;
          }
          return left.occurredOn.compareTo(right.occurredOn);
        });
      final inserted = <CustomerTransaction>[];
      for (final entry in sortedEntries) {
        final requestId = _batchEntryRequestId(input.requestId, entry.customerId, entry.occurredOn);
        final requestHash = _collectionEntryHash(
          customerId: entry.customerId,
          occurredOn: entry.occurredOn,
          amount: entry.amount,
          batchRequestId: input.requestId,
        );
        await _database.into(_database.customerTransactions).insert(
              CustomerTransactionsCompanion.insert(
                id: generateLocalUuid(),
                customerId: entry.customerId,
                requestId: Value(requestId),
                requestHash: Value(requestHash),
                entryType: 'COLLECTION',
                amount: _normalizeDecimal(entry.amount),
                occurredOn: entry.occurredOn,
                notes: Value(batchNotes),
                createdByUserId: _systemUserId,
                createdAt: DateTime.now().toUtc().toIso8601String(),
              ),
            );
        inserted.add(
          CustomerTransaction(
            id: requestId,
            customerId: entry.customerId,
            requestId: requestId,
            requestHash: requestHash,
            entryType: 'COLLECTION',
            amount: _normalizeDecimal(entry.amount),
            occurredOn: entry.occurredOn,
            notes: batchNotes,
            createdByUserId: _systemUserId,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      }
      return _buildBatchResult(input.requestId, inserted);
    });
  }

  BatchCollectionResult _buildBatchResult(String requestId, List<CustomerTransaction> transactions) {
    final totalAmount = transactions.fold<double>(
      0,
      (total, transaction) => total + double.parse(transaction.amount),
    );
    final affectedCustomers = transactions.map((transaction) => transaction.customerId).toSet().length;
    return BatchCollectionResult(
      requestId: requestId,
      entryCount: transactions.length,
      totalAmount: totalAmount,
      affectedCustomers: affectedCustomers,
    );
  }

  void _validateBatchEntries(List<BatchCollectionEntryInput> entries, {required String today}) {
    final seen = <String>{};
    for (final entry in entries) {
      if (entry.occurredOn.compareTo(today) > 0) {
        throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'Collection dates cannot be in the future',
          statusCode: 400,
        );
      }
      if (_daysBetween(entry.occurredOn, today) > 6) {
        throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'Collection dates cannot be older than six days',
          statusCode: 400,
        );
      }
      final key = '${entry.customerId}|${entry.occurredOn}';
      if (seen.contains(key)) {
        throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'Duplicate customer and date entries are not allowed',
          statusCode: 400,
        );
      }
      seen.add(key);
    }
  }

  List<String> _validateCollectionWindow({
    required String fromDate,
    required String toDate,
    required String today,
  }) {
    if (fromDate.compareTo(toDate) > 0) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'from_date must be on or before to_date',
        statusCode: 400,
      );
    }
    if (toDate.compareTo(today) > 0) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'Collection dates cannot be in the future',
        statusCode: 400,
      );
    }
    if (_daysBetween(fromDate, today) > 6) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'Collection dates cannot be older than six days',
        statusCode: 400,
      );
    }
    final dayCount = _daysBetween(fromDate, toDate) + 1;
    if (dayCount > _maxCollectionWindowDays) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'Collection date range cannot exceed seven days',
        statusCode: 400,
      );
    }
    final dates = <String>[];
    var cursor = _parseDate(fromDate);
    final end = _parseDate(toDate);
    while (!cursor.isAfter(end)) {
      dates.add(_dateString(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<Map<String, double>> _pendingBalancesByCustomerId() async {
    final transactions = await _database.select(_database.customerTransactions).get();
    final balances = <String, double>{};
    for (final transaction in transactions) {
      balances.update(
        transaction.customerId,
        (balance) => balance + _signedAmount(transaction),
        ifAbsent: () => _signedAmount(transaction),
      );
    }
    return balances;
  }

  double _signedAmount(CustomerTransaction transaction) {
    final amount = double.parse(transaction.amount);
    return switch (transaction.entryType) {
      'OPENING_BALANCE' ||
      'CREDIT_SALE' ||
      'COLLECTION_REVERSAL' ||
      'BALANCE_INCREASE_ADJUSTMENT' =>
        amount,
      _ => -amount,
    };
  }

  String _batchNotes(String batchRequestId, String batchHash) {
    return '$_batchNotesPrefix$batchRequestId|$batchHash';
  }

  String _canonicalBatchHash(List<BatchCollectionEntryInput> entries) {
    final sorted = List<BatchCollectionEntryInput>.from(entries)
      ..sort((left, right) {
        final customerCompare = left.customerId.compareTo(right.customerId);
        if (customerCompare != 0) {
          return customerCompare;
        }
        return left.occurredOn.compareTo(right.occurredOn);
      });
    final canonical = sorted
        .map(
          (entry) => <String, String>{
            'customer_id': entry.customerId,
            'occurred_on': entry.occurredOn,
            'amount': _normalizeDecimal(entry.amount),
          },
        )
        .toList();
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  String _batchEntryRequestId(String batchRequestId, String customerId, String occurredOn) {
    final namespace = _uuidFromString(batchRequestId);
    return _uuidV5(namespace, '$customerId:$occurredOn');
  }

  String _collectionEntryHash({
    required String customerId,
    required String occurredOn,
    required double amount,
    required String batchRequestId,
  }) {
    return _entryHash(<String, dynamic>{
      'customer_id': customerId,
      'entry_type': 'COLLECTION',
      'occurred_on': occurredOn,
      'amount': _normalizeDecimal(amount),
      'batch_request_id': batchRequestId,
    });
  }

  String _todayString() {
    return _dateString(DateTime.now());
  }

  String _dateString(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String value) {
    final parts = value.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  int _daysBetween(String earlier, String later) {
    return _parseDate(later).difference(_parseDate(earlier)).inDays;
  }

  List<int> _uuidFromString(String value) {
    final normalized = value.replaceAll('-', '');
    final bytes = <int>[];
    for (var index = 0; index < normalized.length; index += 2) {
      bytes.add(int.parse(normalized.substring(index, index + 2), radix: 16));
    }
    return bytes;
  }

  String _uuidV5(List<int> namespace, String name) {
    final input = <int>[...namespace, ...utf8.encode(name)];
    final digest = sha1.convert(input).bytes;
    digest[6] = (digest[6] & 0x0f) | 0x50;
    digest[8] = (digest[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final hexString = digest.map(hex).join();
    return '${hexString.substring(0, 8)}-${hexString.substring(8, 12)}-'
        '${hexString.substring(12, 16)}-${hexString.substring(16, 20)}-'
        '${hexString.substring(20, 32)}';
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
