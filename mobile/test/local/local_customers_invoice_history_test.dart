import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  late LocalDatabase database;
  late LocalCustomersService customersService;

  setUp(() async {
    database = LocalDatabase.memory();
    customersService = LocalCustomersService(database: database);
    await _seedLocalUser(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('fetchCustomerLedger includes invoices for the customer', () async {
    final customer = await customersService.createCustomer(_customerInput());
    await _seedInvoice(
      database,
      id: 'inv-1',
      customerId: customer.id,
      invoiceNumber: 1,
      invoiceDate: '2026-01-15',
      grandTotal: '500',
      paymentMode: 'CREDIT',
      status: 'ACTIVE',
    );

    final ledger = await customersService.fetchCustomerLedger(customer.id);

    expect(ledger.invoices, hasLength(1));
    expect(ledger.invoices.single.invoiceId, 'inv-1');
    expect(ledger.invoices.single.invoiceNumber, '1');
    expect(ledger.invoices.single.invoiceDate, '2026-01-15');
    expect(ledger.invoices.single.grandTotal, 500);
    expect(ledger.invoices.single.paymentMode, 'CREDIT');
    expect(ledger.invoices.single.status, 'ACTIVE');
  });

  test('fetchCustomerLedger excludes invoices from other customers', () async {
    final customerA = await customersService.createCustomer(
      _customerInput(name: 'Alpha Stores', phone: '1111111111'),
    );
    final customerB = await customersService.createCustomer(
      _customerInput(name: 'Beta Stores', phone: '2222222222'),
    );
    await _seedInvoice(
      database,
      id: 'inv-a',
      customerId: customerA.id,
      invoiceNumber: 1,
      invoiceDate: '2026-01-15',
      grandTotal: '300',
      paymentMode: 'CREDIT',
      status: 'ACTIVE',
    );
    await _seedInvoice(
      database,
      id: 'inv-b',
      customerId: customerB.id,
      invoiceNumber: 2,
      invoiceDate: '2026-01-16',
      grandTotal: '700',
      paymentMode: 'CREDIT',
      status: 'ACTIVE',
    );

    final ledgerA = await customersService.fetchCustomerLedger(customerA.id);
    final ledgerB = await customersService.fetchCustomerLedger(customerB.id);

    expect(ledgerA.invoices, hasLength(1));
    expect(ledgerA.invoices.single.invoiceId, 'inv-a');
    expect(ledgerB.invoices, hasLength(1));
    expect(ledgerB.invoices.single.invoiceId, 'inv-b');
  });

  test('fetchCustomerLedger includes CANCELED invoices', () async {
    final customer = await customersService.createCustomer(_customerInput());
    await _seedInvoice(
      database,
      id: 'inv-active',
      customerId: customer.id,
      invoiceNumber: 1,
      invoiceDate: '2026-01-15',
      grandTotal: '250',
      paymentMode: 'CREDIT',
      status: 'ACTIVE',
    );
    await _seedInvoice(
      database,
      id: 'inv-canceled',
      customerId: customer.id,
      invoiceNumber: 2,
      invoiceDate: '2026-01-16',
      grandTotal: '400',
      paymentMode: 'CREDIT',
      status: 'CANCELED',
    );

    final ledger = await customersService.fetchCustomerLedger(customer.id);

    expect(ledger.invoices, hasLength(2));
    final ids = ledger.invoices.map((e) => e.invoiceId).toList();
    expect(ids, containsAll(['inv-active', 'inv-canceled']));
  });
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String phone = '9999999999',
}) {
  return CreateCustomerInput(
    name: name,
    address: '1 Market Road',
    phone: phone,
    gstin: '27ABCDE1234F1Z5',
    state: 'Maharashtra',
    stateCode: '27',
  );
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

Future<void> _seedInvoice(
  LocalDatabase database, {
  required String id,
  required String customerId,
  required int invoiceNumber,
  required String invoiceDate,
  required String grandTotal,
  required String paymentMode,
  required String status,
}) {
  return database.into(database.invoices).insert(
        InvoicesCompanion.insert(
          id: id,
          requestId: 'req-$id',
          requestHash: 'hash-$id',
          invoiceNumber: invoiceNumber,
          customerId: customerId,
          customerName: 'Customer',
          customerAddress: 'Address',
          placeOfSupplyState: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          companyName: 'Company',
          companyAddress: 'Address',
          companyCity: 'City',
          companyState: 'Maharashtra',
          companyStateCode: '27',
          invoiceDate: invoiceDate,
          taxRegime: 'INTRA_STATE',
          status: status,
          paymentMode: paymentMode,
          subtotal: grandTotal,
          discountTotal: '0',
          taxableTotal: grandTotal,
          gstTotal: '0',
          grandTotal: grandTotal,
          createdByUserId: 'local-system-user',
          createdAt: '2026-01-01T00:00:00.000Z',
        ),
      );
}
