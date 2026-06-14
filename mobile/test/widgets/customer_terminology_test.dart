import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/customer_detail_screen.dart';
import 'package:internal_billing_khata_mobile/screens/customer_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/widgets/app_navigation_drawer.dart';

void main() {
  testWidgets('drawer shows Customers/Khata and not Sellers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: AppNavigationDrawer(
            selected: AppDestination.customers,
            onSelect: (_) {},
            onLogout: () async {},
          ),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Customers/Khata'), findsOneWidget);
    expect(find.text('Sellers'), findsNothing);
  });

  testWidgets('customer list uses customer khata labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerListScreen(
          customersService: _FakeCustomersService(
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
            ],
          ),
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customers/Khata'), findsOneWidget);
    expect(find.text('Add customer'), findsOneWidget);
    expect(find.text('Search customers'), findsOneWidget);
    expect(find.textContaining('Seller'), findsNothing);
  });

  testWidgets('customer detail uses customer khata labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: _FakeCustomersService(
            ledgers: const <CustomerLedger>[
              CustomerLedger(
                customer: Customer(
                  id: 'customer-1',
                  name: 'ABC Stores',
                  address: 'Market Yard',
                  phone: null,
                  gstin: null,
                  state: null,
                  stateCode: null,
                  isActive: true,
                  pendingBalance: 450,
                ),
                transactions: <CustomerLedgerTransaction>[
                  CustomerLedgerTransaction(
                    id: 'txn-1',
                    entryType: 'COLLECTION',
                    amount: 100,
                    occurredOn: '2026-04-20',
                    notes: 'Cash',
                  ),
                ],
                invoices: <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Customer khata'), findsOneWidget);
    expect(find.text('Collect money'), findsOneWidget);
    expect(find.text('Ledger history'), findsOneWidget);
    expect(find.textContaining('Seller'), findsNothing);
  });
}

class _FakeCustomersService implements CustomersService {
  _FakeCustomersService(
      {this.customers = const <Customer>[],
      this.ledgers = const <CustomerLedger>[]});

  final List<Customer> customers;
  final List<CustomerLedger> ledgers;

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
          {String? onDate}) async =>
      ledgers.single;

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async =>
      customers;
}

class _FakePaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment(
      {required String customerId,
      required BalanceAdjustmentInput input}) async {}

  @override
  Future<void> addOpeningBalance(
      {required String customerId, required OpeningBalanceInput input}) async {}

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {}
  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(BatchCollectionInput input) {
    throw UnimplementedError();
  }

}
