import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_payments_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';

void main() {
  late LocalDatabase database;
  late LocalCustomersService customersService;
  late LocalPaymentsService paymentsService;

  setUp(() async {
    database = LocalDatabase.memory();
    customersService = LocalCustomersService(database: database);
    paymentsService = LocalPaymentsService(database: database);
    await database.into(database.localUsers).insert(
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
  });

  tearDown(() async {
    await database.close();
  });

  test('local schema uses customer tables not seller tables', () async {
    final tables = await database.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final names = tables.map((row) => row.read<String>('name')).toSet();

    expect(names, contains('customers'));
    expect(names, contains('customer_transactions'));
    expect(names, isNot(contains('sellers')));
    expect(names, isNot(contains('seller_transactions')));
  });

  test('customer khata ledger preserves balance math and deterministic ordering', () async {
    final customer = await customersService.createCustomer(
      const CreateCustomerInput(
        name: 'Acme Stores',
        address: '1 Market Road',
        phone: '9999999999',
        gstin: '27ABCDE1234F1Z5',
        state: 'Maharashtra',
        stateCode: '27',
      ),
    );

    await paymentsService.addBalanceAdjustment(
      customerId: customer.id,
      input: BalanceAdjustmentInput(
        requestId: _uuid(1),
        direction: 'INCREASE',
        amount: 50,
        occurredOn: '2026-01-03',
      ),
    );
    await paymentsService.addOpeningBalance(
      customerId: customer.id,
      input: OpeningBalanceInput(
        requestId: _uuid(2),
        amount: 500,
        occurredOn: '2026-01-01',
      ),
    );
    await paymentsService.recordCollection(
      RecordCollectionInput(
        requestId: _uuid(3),
        customerId: customer.id,
        amount: 100,
        occurredOn: '2026-01-02',
        notes: 'Cash received',
      ),
    );

    final ledger = await customersService.fetchCustomerLedger(customer.id);

    expect(ledger.customer.pendingBalance, 450);
    expect(
      ledger.transactions.map((transaction) => transaction.entryType),
      <String>['OPENING_BALANCE', 'COLLECTION', 'BALANCE_INCREASE_ADJUSTMENT'],
    );
    expect(ledger.transactions[1].notes, 'Cash received');
  });
}

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
}
