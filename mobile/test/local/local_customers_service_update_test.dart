import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
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

  test('updateCustomer updates name and persists', () async {
    final customer = await customersService.createCustomer(_customerInput());

    final updated = await customersService.updateCustomer(
      id: customer.id,
      input: UpdateCustomerInput(
        name: 'ABC Stores Updated',
        address: '10 New Market',
        phone: '9999999999',
        gstin: '27ABCDE1234F1Z6',
        state: 'Karnataka',
        stateCode: '29',
      ),
    );

    expect(updated.id, customer.id);
    expect(updated.name, 'ABC Stores Updated');
    expect(updated.address, '10 New Market');
    expect(updated.phone, '9999999999');
    expect(updated.gstin, '27ABCDE1234F1Z6');
    expect(updated.state, 'Karnataka');
    expect(updated.stateCode, '29');

    final storedCustomer =
        await database.select(database.customers).getSingle();
    expect(storedCustomer.name, 'ABC Stores Updated');
    expect(storedCustomer.address, '10 New Market');
    expect(storedCustomer.phone, '9999999999');
    expect(storedCustomer.isActive, isTrue);
  });

  test('updateCustomer with non-existent id throws NOT_FOUND', () async {
    await expectLater(
      () => customersService.updateCustomer(
        id: 'non-existent-id',
        input: UpdateCustomerInput(
          name: 'Test',
          address: 'Test Address',
        ),
      ),
      throwsA(_apiError(code: 'NOT_FOUND', statusCode: 404)),
    );
  });

  test('updateCustomer with duplicate name+phone throws DUPLICATE_CUSTOMER',
      () async {
    await customersService.createCustomer(
      _customerInput(name: 'Alpha Mills', phone: '1111111111'),
    );
    final beta = await customersService.createCustomer(
      _customerInput(name: 'Beta Fabrics', phone: '2222222222'),
    );

    await expectLater(
      () => customersService.updateCustomer(
        id: beta.id,
        input: UpdateCustomerInput(
          name: 'Alpha Mills',
          address: 'New Address',
          phone: '1111111111',
        ),
      ),
      throwsA(
          _apiError(code: 'DUPLICATE_CUSTOMER', statusCode: 409)),
    );
  });

  test('updateCustomer with same name+phone (self) succeeds', () async {
    final customer = await customersService.createCustomer(_customerInput());

    final updated = await customersService.updateCustomer(
      id: customer.id,
      input: UpdateCustomerInput(
        name: 'ABC Stores',
        address: 'Updated Address',
        phone: '9999999999',
      ),
    );

    expect(updated.name, 'ABC Stores');
    expect(updated.address, 'Updated Address');
  });

  test('updateCustomer persists whatsappNumber', () async {
    final customer = await customersService.createCustomer(_customerInput());

    final updated = await customersService.updateCustomer(
      id: customer.id,
      input: UpdateCustomerInput(
        name: 'ABC Stores',
        address: 'Market Yard',
        phone: '9999999999',
        whatsappNumber: '9876543210',
      ),
    );

    expect(updated.whatsappNumber, '9876543210');

    final storedCustomer =
        await database.select(database.customers).getSingle();
    expect(storedCustomer.whatsappNumber, '9876543210');
  });

  test('updateCustomer updates updated_at timestamp', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final originalUpdatedAt =
        (await database.select(database.customers).getSingle()).updatedAt;

    await customersService.updateCustomer(
      id: customer.id,
      input: UpdateCustomerInput(
        name: 'ABC Stores',
        address: 'Market Yard',
      ),
    );

    final storedCustomer =
        await database.select(database.customers).getSingle();
    expect(storedCustomer.updatedAt, isNot(equals(originalUpdatedAt)));
  });
}

CreateCustomerInput _customerInput({
  String name = 'ABC Stores',
  String address = 'Market Yard',
  String? phone = '9999999999',
  String gstin = '27ABCDE1234F1Z5',
  String state = 'Maharashtra',
  String stateCode = '27',
  String? whatsappNumber,
}) {
  return CreateCustomerInput(
    name: name,
    address: address,
    phone: phone,
    gstin: gstin,
    state: state,
    stateCode: stateCode,
    whatsappNumber: whatsappNumber,
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
