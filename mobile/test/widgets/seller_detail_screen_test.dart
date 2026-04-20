import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/models/seller_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/seller_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  testWidgets('seller detail loads profile balance ledger and invoices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: FakeSellersService(
            ledgers: <SellerLedger>[
              SellerLedger(
                seller: _seller,
                transactions: const <SellerLedgerTransaction>[
                  SellerLedgerTransaction(
                    id: 'txn-1',
                    entryType: 'PAYMENT',
                    amount: 100,
                    occurredOn: '2026-04-20',
                    notes: 'Cash collection',
                  ),
                ],
                invoices: const <SellerInvoiceHistoryEntry>[
                  SellerInvoiceHistoryEntry(
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
    expect(find.text('Cash collection'), findsOneWidget);
    expect(find.text('1001'), findsOneWidget);
  });

  testWidgets('seller detail refreshes after successful payment flow', (tester) async {
    final sellersService = FakeSellersService(
      ledgers: <SellerLedger>[
        SellerLedger(
          seller: _seller,
          transactions: const <SellerLedgerTransaction>[],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
        SellerLedger(
          seller: _seller.copyWith(pendingBalance: 375),
          transactions: const <SellerLedgerTransaction>[
            SellerLedgerTransaction(
              id: 'txn-2',
              entryType: 'PAYMENT',
              amount: 125,
              occurredOn: '2026-04-20',
              notes: 'Cash',
            ),
          ],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: sellersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recordPaymentActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paymentAmountField')), '125');
    await tester.enterText(find.byKey(const Key('paymentOccurredOnField')), '2026-04-20');
    await tester.enterText(find.byKey(const Key('paymentNotesField')), 'Cash');
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.recordedPayments, hasLength(1));
    expect(sellersService.fetchSellerLedgerCount, 2);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.textContaining('375'), findsWidgets);
  });

  testWidgets('seller detail refreshes after opening balance flow', (tester) async {
    final sellersService = FakeSellersService(
      ledgers: <SellerLedger>[
        SellerLedger(
          seller: _seller,
          transactions: const <SellerLedgerTransaction>[],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
        SellerLedger(
          seller: _seller.copyWith(pendingBalance: 700),
          transactions: const <SellerLedgerTransaction>[
            SellerLedgerTransaction(
              id: 'txn-3',
              entryType: 'OPENING_BALANCE',
              amount: 200,
              occurredOn: '2026-04-20',
              notes: null,
            ),
          ],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: sellersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openingBalanceActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('openingBalanceAmountField')), '200');
    await tester.enterText(find.byKey(const Key('openingBalanceOccurredOnField')), '2026-04-20');
    await tester.tap(find.byKey(const Key('submitOpeningBalanceButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.openingBalances, hasLength(1));
    expect(sellersService.fetchSellerLedgerCount, 2);
    expect(find.textContaining('700'), findsWidgets);
    expect(find.text('OPENING_BALANCE'), findsOneWidget);
  });

  testWidgets('seller detail refreshes after balance adjustment flow', (tester) async {
    final sellersService = FakeSellersService(
      ledgers: <SellerLedger>[
        SellerLedger(
          seller: _seller,
          transactions: const <SellerLedgerTransaction>[],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
        SellerLedger(
          seller: _seller.copyWith(pendingBalance: 450),
          transactions: const <SellerLedgerTransaction>[
            SellerLedgerTransaction(
              id: 'txn-4',
              entryType: 'BALANCE_ADJUSTMENT',
              amount: 50,
              occurredOn: '2026-04-20',
              notes: 'Correction',
            ),
          ],
          invoices: const <SellerInvoiceHistoryEntry>[],
        ),
      ],
    );
    final paymentsService = FakePaymentsService();

    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: sellersService,
          paymentsService: paymentsService,
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('balanceAdjustmentActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('balanceAdjustmentAmountField')), '50');
    await tester.enterText(find.byKey(const Key('balanceAdjustmentOccurredOnField')), '2026-04-20');
    await tester.enterText(find.byKey(const Key('balanceAdjustmentNotesField')), 'Correction');
    await tester.tap(find.byKey(const Key('submitBalanceAdjustmentButton')));
    await tester.pumpAndSettle();

    expect(paymentsService.adjustments, hasLength(1));
    expect(sellersService.fetchSellerLedgerCount, 2);
    expect(find.textContaining('450'), findsWidgets);
    expect(find.text('Correction'), findsOneWidget);
  });

  testWidgets('seller detail action buttons are wired', (tester) async {
    Seller? invoiceSeller;

    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: FakeSellersService(
            ledgers: <SellerLedger>[
              SellerLedger(
                seller: _seller,
                transactions: const <SellerLedgerTransaction>[],
                invoices: const <SellerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (seller) async {
            invoiceSeller = seller;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recordPaymentActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Record payment'), findsOneWidget);
    Navigator.of(tester.element(find.text('Record payment'))).pop();
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
    expect(invoiceSeller?.id, 'seller-1');
  });

  testWidgets('seller detail disables create invoice for archived seller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: FakeSellersService(
            ledgers: <SellerLedger>[
              SellerLedger(
                seller: _seller.copyWith(isActive: false),
                transactions: const <SellerLedgerTransaction>[],
                invoices: const <SellerInvoiceHistoryEntry>[],
              ),
            ],
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(find.byKey(const Key('createInvoiceActionButton')));
    expect(button.onPressed, isNull);
    expect(find.text('Create invoice unavailable for archived sellers'), findsOneWidget);
  });

  testWidgets('seller detail shows error banner when load fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: FakeSellersService(
            ledgers: <SellerLedger>[],
            error: const ApiError(message: 'Unable to load seller detail'),
          ),
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load seller detail'), findsOneWidget);
  });

  testWidgets('seller detail shows network error banner when load throws socket exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerDetailScreen(
          sellerId: 'seller-1',
          sellersService: FakeSellersService(
            ledgers: <SellerLedger>[],
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

const _seller = Seller(
  id: 'seller-1',
  name: 'ABC Stores',
  address: 'Market Yard',
  phone: '9999999999',
  gstin: '27BBBBB0000B1Z5',
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 500,
);

class FakeSellersService implements SellersService {
  FakeSellersService({required this.ledgers, this.error});

  final List<SellerLedger> ledgers;
  final Object? error;
  var fetchSellerLedgerCount = 0;

  @override
  Future<Seller> createSeller(CreateSellerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) async {
    if (error != null) {
      throw error!;
    }
    final index = fetchSellerLedgerCount < ledgers.length ? fetchSellerLedgerCount : ledgers.length - 1;
    fetchSellerLedgerCount += 1;
    return ledgers[index];
  }

  @override
  Future<List<Seller>> fetchSellers({String search = ''}) {
    throw UnimplementedError();
  }
}

class FakePaymentsService implements PaymentsService {
  final List<RecordPaymentInput> recordedPayments = <RecordPaymentInput>[];
  final List<_OpeningBalanceCall> openingBalances = <_OpeningBalanceCall>[];
  final List<_BalanceAdjustmentCall> adjustments = <_BalanceAdjustmentCall>[];

  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) async {
    adjustments.add(_BalanceAdjustmentCall(sellerId: sellerId, input: input));
  }

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) async {
    openingBalances.add(_OpeningBalanceCall(sellerId: sellerId, input: input));
  }

  @override
  Future<void> recordPayment(RecordPaymentInput input) async {
    recordedPayments.add(input);
  }
}

class _OpeningBalanceCall {
  const _OpeningBalanceCall({required this.sellerId, required this.input});

  final String sellerId;
  final OpeningBalanceInput input;
}

class _BalanceAdjustmentCall {
  const _BalanceAdjustmentCall({required this.sellerId, required this.input});

  final String sellerId;
  final BalanceAdjustmentInput input;
}
