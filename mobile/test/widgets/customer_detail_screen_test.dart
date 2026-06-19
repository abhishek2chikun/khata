import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/screens/customer_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/balance_share_service.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
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
          paymentsService: _FakePaymentsService(),
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
    expect(
        find.text(_dateTimeString(
            DateTime.parse('2026-04-20T10:30:00.000Z').toLocal())),
        findsOneWidget);
    expect(find.text('Cash collection'), findsOneWidget);
    expect(find.text('1001'), findsOneWidget);
  });

  testWidgets('customer detail parses timezone-aware ledger timestamps',
      (tester) async {
    const createdAt = '2026-04-20T10:30:00+05:30';
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
                    id: 'txn-offset',
                    entryType: 'COLLECTION',
                    amount: 100,
                    occurredOn: '2026-04-20',
                    createdAt: createdAt,
                    notes: 'Offset timestamp',
                  ),
                ],
                invoices: const <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_dateTimeString(DateTime.parse(createdAt).toLocal())),
        findsOneWidget);
  });

  testWidgets('customer detail does not falsely format invalid timestamps',
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
                    id: 'txn-invalid-time',
                    entryType: 'COLLECTION',
                    amount: 100,
                    occurredOn: '2026-04-19',
                    createdAt: '2026-04-20T10:30-not-a-real-time',
                    notes: 'Invalid timestamp',
                  ),
                ],
                invoices: const <CustomerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-04-20 10:30'), findsNothing);
    expect(find.text('2026-04-19'), findsOneWidget);
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
          paymentsService: _FakePaymentsService(),
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
          paymentsService: _FakePaymentsService(),
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

  testWidgets('customer detail uses date picker to refresh ledger date',
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
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = _dateString(now);
    final selectedDate = _dateString(
      DateTime(now.year, now.month, now.day == 1 ? 1 : now.day - 1),
    );
    final selectedDay = int.parse(selectedDate.substring(8, 10)).toString();

    await tester.scrollUntilVisible(
      find.byKey(const Key('ledgerDateFilterField')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('ledgerDateFilterField')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);

    await tester.tap(find.text(selectedDay).last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(customersService.requestedLedgerDates, <String?>[
      today,
      selectedDate,
    ]);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('ledgerDateFilterField')))
          .controller
          ?.text,
      selectedDate,
    );
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
    final paymentsService = _FakePaymentsService();

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
    final paymentsService = _FakePaymentsService();

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
    final paymentsService = _FakePaymentsService();

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
          paymentsService: _FakePaymentsService(),
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
          paymentsService: _FakePaymentsService(),
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
          paymentsService: _FakePaymentsService(),
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
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to reach the server'), findsOneWidget);
  });

  testWidgets('previews and shares individual balance', (tester) async {
    final shareService = _RecordingBalanceShareService();
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
          paymentsService: _FakePaymentsService(),
          onCreateInvoice: (_) async => false,
          companyProfileService: _FakeCompanyProfileService(),
          balanceShareService: shareService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareIndividualBalanceButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pending balance: 500.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancelBalanceShareButton')));
    await tester.pumpAndSettle();
    expect(shareService.sharedMessages, isEmpty);

    await tester.tap(find.byKey(const Key('shareIndividualBalanceButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmBalanceShareButton')));
    await tester.pumpAndSettle();

    expect(shareService.sharedMessages, hasLength(1));
    expect(shareService.sharedMessages.single, contains('ABC Stores'));
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

String _dateString(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _dateTimeString(DateTime value) {
  return '${_dateString(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

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
  Future<Customer> updateCustomer({
    required String id,
    required UpdateCustomerInput input,
  }) {
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

class _FakePaymentsService implements PaymentsService {
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

class _FakeCompanyProfileService implements CompanyProfileService {
  @override
  Future<CompanyProfile> fetchCompanyProfile() async {
    return const CompanyProfile(
      id: 'profile-1',
      name: 'Khata Traders',
      address: '10 Market Road',
      city: 'Mumbai',
      state: 'Maharashtra',
      stateCode: '27',
      gstin: null,
      phone: '9999999999',
      email: 'info@khata.com',
      bankName: 'State Bank',
      bankAccount: '1234567890',
      bankIfsc: 'SBIN0001234',
      bankBranch: 'Main',
      jurisdiction: 'IN',
      isActive: true,
    );
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(UpsertCompanyProfileInput input) {
    throw UnimplementedError();
  }
}

class _RecordingBalanceShareService implements BalanceShareService {
  final List<String> sharedMessages = <String>[];

  @override
  Future<void> shareText(String message) async {
    sharedMessages.add(message);
  }
}
