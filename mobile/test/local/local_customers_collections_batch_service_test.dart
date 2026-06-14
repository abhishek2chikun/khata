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
  late String today;
  late String openingDate;

  setUp(() async {
    database = LocalDatabase.memory();
    customersService = LocalCustomersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    await _seedLocalUser(database);
    today = _todayString();
    openingDate = _offsetDate(daysAgo: 4);
  });

  tearDown(() async {
    await database.close();
  });

  test('loadCollectionGrid returns active positive-balance customers only', () async {
    final owing = await customersService.createCustomer(_customerInput(name: 'Owing'));
    final zero = await customersService.createCustomer(
      _customerInput(name: 'Zero', phone: '2222222222'),
    );
    await paymentsService.addOpeningBalance(
      customerId: owing.id,
      input: OpeningBalanceInput(requestId: _uuid(1), amount: 500, occurredOn: openingDate),
    );
    await paymentsService.addOpeningBalance(
      customerId: zero.id,
      input: OpeningBalanceInput(requestId: _uuid(2), amount: 100, occurredOn: openingDate),
    );
    await paymentsService.recordCollection(
      RecordCollectionInput(
        requestId: _uuid(3),
        customerId: zero.id,
        amount: 100,
        occurredOn: today,
      ),
    );

    final grid = await paymentsService.loadCollectionGrid(
      fromDate: today,
      toDate: today,
    );

    expect(grid.dates, <String>[today]);
    expect(grid.customers.map((row) => row.name), <String>['Owing']);
    expect(grid.customers.single.pendingBalance, 500);
  });

  test('recordCollectionBatch commits atomically and supports idempotent retry', () async {
    final first = await customersService.createCustomer(_customerInput(name: 'Alpha'));
    final second = await customersService.createCustomer(
      _customerInput(name: 'Beta', phone: '2222222222'),
    );
    await paymentsService.addOpeningBalance(
      customerId: first.id,
      input: OpeningBalanceInput(requestId: _uuid(4), amount: 500, occurredOn: openingDate),
    );
    await paymentsService.addOpeningBalance(
      customerId: second.id,
      input: OpeningBalanceInput(requestId: _uuid(5), amount: 300, occurredOn: openingDate),
    );

    final requestId = _uuid(6);
    final yesterday = _offsetDate(daysAgo: 1);
    final input = BatchCollectionInput(
      requestId: requestId,
      entries: <BatchCollectionEntryInput>[
        BatchCollectionEntryInput(customerId: first.id, occurredOn: today, amount: 100),
        BatchCollectionEntryInput(customerId: second.id, occurredOn: today, amount: 50),
        BatchCollectionEntryInput(customerId: first.id, occurredOn: yesterday, amount: 25),
      ],
    );

    final firstResult = await paymentsService.recordCollectionBatch(input);
    final retryResult = await paymentsService.recordCollectionBatch(input);

    expect(firstResult.entryCount, 3);
    expect(firstResult.totalAmount, 175);
    expect(firstResult.affectedCustomers, 2);
    expect(firstResult.entryCount, retryResult.entryCount);
    expect(firstResult.totalAmount, retryResult.totalAmount);
    expect(firstResult.affectedCustomers, retryResult.affectedCustomers);
    expect(await database.select(database.customerTransactions).get(), hasLength(5));

    final firstBalance = (await customersService.fetchCustomers())
        .firstWhere((customer) => customer.id == first.id)
        .pendingBalance;
    final secondBalance = (await customersService.fetchCustomers())
        .firstWhere((customer) => customer.id == second.id)
        .pendingBalance;
    expect(firstBalance, 375);
    expect(secondBalance, 250);
  });

  test('recordCollectionBatch rejects duplicate cells and overpayment', () async {
    final customer = await customersService.createCustomer(_customerInput());
    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(requestId: _uuid(7), amount: 100, occurredOn: openingDate),
    );
    final yesterday = _offsetDate(daysAgo: 1);

    await expectLater(
      () => paymentsService.recordCollectionBatch(
        BatchCollectionInput(
          requestId: _uuid(8),
          entries: <BatchCollectionEntryInput>[
            BatchCollectionEntryInput(customerId: customer.id, occurredOn: today, amount: 60),
            BatchCollectionEntryInput(customerId: customer.id, occurredOn: today, amount: 10),
          ],
        ),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );

    await expectLater(
      () => paymentsService.recordCollectionBatch(
        BatchCollectionInput(
          requestId: _uuid(9),
          entries: <BatchCollectionEntryInput>[
            BatchCollectionEntryInput(customerId: customer.id, occurredOn: today, amount: 60),
            BatchCollectionEntryInput(customerId: customer.id, occurredOn: yesterday, amount: 50),
          ],
        ),
      ),
      throwsA(_apiError(code: 'STALE_BALANCE', statusCode: 409)),
    );

    final collections = await (database.select(database.customerTransactions)
          ..where((row) => row.entryType.equals('COLLECTION')))
        .get();
    expect(collections, isEmpty);
  });

  test('recordCollectionBatch rejects conflicting retry request id', () async {
    final customer = await customersService.createCustomer(_customerInput());
    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(requestId: _uuid(10), amount: 200, occurredOn: openingDate),
    );
    final requestId = _uuid(11);

    await paymentsService.recordCollectionBatch(
      BatchCollectionInput(
        requestId: requestId,
        entries: <BatchCollectionEntryInput>[
          BatchCollectionEntryInput(customerId: customer.id, occurredOn: today, amount: 50),
        ],
      ),
    );

    await expectLater(
      () => paymentsService.recordCollectionBatch(
        BatchCollectionInput(
          requestId: requestId,
          entries: <BatchCollectionEntryInput>[
            BatchCollectionEntryInput(customerId: customer.id, occurredOn: today, amount: 60),
          ],
        ),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
  });
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String address = '1 Market Road',
  String? phone = '9999999999',
}) {
  return CreateCustomerInput(name: name, address: address, phone: phone);
}

Matcher _apiError({required String code, required int statusCode}) {
  return isA<ApiError>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.statusCode, 'statusCode', statusCode);
}

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
}

String _todayString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _offsetDate({required int daysAgo}) {
  final date = DateTime.now().subtract(Duration(days: daysAgo));
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
