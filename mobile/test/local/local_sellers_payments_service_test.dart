import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_sellers_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  late LocalDatabase database;
  late LocalSellersService sellersService;
  late LocalPaymentsService paymentsService;

  setUp(() async {
    database = LocalDatabase.memory();
    sellersService = LocalSellersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    await _seedLocalUser(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates sellers and stores backend-compatible fields', () async {
    final seller = await sellersService.createSeller(_sellerInput());

    expect(seller.id, isNotEmpty);
    expect(seller.name, 'Acme Stores');
    expect(seller.address, '1 Market Road');
    expect(seller.phone, '9999999999');
    expect(seller.gstin, '27ABCDE1234F1Z5');
    expect(seller.state, 'Maharashtra');
    expect(seller.stateCode, '27');
    expect(seller.isActive, isTrue);
    expect(seller.pendingBalance, 0);

    final storedSeller = await database.select(database.sellers).getSingle();
    expect(storedSeller.id, seller.id);
    expect(storedSeller.name, 'Acme Stores');
    expect(storedSeller.phone, '9999999999');
    expect(storedSeller.isActive, isTrue);
  });

  test('lists active sellers ordered by name and searches case-insensitively',
      () async {
    final zeta = await sellersService.createSeller(
      _sellerInput(name: 'Zeta Traders', phone: '1111111111'),
    );
    final alpha = await sellersService.createSeller(
      _sellerInput(name: 'Alpha Stores', phone: '2222222222'),
    );
    final inactive = await sellersService.createSeller(
      _sellerInput(name: 'Beta Stores', phone: '3333333333'),
    );
    await database.customStatement(
      "UPDATE sellers SET is_active = 0 WHERE id = '${inactive.id}'",
    );

    final sellers = await sellersService.fetchSellers();
    final nameMatches = await sellersService.fetchSellers(search: 'zeta');
    final phoneMatches = await sellersService.fetchSellers(search: '2222');

    expect(sellers.map((seller) => seller.id), <String>[alpha.id, zeta.id]);
    expect(nameMatches.map((seller) => seller.id), <String>[zeta.id]);
    expect(phoneMatches.map((seller) => seller.id), <String>[alpha.id]);
  });

  test('rejects duplicate sellers by name and phone', () async {
    await sellersService.createSeller(_sellerInput());

    await expectLater(
      () => sellersService.createSeller(
        _sellerInput(address: 'Different address'),
      ),
      throwsA(_apiError(code: 'DUPLICATE_SELLER', statusCode: 409)),
    );
    expect(await database.select(database.sellers).get(), hasLength(1));
  });

  test('records opening balance and computes pending balance from ledger rows',
      () async {
    final seller = await sellersService.createSeller(_sellerInput());

    await paymentsService.addOpeningBalance(
      sellerId: seller.id,
      input: const OpeningBalanceInput(
        requestId: 'open-1',
        amount: 1250.5,
        occurredOn: '2026-01-02',
      ),
    );

    final sellers = await sellersService.fetchSellers();
    final storedTransaction =
        await database.select(database.sellerTransactions).getSingle();

    expect(sellers.single.pendingBalance, 1250.5);
    expect(storedTransaction.entryType, 'OPENING_BALANCE');
    expect(storedTransaction.amount, '1250.5');
    expect(storedTransaction.createdByUserId, 'local-system-user');
  });

  test('creates deterministic system user for local transactions when missing',
      () async {
    await database.close();
    database = LocalDatabase.memory();
    sellersService = LocalSellersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    final seller = await sellersService.createSeller(_sellerInput());

    await paymentsService.recordPayment(
      RecordPaymentInput(
        requestId: 'payment-1',
        sellerId: seller.id,
        amount: 10,
        occurredOn: '2026-01-03',
      ),
    );

    final user = await database.select(database.localUsers).getSingle();
    final transaction =
        await database.select(database.sellerTransactions).getSingle();
    expect(user.id, 'local-system-user');
    expect(user.username, 'local-system');
    expect(transaction.createdByUserId, 'local-system-user');
  });

  test('records payments and balance adjustments with signed balance effect',
      () async {
    final seller = await sellersService.createSeller(_sellerInput());

    await paymentsService.addOpeningBalance(
      sellerId: seller.id,
      input: const OpeningBalanceInput(
        requestId: 'open-1',
        amount: 1000,
        occurredOn: '2026-01-01',
      ),
    );
    await paymentsService.recordPayment(
      RecordPaymentInput(
        requestId: 'payment-1',
        sellerId: seller.id,
        amount: 250.25,
        occurredOn: '2026-01-03',
        notes: 'Cash received',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      sellerId: seller.id,
      input: const BalanceAdjustmentInput(
        requestId: 'increase-1',
        direction: 'INCREASE',
        amount: 50,
        occurredOn: '2026-01-04',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      sellerId: seller.id,
      input: const BalanceAdjustmentInput(
        requestId: 'decrease-1',
        direction: 'DECREASE',
        amount: 100,
        occurredOn: '2026-01-05',
      ),
    );
    final ledger = await sellersService.fetchSellerLedger(seller.id);

    expect(ledger.seller.pendingBalance, 699.75);
    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>[
        'OPENING_BALANCE',
        'PAYMENT',
        'BALANCE_INCREASE_ADJUSTMENT',
        'BALANCE_DECREASE_ADJUSTMENT',
      ],
    );
    expect(ledger.transactions[1].amount, 250.25);
    expect(ledger.transactions[1].notes, 'Cash received');
    expect(ledger.invoices, isEmpty);
  });

  test('orders ledger by occurred date then creation time', () async {
    final seller = await sellersService.createSeller(_sellerInput());

    await paymentsService.addBalanceAdjustment(
      sellerId: seller.id,
      input: const BalanceAdjustmentInput(
        requestId: 'second-created',
        direction: 'INCREASE',
        amount: 20,
        occurredOn: '2026-01-02',
      ),
    );
    await paymentsService.addOpeningBalance(
      sellerId: seller.id,
      input: const OpeningBalanceInput(
        requestId: 'first-by-date',
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      sellerId: seller.id,
      input: const BalanceAdjustmentInput(
        requestId: 'third-created',
        direction: 'DECREASE',
        amount: 10,
        occurredOn: '2026-01-02',
      ),
    );

    final ledger = await sellersService.fetchSellerLedger(seller.id);

    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>[
        'OPENING_BALANCE',
        'BALANCE_INCREASE_ADJUSTMENT',
        'BALANCE_DECREASE_ADJUSTMENT',
      ],
    );
  });

  test('rejects duplicate opening balances and idempotency conflicts',
      () async {
    final seller = await sellersService.createSeller(_sellerInput());

    await paymentsService.addOpeningBalance(
      sellerId: seller.id,
      input: const OpeningBalanceInput(
        requestId: 'open-1',
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );

    await paymentsService.addOpeningBalance(
      sellerId: seller.id,
      input: const OpeningBalanceInput(
        requestId: 'open-1',
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );
    await expectLater(
      () => paymentsService.addOpeningBalance(
        sellerId: seller.id,
        input: const OpeningBalanceInput(
          requestId: 'open-2',
          amount: 200,
          occurredOn: '2026-01-02',
        ),
      ),
      throwsA(_apiError(code: 'OPENING_BALANCE_EXISTS', statusCode: 409)),
    );
    await expectLater(
      () => paymentsService.addOpeningBalance(
        sellerId: seller.id,
        input: const OpeningBalanceInput(
          requestId: 'open-1',
          amount: 150,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
    expect(
        await database.select(database.sellerTransactions).get(), hasLength(1));
  });
}

CreateSellerInput _sellerInput({
  String name = 'Acme Stores',
  String address = '1 Market Road',
  String phone = '9999999999',
  String gstin = '27ABCDE1234F1Z5',
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return CreateSellerInput(
    name: name,
    address: address,
    phone: phone,
    gstin: gstin,
    state: state,
    stateCode: stateCode,
  );
}

Matcher _apiError({required String code, required int statusCode}) {
  return isA<ApiError>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.statusCode, 'statusCode', statusCode);
}

Future<void> _seedLocalUser(LocalDatabase database) {
  return database.into(database.localUsers).insert(
        LocalUsersCompanion.insert(
          id: 'local-system-user',
          username: 'system',
          passwordHash: 'hash',
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
          displayName: const Value('System'),
        ),
      );
}
