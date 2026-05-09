import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/customer_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  testWidgets('customer detail loads profile balance ledger and invoices',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[
              CustomerLedger(
                customer: _customer,
                transactions: const <CustomerLedgerTransaction>[
                  CustomerLedgerTransaction(
                    id: 'txn-1',
                    entryType: 'COLLECTION',
                    amount: 100,
                    occurredOn: '2026-04-20',
                    createdAt: '2026-04-20T10:30:00.000Z',
                    notes: 'Cash collection',
                  ),
                ],
                invoices: const <CustomerInvoiceHistoryEntry>[
                  CustomerInvoiceHistoryEntry(
                    invoiceId: 'inv-1',
                    invoiceNumber: '1001',
                    invoiceDate: '2026-04-18',
                    grandTotal: 600,
                    paymentMode: 'CREDIT',
                    status: 'ACTIVE',
                  ),
                ],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsWidgets);
    expect(find.text('Market Yard'), findsOneWidget);
    expect(find.textContaining('500'), findsWidgets);
    expect(find.text('Collect money'), findsOneWidget);
    expect(find.text('Increase balance'), findsOneWidget);
    expect(find.text('Decrease balance'), findsOneWidget);
    expect(find.text('Ledger history'), findsOneWidget);
    expect(find.text('2026-04-20 10:30'), findsOneWidget);
    expect(find.text('Cash collection'), findsOneWidget);
    expect(find.text('1001'), findsOneWidget);
  });

  testWidgets('customer detail payment forms default occurred date to today',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[
              CustomerLedger(
                customer: _customer,
                transactions: const <CustomerLedgerTransaction>[],
                invoices: const <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await tester.tap(find.byKey(const Key('recordCollectionActionButton')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const Key('collectionOccurredOnField')))
            .controller
            ?.text,
        today);
    Navigator.of(tester.element(find.text('Record collection'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openingBalanceActionButton')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const Key('openingBalanceOccurredOnField')))
            .controller
            ?.text,
        today);
    Navigator.of(tester.element(find.text('Add opening balance'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('balanceAdjustmentActionButton')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const Key('balanceAdjustmentOccurredOnField')))
            .controller
            ?.text,
        today);
  });

  testWidgets('customer detail filters ledger by today by default',
      (tester) async {
    final customersService = FakeCustomersService(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: customersService,
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    expect(find.byKey(const Key('ledgerDateFilterField')), findsOneWidget);
    expect(find.text('Ledger date'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('ledgerDateFilterField')))
          .controller
          ?.text,
      today,
    );
    expect(customersService.requestedLedgerDates, <String?>[today]);
  });

  testWidgets('customer detail refreshes ledger when date filter changes',
      (tester) async {
    final customersService = FakeCustomersService(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[
            CustomerLedgerTransaction(
              id: 'txn-today',
              entryType: 'COLLECTION',
              amount: 50,
              occurredOn: '2026-04-20',
              notes: 'Today row',
            ),
          ],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[
            CustomerLedgerTransaction(
              id: 'txn-selected',
              entryType: 'COLLECTION',
              amount: 75,
              occurredOn: '2026-04-18',
              notes: 'Selected date row',
            ),
          ],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: customersService,
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await tester.enterText(
      find.byKey(const Key('ledgerDateFilterField')),
      '2026-04-18',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(customersService.requestedLedgerDates, <String?>[
      today,
      '2026-04-18',
    ]);
    expect(find.text('Selected date row'), findsOneWidget);
  });

  testWidgets('customer detail refreshes after successful payment flow',
      (tester) async {
    final customersService = FakeCustomersService(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer.copyWith(pendingBalance: 375),
          transactions: const <CustomerLedgerTransaction>[
            CustomerLedgerTransaction(
              id: 'txn-2',
              entryType: 'COLLECTION',
              amount: 125,
              occurredOn: '2026-04-20',
              notes: 'Cash',
            ),
          ],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: customersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recordCollectionActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('collectionAmountField')), '125');
    await tester.enterText(
        find.byKey(const Key('collectionOccurredOnField')), '2026-04-20');
    await tester.enterText(
        find.byKey(const Key('collectionNotesField')), 'Cash');
    await tester.tap(find.byKey(const Key('submitCollectionButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.recordedCollections, hasLength(1));
    expect(customersService.fetchCustomerLedgerCount, 2);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.textContaining('375'), findsWidgets);
  });

  testWidgets('customer detail refreshes after opening balance flow',
      (tester) async {
    final customersService = FakeCustomersService(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer.copyWith(pendingBalance: 700),
          transactions: const <CustomerLedgerTransaction>[
            CustomerLedgerTransaction(
              id: 'txn-3',
              entryType: 'OPENING_BALANCE',
              amount: 200,
              occurredOn: '2026-04-20',
              notes: null,
            ),
          ],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: customersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openingBalanceActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('openingBalanceAmountField')), '200');
    await tester.enterText(
        find.byKey(const Key('openingBalanceOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.openingBalances, hasLength(1));
    expect(customersService.fetchCustomerLedgerCount, 2);
    expect(find.textContaining('700'), findsWidgets);
    expect(find.text('OPENING_BALANCE'), findsOneWidget);
  });

  testWidgets('customer detail refreshes after balance adjustment flow',
      (tester) async {
    final customersService = FakeCustomersService(
      ledgers: <CustomerLedger>[
        CustomerLedger(
          customer: _customer,
          transactions: const <CustomerLedgerTransaction>[],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
        CustomerLedger(
          customer: _customer.copyWith(pendingBalance: 450),
          transactions: const <CustomerLedgerTransaction>[
            CustomerLedgerTransaction(
              id: 'txn-4',
              entryType: 'BALANCE_ADJUSTMENT',
              amount: 50,
              occurredOn: '2026-04-20',
              notes: 'Correction',
            ),
          ],
          invoices: const <CustomerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: customersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('balanceAdjustmentActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('balanceAdjustmentAmountField')), '50');
    await tester.enterText(
        find.byKey(const Key('balanceAdjustmentOccurredOnField')),
        '2026-04-20');
    await tester.enterText(
        find.byKey(const Key('balanceAdjustmentNotesField')), 'Correction');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.adjustments, hasLength(1));
    expect(customersService.fetchCustomerLedgerCount, 2);
    expect(find.textContaining('450'), findsWidgets);
    expect(find.text('Correction'), findsOneWidget);
  });

  testWidgets('customer detail action buttons are wired', (tester) async {
    Customer? invoiceCustomer;

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[
              CustomerLedger(
                customer: _customer,
                transactions: const <CustomerLedgerTransaction>[],
                invoices: const <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (customer) async {
            invoiceCustomer = customer;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recordCollectionActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Record collection'), findsOneWidget);
    Navigator.of(tester.element(find.text('Record collection'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openingBalanceActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Add opening balance'), findsOneWidget);
    Navigator.of(tester.element(find.text('Add opening balance'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('balanceAdjustmentActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Balance adjustment'), findsOneWidget);
    Navigator.of(tester.element(find.text('Balance adjustment'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createInvoiceActionButton')));
    await tester.pump();
    expect(invoiceCustomer?.id, 'customer-1');
  });

  testWidgets('customer detail disables create invoice for archived customer',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[
              CustomerLedger(
                customer: _customer.copyWith(isActive: false),
                transactions: const <CustomerLedgerTransaction>[],
                invoices: const <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('createInvoiceActionButton')));
    expect(button.onPressed, isNull);
    expect(find.text('Create invoice unavailable for archived customers'),
        findsOneWidget);
  });

  testWidgets('customer detail shows error banner when load fails',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[],
            error: const ApiError(message: 'Unable to load customer detail'),
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load customer detail'), findsOneWidget);
  });

  testWidgets(
      'customer detail shows network error banner when load throws socket exception',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          customerId: 'customer-1',
          customersService: FakeCustomersService(
            ledgers: <CustomerLedger>[],
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

class FakeCustomersService implements CustomersService {
  FakeCustomersService({required this.ledgers, this.error});

  final List<CustomerLedger> ledgers;
  final Object? error;
  var fetchCustomerLedgerCount = 0;
  final requestedLedgerDates = <String?>[];

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) async {
    requestedLedgerDates.add(onDate);
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
  Future<List<Customer>> fetchCustomers({String search = ''}) {
    throw UnimplementedError();
  }
}

class FakePaymentsService implements PaymentsService {
  final List<RecordCollectionInput> recordedCollections =
      <RecordCollectionInput>[];
  final List<_OpeningBalanceCall> openingBalances = <_OpeningBalanceCall>[];
  final List<_BalanceAdjustmentCall> adjustments = <_BalanceAdjustmentCall>[];

  @override
  Future<void> addBalanceAdjustment({
    required String customerId,
    required BalanceAdjustmentInput input,
  }) async {
    adjustments
        .add(_BalanceAdjustmentCall(customerId: customerId, input: input));
  }

  @override
  Future<void> addOpeningBalance({
    required String customerId,
    required OpeningBalanceInput input,
  }) async {
    openingBalances
        .add(_OpeningBalanceCall(customerId: customerId, input: input));
  }

  @override
  Future<void> recordCollection(RecordCollectionInput input) async {
    recordedCollections.add(input);
  }
}

class _OpeningBalanceCall {
  const _OpeningBalanceCall({required this.customerId, required this.input});

  final String customerId;
  final OpeningBalanceInput input;
}

class _BalanceAdjustmentCall {
  const _BalanceAdjustmentCall({required this.customerId, required this.input});

  final String customerId;
  final BalanceAdjustmentInput input;
}
