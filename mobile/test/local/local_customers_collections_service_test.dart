import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  late LocalDatabase database;
  late LocalCustomersService customersService;
  late LocalPaymentsService paymentsService;

  setUp(() async {
    database = LocalDatabase.memory();
    customersService = LocalCustomersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    await _seedLocalUser(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates customers and stores backend-compatible fields', () async {
    final customer = await customersService.createCustomer(_customerInput());

    expect(customer.id, isNotEmpty);
    expect(customer.name, 'Acme Stores');
    expect(customer.address, '1 Market Road');
    expect(customer.phone, '9999999999');
    expect(customer.gstin, '27ABCDE1234F1Z5');
    expect(customer.state, 'Maharashtra');
    expect(customer.stateCode, '27');
    expect(customer.isActive, isTrue);
    expect(customer.pendingBalance, 0);

    final storedCustomer =
        await database.select(database.customers).getSingle();
    expect(storedCustomer.id, customer.id);
    expect(storedCustomer.name, 'Acme Stores');
    expect(storedCustomer.phone, '9999999999');
    expect(storedCustomer.isActive, isTrue);
  });

  test('lists customers ordered by name and searches case-insensitively',
      () async {
    final zeta = await customersService.createCustomer(
      _customerInput(name: 'Zeta Traders', phone: '1111111111'),
    );
    final alpha = await customersService.createCustomer(
      _customerInput(name: 'Alpha Stores', phone: '2222222222'),
    );
    final inactive = await customersService.createCustomer(
      _customerInput(name: 'Beta Stores', phone: '3333333333'),
    );
    await database.customStatement(
      "UPDATE customers SET is_active = 0 WHERE id = '${inactive.id}'",
    );

    final customers = await customersService.fetchCustomers();
    final nameMatches = await customersService.fetchCustomers(search: 'zeta');
    final phoneMatches = await customersService.fetchCustomers(search: '2222');

    expect(customers.map((customer) => customer.id), <String>[
      alpha.id,
      inactive.id,
      zeta.id,
    ]);
    expect(nameMatches.map((customer) => customer.id), <String>[zeta.id]);
    expect(phoneMatches.map((customer) => customer.id), <String>[alpha.id]);
  });

  test(
      'unfiltered customer list includes inactive customers seeded through Drift',
      () async {
    final active = await customersService.createCustomer(
      _customerInput(name: 'Active Stores', phone: '1111111111'),
    );
    await _seedCustomer(
      database,
      id: 'inactive-customer',
      name: 'Inactive Stores',
      phone: '2222222222',
      isActive: false,
    );

    final customers = await customersService.fetchCustomers();

    expect(customers.map((customer) => customer.id), <String>[
      active.id,
      'inactive-customer',
    ]);
    expect(customers.map((customer) => customer.isActive), <bool>[true, false]);
  });

  test('allows duplicate customer names when phone is omitted', () async {
    final first = await customersService.createCustomer(
      _customerInput(phone: null, address: 'First address'),
    );
    final second = await customersService.createCustomer(
      _customerInput(phone: null, address: 'Second address'),
    );

    expect(first.name, 'Acme Stores');
    expect(first.phone, isNull);
    expect(second.name, 'Acme Stores');
    expect(second.phone, isNull);
    expect(await database.select(database.customers).get(), hasLength(2));
  });

  test('rejects duplicate customers by same name and same non-null phone',
      () async {
    await customersService.createCustomer(_customerInput());

    await expectLater(
      () => customersService.createCustomer(
        _customerInput(address: 'Different address'),
      ),
      throwsA(_apiError(code: 'DUPLICATE_CUSTOMER', statusCode: 409)),
    );
    expect(await database.select(database.customers).get(), hasLength(1));
  });

  test('records opening balance and computes pending balance from ledger rows',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(1),
        amount: 1250.5,
        occurredOn: '2026-01-02',
      ),
    );

    final customers = await customersService.fetchCustomers();
    final storedTransaction =
        await database.select(database.customerTransactions).getSingle();

    expect(customers.single.pendingBalance, 1250.5);
    expect(storedTransaction.entryType, 'OPENING_BALANCE');
    expect(storedTransaction.amount, '1250.50');
    expect(storedTransaction.createdByUserId, 'local-system-user');
  });

  test('creates deterministic system user for local transactions when missing',
      () async {
    await database.close();
    database = LocalDatabase.memory();
    customersService = LocalCustomersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.recordCollection(
      RecordCollectionInput(
        requestId: _uuid(2),
        customerId: customer.id,
        amount: 10,
        occurredOn: '2026-01-03',
      ),
    );

    final user = await database.select(database.localUsers).getSingle();
    final transaction =
        await database.select(database.customerTransactions).getSingle();
    expect(user.id, 'local-system-user');
    expect(user.username, 'local-system');
    expect(transaction.createdByUserId, 'local-system-user');
  });

  test('records payments and balance adjustments with signed balance effect',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(3),
        amount: 1000,
        occurredOn: '2026-01-01',
      ),
    );
    await paymentsService.recordCollection(
      RecordCollectionInput(
        requestId: _uuid(4),
        customerId: customer.id,
        amount: 250.25,
        occurredOn: '2026-01-03',
        notes: 'Cash received',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      customerId: customer.id,
      input: BalanceAdjustmentInput(
        requestId: _uuid(5),
        direction: 'INCREASE',
        amount: 50,
        occurredOn: '2026-01-04',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      customerId: customer.id,
      input: BalanceAdjustmentInput(
        requestId: _uuid(6),
        direction: 'DECREASE',
        amount: 100,
        occurredOn: '2026-01-05',
      ),
    );
    final ledger = await customersService.fetchCustomerLedger(customer.id);

    expect(ledger.customer.pendingBalance, 699.75);
    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>[
        'OPENING_BALANCE',
        'COLLECTION',
        'BALANCE_INCREASE_ADJUSTMENT',
        'BALANCE_DECREASE_ADJUSTMENT',
      ],
    );
    expect(ledger.transactions[1].amount, 250.25);
    expect(ledger.transactions[1].notes, 'Cash received');
    expect(ledger.invoices, isEmpty);
  });

  test('orders ledger by occurred date then creation time', () async {
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.addBalanceAdjustment(
      customerId: customer.id,
      input: BalanceAdjustmentInput(
        requestId: _uuid(7),
        direction: 'INCREASE',
        amount: 20,
        occurredOn: '2026-01-02',
      ),
    );
    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(8),
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );
    await paymentsService.addBalanceAdjustment(
      customerId: customer.id,
      input: BalanceAdjustmentInput(
        requestId: _uuid(9),
        direction: 'DECREASE',
        amount: 10,
        occurredOn: '2026-01-02',
      ),
    );

    final ledger = await customersService.fetchCustomerLedger(customer.id);

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
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(10),
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );

    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(10),
        amount: 100,
        occurredOn: '2026-01-01',
      ),
    );
    await expectLater(
      () => paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: OpeningBalanceInput(
          requestId: _uuid(11),
          amount: 200,
          occurredOn: '2026-01-02',
        ),
      ),
      throwsA(_apiError(code: 'OPENING_BALANCE_EXISTS', statusCode: 409)),
    );
    await expectLater(
      () => paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: OpeningBalanceInput(
          requestId: _uuid(10),
          amount: 150,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
    expect(await database.select(database.customerTransactions).get(),
        hasLength(1));
  });

  test('database rejects a second opening balance for the same customer',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await _seedCustomerTransaction(
      database,
      id: 'opening-1',
      customerId: customer.id,
      requestId: _uuid(12),
      entryType: 'OPENING_BALANCE',
      occurredOn: '2026-01-01',
    );

    await expectLater(
      () => _seedCustomerTransaction(
        database,
        id: 'opening-2',
        customerId: customer.id,
        requestId: _uuid(13),
        entryType: 'OPENING_BALANCE',
        occurredOn: '2026-01-02',
      ),
      throwsA(anything),
    );
    expect(await database.select(database.customerTransactions).get(),
        hasLength(1));
  });

  test('rejects non-UUID request IDs without inserting ledger rows', () async {
    final customer = await customersService.createCustomer(_customerInput());

    await expectLater(
      () => paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: const OpeningBalanceInput(
          requestId: 'not-a-uuid',
          amount: 100,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.recordCollection(
        RecordCollectionInput(
          requestId: 'not-a-uuid',
          customerId: customer.id,
          amount: 10,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.addBalanceAdjustment(
        customerId: customer.id,
        input: const BalanceAdjustmentInput(
          requestId: 'not-a-uuid',
          direction: 'INCREASE',
          amount: 10,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    expect(await database.select(database.customerTransactions).get(), isEmpty);
  });

  test('rejects invalid occurred dates without inserting ledger rows',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await expectLater(
      () => paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: OpeningBalanceInput(
          requestId: _uuid(14),
          amount: 100,
          occurredOn: '2026-02-30',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.recordCollection(
        RecordCollectionInput(
          requestId: _uuid(15),
          customerId: customer.id,
          amount: 10,
          occurredOn: '2026-1-1',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.addBalanceAdjustment(
        customerId: customer.id,
        input: BalanceAdjustmentInput(
          requestId: _uuid(16),
          direction: 'DECREASE',
          amount: 10,
          occurredOn: 'not-a-date',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    expect(await database.select(database.customerTransactions).get(), isEmpty);
  });

  test('rejects customer ledger money precision and overflow locally',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await expectLater(
      () => paymentsService.addOpeningBalance(
        customerId: customer.id,
        input: OpeningBalanceInput(
          requestId: _uuid(17),
          amount: 1.001,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.recordCollection(
        RecordCollectionInput(
          requestId: _uuid(18),
          customerId: customer.id,
          amount: 1000000000000,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );
    await expectLater(
      () => paymentsService.addBalanceAdjustment(
        customerId: customer.id,
        input: BalanceAdjustmentInput(
          requestId: _uuid(19),
          direction: 'INCREASE',
          amount: -0.01,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );

    expect(await database.select(database.customerTransactions).get(), isEmpty);
  });

  test('stores valid customer ledger money with two decimal places locally',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await paymentsService.recordCollection(
      RecordCollectionInput(
        requestId: _uuid(20),
        customerId: customer.id,
        amount: 125.5,
        occurredOn: '2026-01-01',
      ),
    );

    final transaction =
        await database.select(database.customerTransactions).getSingle();
    expect(transaction.amount, '125.50');
  });

  test('rejects 1.005 deterministically using string-based validation',
      () async {
    final customer = await customersService.createCustomer(_customerInput());

    await expectLater(
      () => paymentsService.recordCollection(
        RecordCollectionInput(
          requestId: _uuid(21),
          customerId: customer.id,
          amount: 1.005,
          occurredOn: '2026-01-01',
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 422)),
    );

    expect(
        await database.select(database.customerTransactions).get(), isEmpty);
  });
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String address = '1 Market Road',
  String? phone = '9999999999',
  String gstin = '27ABCDE1234F1Z5',
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return CreateCustomerInput(
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

Future<void> _seedCustomer(
  LocalDatabase database, {
  required String id,
  required String name,
  required String? phone,
  required bool isActive,
}) {
  return database.into(database.customers).insert(
        CustomersCompanion.insert(
          id: id,
          name: name,
          address: 'Seeded address',
          phone: Value(phone),
          isActive: Value(isActive),
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        ),
      );
}

Future<void> _seedCustomerTransaction(
  LocalDatabase database, {
  required String id,
  required String customerId,
  required String requestId,
  required String entryType,
  required String occurredOn,
}) {
  return database.into(database.customerTransactions).insert(
        CustomerTransactionsCompanion.insert(
          id: id,
          customerId: customerId,
          requestId: Value(requestId),
          requestHash: const Value('request-hash'),
          openingBalanceCustomerId: Value(
            entryType == 'OPENING_BALANCE' ? customerId : null,
          ),
          entryType: entryType,
          amount: '100',
          occurredOn: occurredOn,
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-01T00:00:00.000Z',
        ),
      );
}
