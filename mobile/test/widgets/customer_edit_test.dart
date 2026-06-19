import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/customer_detail_screen.dart';
import 'package:internal_billing_khata_mobile/screens/customer_form_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  testWidgets('edit button on customer detail navigates to form',
      (tester) async {
    final service = FakeCustomersServiceForEdit(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer.copyWith(
            name: 'ABC Stores Edited',
            pendingBalance: 500,
          ),
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: service,
          paymentsService: FakePaymentsServiceForEdit(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editCustomerButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Edit customer'), findsOneWidget);
    expect(find.byType(CustomerFormScreen), findsOneWidget);
  });

  testWidgets('customer form in edit mode pre-fills fields and saves',
      (tester) async {
    final service = FakeCustomersServiceForEdit(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer.copyWith(
            name: 'Updated Stores',
            address: 'New Address',
            pendingBalance: 500,
          ),
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: service,
          paymentsService: FakePaymentsServiceForEdit(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Edit customer'), findsOneWidget);
    expect(
        (tester
                .widget<TextField>(find.byKey(const Key('customerNameField')))
                .controller
                ?.text ??
            ''),
        'ABC Stores');

    await tester.enterText(
        find.byKey(const Key('customerNameField')), 'Updated Stores');
    await tester.enterText(
        find.byKey(const Key('customerAddressField')), 'New Address');
    await tester.scrollUntilVisible(
      find.byKey(const Key('submitCustomerButton')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('submitCustomerButton')));
    await tester.pumpAndSettle();

    expect(service.updateInputs, hasLength(1));
    expect(service.updateInputs.single.input.name, 'Updated Stores');
    expect(service.updateInputs.single.input.address, 'New Address');
    expect(find.textContaining('Updated Stores'), findsWidgets);
  });
}

const _customer = Customer(
  id: 'customer-1',
  name: 'ABC Stores',
  address: 'Market Yard',
  phone: '9999999999',
  gstin: '27BBBBB0000B1Z5',
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 500,
);

class FakeCustomersServiceForEdit implements CustomersService {
  FakeCustomersServiceForEdit({
    required this.ledgers,
    this.error,
  });

  final List<CustomerLedger> ledgers;
  final Object? error;
  var fetchCustomerLedgerCount = 0;
  final List<Customer> createdCustomers = <Customer>[];
  final List<({String id, UpdateCustomerInput input})> updateInputs =
      <({String id, UpdateCustomerInput input})>[];

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) async {
    final customer = Customer(
      id: 'customer-${createdCustomers.length + 1}',
      name: input.name,
      address: input.address,
      phone: input.phone,
      gstin: input.gstin,
      state: input.state,
      stateCode: input.stateCode,
      isActive: true,
      pendingBalance: 0,
      whatsappNumber: input.whatsappNumber,
    );
    createdCustomers.add(customer);
    return customer;
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) async {
    updateInputs.add((id: id, input: input));
    return Customer(
      id: id,
      name: input.name,
      address: input.address,
      phone: input.phone,
      gstin: input.gstin,
      state: input.state,
      stateCode: input.stateCode,
      isActive: true,
      pendingBalance: 500,
      whatsappNumber: input.whatsappNumber,
    );
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) async {
    if (error != null) {
      throw error!;
    }
    final index = fetchCustomerLedgerCount < ledgers.length
        ? fetchCustomerLedgerCount
        : ledgers.length - 1;
    fetchCustomerLedgerCount += 1;
    return ledgers[index];
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async {
    return createdCustomers;
  }
}

class FakePaymentsServiceForEdit implements PaymentsService {
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
  @override
  Future<CollectionGridData> loadCollectionGrid({
    required String fromDate,
    required String toDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BatchCollectionResult> recordCollectionBatch(
      BatchCollectionInput input) {
    throw UnimplementedError();
  }
}
