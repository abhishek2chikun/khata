import 'dart:math';

import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/customer.dart' as customer_model;
import '../models/customer_ledger.dart';
import '../services/customers_service.dart';
import 'local_database.dart';

class LocalCustomersService implements CustomersService {
  LocalCustomersService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

  @override
  Future<customer_model.Customer> createCustomer(
      CreateCustomerInput input) async {
    await _throwIfDuplicate(name: input.name, phone: input.phone);

    final now = DateTime.now().toUtc().toIso8601String();
    final id = generateLocalUuid();
    try {
      await _database.into(_database.customers).insert(
            CustomersCompanion.insert(
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
        throw _duplicateCustomerError();
      }
      throw error;
    }

    final customer = await (_database.select(_database.customers)
          ..where((customer) => customer.id.equals(id)))
        .getSingle();
    return _toCustomer(customer, pendingBalance: 0);
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) async {
    final customer = await _getCustomer(customerId);
    final transactionQuery = _database.select(_database.customerTransactions)
      ..where((transaction) => transaction.customerId.equals(customerId))
      ..orderBy([
        (transaction) => OrderingTerm.asc(transaction.occurredOn),
        (transaction) => OrderingTerm.asc(transaction.createdAt),
        (transaction) => OrderingTerm.asc(transaction.id),
      ]);
    final allTransactions = await transactionQuery.get();
    final transactions = onDate == null
        ? allTransactions
        : allTransactions
            .where((transaction) => transaction.occurredOn == onDate)
            .toList();
    final pendingBalance = _pendingBalance(allTransactions);
    return CustomerLedger(
      customer: _toCustomer(customer, pendingBalance: pendingBalance),
      transactions: transactions.map(_toLedgerTransaction).toList(),
      invoices: const <CustomerInvoiceHistoryEntry>[],
    );
  }

  @override
  Future<List<customer_model.Customer>> fetchCustomers(
      {String search = ''}) async {
    final query = _database.select(_database.customers)
      ..orderBy([
        (customer) => OrderingTerm.asc(customer.name),
      ]);
    var customers = await query.get();
    if (search.isNotEmpty) {
      final normalizedSearch = search.toLowerCase();
      customers = customers
          .where(
            (customer) =>
                customer.name.toLowerCase().contains(normalizedSearch) ||
                (customer.phone?.toLowerCase().contains(normalizedSearch) ??
                    false),
          )
          .toList();
    }

    final balances = await _pendingBalancesByCustomerId();
    return customers
        .map(
          (customer) => _toCustomer(
            customer,
            pendingBalance: balances[customer.id] ?? 0,
          ),
        )
        .toList();
  }

  Future<Customer> _getCustomer(String customerId) async {
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
    return customer;
  }

  Future<void> _throwIfDuplicate({required String name, String? phone}) async {
    if (await _hasDuplicate(name: name, phone: phone)) {
      throw _duplicateCustomerError();
    }
  }

  Future<bool> _hasDuplicate({required String name, String? phone}) async {
    if (phone == null) {
      return false;
    }
    final duplicates = await (_database.select(_database.customers)
          ..where(
            (customer) =>
                customer.name.equals(name) & customer.phone.equals(phone),
          ))
        .get();
    return duplicates.isNotEmpty;
  }

  Future<Map<String, double>> _pendingBalancesByCustomerId() async {
    final transactions =
        await _database.select(_database.customerTransactions).get();
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

  double _pendingBalance(List<CustomerTransaction> transactions) {
    return transactions.fold<double>(
      0,
      (balance, transaction) => balance + _signedAmount(transaction),
    );
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

  customer_model.Customer _toCustomer(Customer customer,
      {required double pendingBalance}) {
    return customer_model.Customer(
      id: customer.id,
      name: customer.name,
      address: customer.address,
      phone: customer.phone,
      gstin: customer.gstin,
      state: customer.state,
      stateCode: customer.stateCode,
      isActive: customer.isActive,
      pendingBalance: pendingBalance,
    );
  }

  CustomerLedgerTransaction _toLedgerTransaction(
      CustomerTransaction transaction) {
    return CustomerLedgerTransaction(
      id: transaction.id,
      entryType: transaction.entryType,
      amount: double.parse(transaction.amount),
      occurredOn: transaction.occurredOn,
      createdAt: transaction.createdAt,
      notes: transaction.notes,
    );
  }

  ApiError _duplicateCustomerError() {
    return const ApiError(
      code: 'DUPLICATE_CUSTOMER',
      message: 'Customer already exists',
      statusCode: 409,
    );
  }
}

String generateLocalUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
