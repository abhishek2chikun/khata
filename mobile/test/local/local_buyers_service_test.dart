import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_buyers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/services/buyers_service.dart';

void main() {
  late LocalDatabase database;
  late LocalBuyersService buyersService;

  setUp(() async {
    database = LocalDatabase.memory();
    buyersService = LocalBuyersService(database: database);
    await _seedLocalUser(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates buyers and stores backend-compatible fields', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    expect(buyer.id, isNotEmpty);
    expect(buyer.name, 'Global Suppliers');
    expect(buyer.address, '9 Wholesale Market');
    expect(buyer.phone, '8888888888');
    expect(buyer.gstin, '27ABCDE1234F1Z5');
    expect(buyer.state, 'Maharashtra');
    expect(buyer.stateCode, '27');
    expect(buyer.isActive, isTrue);
    expect(buyer.pendingPayable, 0);

    final storedBuyer = await database.select(database.buyers).getSingle();
    expect(storedBuyer.id, buyer.id);
    expect(storedBuyer.name, 'Global Suppliers');
    expect(storedBuyer.phone, '8888888888');
    expect(storedBuyer.isActive, isTrue);
  });

  test('lists buyers ordered by name and searches case-insensitively',
      () async {
    final zeta = await buyersService.createBuyer(
      _buyerInput(name: 'Zeta Suppliers', phone: '1111111111'),
    );
    final alpha = await buyersService.createBuyer(
      _buyerInput(name: 'Alpha Mills', phone: '2222222222'),
    );
    final beta = await buyersService.createBuyer(
      _buyerInput(name: 'Beta Fabrics', phone: '3333333333'),
    );

    final buyers = await buyersService.fetchBuyers();
    final nameMatches = await buyersService.fetchBuyers(search: 'zeta');
    final phoneMatches = await buyersService.fetchBuyers(search: '2222');

    expect(buyers.map((buyer) => buyer.id), <String>[
      alpha.id,
      beta.id,
      zeta.id,
    ]);
    expect(nameMatches.map((buyer) => buyer.id), <String>[zeta.id]);
    expect(phoneMatches.map((buyer) => buyer.id), <String>[alpha.id]);
  });

  test('records opening pending amount as opening payable', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(1),
        amount: 1250.5,
        occurredAt: '2026-01-02T10:30:00.000Z',
      ),
    );

    final buyers = await buyersService.fetchBuyers();
    final storedTransaction =
        await database.select(database.buyerTransactions).getSingle();

    expect(buyers.single.pendingPayable, 1250.5);
    expect(storedTransaction.entryType, 'OPENING_PAYABLE');
    expect(storedTransaction.amount, '1250.5');
    expect(storedTransaction.createdByUserId, 'local-system-user');
  });

  test('records purchase amount and increases payable balance', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addPurchaseAmount(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(2),
        amount: 600,
        occurredAt: '2026-01-03T10:30:00.000Z',
        notes: 'Invoice 44',
      ),
    );

    final ledger = await buyersService.fetchBuyerLedger(buyer.id);

    expect(ledger.buyer.pendingPayable, 600);
    expect(ledger.transactions.single.entryType, 'PURCHASE_AMOUNT');
    expect(ledger.transactions.single.notes, 'Invoice 44');
  });

  test('records payment made and decreases payable balance', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addPurchaseAmount(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(3),
        amount: 1000,
        occurredAt: '2026-01-01T10:30:00.000Z',
      ),
    );
    await buyersService.addPaymentMade(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(4),
        amount: 250.25,
        occurredAt: '2026-01-02T10:30:00.000Z',
        notes: 'Bank transfer',
      ),
    );

    final ledger = await buyersService.fetchBuyerLedger(buyer.id);

    expect(ledger.buyer.pendingPayable, 749.75);
    expect(ledger.transactions.map((transaction) => transaction.entryType),
        <String>['PURCHASE_AMOUNT', 'PAYMENT_MADE']);
    expect(ledger.transactions.last.notes, 'Bank transfer');
  });

  test('records payable balance adjustments with signed balance effect',
      () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(5),
        amount: 1000,
        occurredAt: '2026-01-01T10:30:00.000Z',
      ),
    );
    await buyersService.addPayableAdjustment(
      buyerId: buyer.id,
      input: BuyerPayableAdjustmentInput(
        requestId: _uuid(6),
        direction: 'INCREASE',
        amount: 50,
        occurredAt: '2026-01-02T10:30:00.000Z',
      ),
    );
    await buyersService.addPayableAdjustment(
      buyerId: buyer.id,
      input: BuyerPayableAdjustmentInput(
        requestId: _uuid(7),
        direction: 'DECREASE',
        amount: 100,
        occurredAt: '2026-01-03T10:30:00.000Z',
        notes: 'Rate correction',
      ),
    );

    final ledger = await buyersService.fetchBuyerLedger(buyer.id);

    expect(ledger.buyer.pendingPayable, 950);
    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>[
        'OPENING_PAYABLE',
        'PAYABLE_INCREASE_ADJUSTMENT',
        'PAYABLE_DECREASE_ADJUSTMENT',
      ],
    );
    expect(ledger.transactions.last.notes, 'Rate correction');
  });

  test('computes payable balance from all ledger row types', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(8),
        amount: 1000,
        occurredAt: '2026-01-01T10:30:00.000Z',
      ),
    );
    await buyersService.addPurchaseAmount(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(9),
        amount: 250.25,
        occurredAt: '2026-01-02T10:30:00.000Z',
      ),
    );
    await buyersService.addPaymentMade(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(10),
        amount: 300,
        occurredAt: '2026-01-03T10:30:00.000Z',
      ),
    );
    await buyersService.addPayableAdjustment(
      buyerId: buyer.id,
      input: BuyerPayableAdjustmentInput(
        requestId: _uuid(11),
        direction: 'INCREASE',
        amount: 20,
        occurredAt: '2026-01-04T10:30:00.000Z',
      ),
    );
    await buyersService.addPayableAdjustment(
      buyerId: buyer.id,
      input: BuyerPayableAdjustmentInput(
        requestId: _uuid(12),
        direction: 'DECREASE',
        amount: 70,
        occurredAt: '2026-01-05T10:30:00.000Z',
      ),
    );

    final buyerList = await buyersService.fetchBuyers();
    final ledger = await buyersService.fetchBuyerLedger(buyer.id);

    expect(buyerList.single.pendingPayable, 900.25);
    expect(ledger.buyer.pendingPayable, 900.25);
  });

  test('orders ledger by occurred timestamp then creation time', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addPayableAdjustment(
      buyerId: buyer.id,
      input: BuyerPayableAdjustmentInput(
        requestId: _uuid(13),
        direction: 'INCREASE',
        amount: 20,
        occurredAt: '2026-01-02T10:00:00.000Z',
      ),
    );
    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(14),
        amount: 100,
        occurredAt: '2026-01-01T10:00:00.000Z',
      ),
    );
    await buyersService.addPaymentMade(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(15),
        amount: 10,
        occurredAt: '2026-01-02T10:00:00.000Z',
      ),
    );

    final ledger = await buyersService.fetchBuyerLedger(buyer.id);

    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>[
        'OPENING_PAYABLE',
        'PAYABLE_INCREASE_ADJUSTMENT',
        'PAYMENT_MADE',
      ],
    );
  });

  test('rejects duplicate opening payable and idempotency conflicts', () async {
    final buyer = await buyersService.createBuyer(_buyerInput());

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(16),
        amount: 100,
        occurredAt: '2026-01-01T10:00:00.000Z',
      ),
    );

    await buyersService.addOpeningPayable(
      buyerId: buyer.id,
      input: BuyerLedgerEntryInput(
        requestId: _uuid(16),
        amount: 100,
        occurredAt: '2026-01-01T10:00:00.000Z',
      ),
    );
    await expectLater(
      () => buyersService.addOpeningPayable(
        buyerId: buyer.id,
        input: BuyerLedgerEntryInput(
          requestId: _uuid(17),
          amount: 200,
          occurredAt: '2026-01-02T10:00:00.000Z',
        ),
      ),
      throwsA(_apiError(code: 'OPENING_PAYABLE_EXISTS', statusCode: 409)),
    );
    await expectLater(
      () => buyersService.addOpeningPayable(
        buyerId: buyer.id,
        input: BuyerLedgerEntryInput(
          requestId: _uuid(16),
          amount: 150,
          occurredAt: '2026-01-01T10:00:00.000Z',
        ),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
    expect(
        await database.select(database.buyerTransactions).get(), hasLength(1));
  });
}

CreateBuyerInput _buyerInput({
  String name = 'Global Suppliers',
  String address = '9 Wholesale Market',
  String? phone = '8888888888',
  String gstin = '27ABCDE1234F1Z5',
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return CreateBuyerInput(
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

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
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
