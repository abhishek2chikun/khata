import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/customer_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  testWidgets('customer list filters customers client side without refetching',
      (tester) async {
    final customersService = FakeCustomersService(
      customers: const <Customer>[
        Customer(
          id: 'customer-1',
          name: 'ABC Stores',
          address: 'Market Yard',
          phone: null,
          gstin: null,
          state: null,
          stateCode: null,
          isActive: true,
          pendingBalance: 500,
        ),
        Customer(
          id: 'customer-2',
          name: 'XYZ Traders',
          address: 'Station Road',
          phone: null,
          gstin: null,
          state: null,
          stateCode: null,
          isActive: true,
          pendingBalance: 100,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerListScreen(
          customersService: customersService,
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsOneWidget);
    expect(find.text('XYZ Traders'), findsOneWidget);
    expect(customersService.fetchCount, 1);

    await tester.enterText(find.byKey(const Key('customerSearchField')), 'abc');
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsOneWidget);
    expect(find.text('XYZ Traders'), findsNothing);
    expect(customersService.fetchCount, 1);
  });

  testWidgets(
      'customer list shows network error banner when load throws socket exception',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerListScreen(
          customersService: FakeCustomersService(
            customers: const <Customer>[],
            error: const SocketException('timed out'),
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to reach the server'), findsOneWidget);
  });
}

class FakeCustomersService implements CustomersService {
  FakeCustomersService({required this.customers, this.error});

  final List<Customer> customers;
  final Object? error;
  var fetchCount = 0;

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async {
    fetchCount += 1;
    if (error != null) {
      throw error!;
    }
    return customers;
  }
}

class FakePaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) async {}

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) async {}

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {}
}
