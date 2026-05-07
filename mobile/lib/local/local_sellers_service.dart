import 'dart:math';

import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/seller.dart' as seller_model;
import '../models/seller_ledger.dart';
import '../services/sellers_service.dart';
import 'local_database.dart';

class LocalSellersService implements SellersService {
  LocalSellersService({required LocalDatabase database}) : _database = database;

  final LocalDatabase _database;

  @override
  Future<seller_model.Seller> createSeller(CreateSellerInput input) async {
    await _throwIfDuplicate(name: input.name, phone: input.phone);

    final now = DateTime.now().toUtc().toIso8601String();
    final id = generateLocalUuid();
    try {
      await _database.into(_database.sellers).insert(
            SellersCompanion.insert(
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
        throw _duplicateSellerError();
      }
      throw error;
    }

    final seller = await (_database.select(_database.sellers)
          ..where((seller) => seller.id.equals(id)))
        .getSingle();
    return _toSeller(seller, pendingBalance: 0);
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) async {
    final seller = await _getSeller(sellerId);
    final transactions = await (_database.select(_database.sellerTransactions)
          ..where((transaction) => transaction.sellerId.equals(sellerId))
          ..orderBy([
            (transaction) => OrderingTerm.asc(transaction.occurredOn),
            (transaction) => OrderingTerm.asc(transaction.createdAt),
          ]))
        .get();
    final pendingBalance = _pendingBalance(transactions);
    return SellerLedger(
      seller: _toSeller(seller, pendingBalance: pendingBalance),
      transactions: transactions.map(_toLedgerTransaction).toList(),
      invoices: const <SellerInvoiceHistoryEntry>[],
    );
  }

  @override
  Future<List<seller_model.Seller>> fetchSellers({String search = ''}) async {
    final query = _database.select(_database.sellers)
      ..where((seller) => seller.isActive.equals(true))
      ..orderBy([
        (seller) => OrderingTerm.asc(seller.name),
      ]);
    var sellers = await query.get();
    if (search.isNotEmpty) {
      final normalizedSearch = search.toLowerCase();
      sellers = sellers
          .where(
            (seller) =>
                seller.name.toLowerCase().contains(normalizedSearch) ||
                (seller.phone?.toLowerCase().contains(normalizedSearch) ??
                    false),
          )
          .toList();
    }

    final balances = await _pendingBalancesBySellerId();
    return sellers
        .map(
          (seller) => _toSeller(
            seller,
            pendingBalance: balances[seller.id] ?? 0,
          ),
        )
        .toList();
  }

  Future<Seller> _getSeller(String sellerId) async {
    final seller = await (_database.select(_database.sellers)
          ..where((seller) => seller.id.equals(sellerId)))
        .getSingleOrNull();
    if (seller == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Seller not found',
        statusCode: 404,
      );
    }
    return seller;
  }

  Future<void> _throwIfDuplicate({required String name, String? phone}) async {
    if (await _hasDuplicate(name: name, phone: phone)) {
      throw _duplicateSellerError();
    }
  }

  Future<bool> _hasDuplicate({required String name, String? phone}) async {
    final duplicates = await (_database.select(_database.sellers)
          ..where(
            (seller) =>
                seller.name.equals(name) &
                (phone == null
                    ? seller.phone.isNull()
                    : seller.phone.equals(phone)),
          ))
        .get();
    return duplicates.isNotEmpty;
  }

  Future<Map<String, double>> _pendingBalancesBySellerId() async {
    final transactions =
        await _database.select(_database.sellerTransactions).get();
    final balances = <String, double>{};
    for (final transaction in transactions) {
      balances.update(
        transaction.sellerId,
        (balance) => balance + _signedAmount(transaction),
        ifAbsent: () => _signedAmount(transaction),
      );
    }
    return balances;
  }

  double _pendingBalance(List<SellerTransaction> transactions) {
    return transactions.fold<double>(
      0,
      (balance, transaction) => balance + _signedAmount(transaction),
    );
  }

  double _signedAmount(SellerTransaction transaction) {
    final amount = double.parse(transaction.amount);
    return switch (transaction.entryType) {
      'OPENING_BALANCE' ||
      'CREDIT_SALE' ||
      'BALANCE_INCREASE_ADJUSTMENT' =>
        amount,
      _ => -amount,
    };
  }

  seller_model.Seller _toSeller(Seller seller,
      {required double pendingBalance}) {
    return seller_model.Seller(
      id: seller.id,
      name: seller.name,
      address: seller.address,
      phone: seller.phone,
      gstin: seller.gstin,
      state: seller.state,
      stateCode: seller.stateCode,
      isActive: seller.isActive,
      pendingBalance: pendingBalance,
    );
  }

  SellerLedgerTransaction _toLedgerTransaction(SellerTransaction transaction) {
    return SellerLedgerTransaction(
      id: transaction.id,
      entryType: transaction.entryType,
      amount: double.parse(transaction.amount),
      occurredOn: transaction.occurredOn,
      notes: transaction.notes,
    );
  }

  ApiError _duplicateSellerError() {
    return const ApiError(
      code: 'DUPLICATE_SELLER',
      message: 'Seller already exists',
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
