import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/buyer.dart';
import 'package:internal_billing_khata_mobile/models/buyer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/buyer_detail_screen.dart';
import 'package:internal_billing_khata_mobile/screens/buyer_form_screen.dart';
import 'package:internal_billing_khata_mobile/screens/buyer_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/buyers_service.dart';
import 'package:internal_billing_khata_mobile/widgets/app_navigation_drawer.dart';

void main() {
  testWidgets('drawer shows Buyer tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: AppNavigationDrawer(
            selected: AppDestination.buyers,
            onSelect: (_) {},
            onLogout: () async {},
          ),
          appBar: AppBar(),
        ),
      ),
    );

    Scaffold.of(tester.element(find.byType(AppBar))).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Buyers'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsNothing);
  });

  testWidgets('Buyer list loads', (tester) async {
    final service = FakeBuyersService(
      buyers: const <Buyer>[
        Buyer(
          id: 'buyer-1',
          name: 'Global Suppliers',
          address: 'Market Yard',
          phone: null,
          gstin: null,
          state: null,
          stateCode: null,
          isActive: true,
          pendingPayable: 500,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: BuyerListScreen(buyersService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buyers'), findsOneWidget);
    expect(find.text('Global Suppliers'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
  });

  testWidgets('Add Buyer flow creates buyer and refreshes list',
      (tester) async {
    final service = FakeBuyersService();

    await tester.pumpWidget(
      MaterialApp(home: BuyerListScreen(buyersService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add buyer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('buyerNameField')), 'New Mill');
    await tester.enterText(
        find.byKey(const Key('buyerAddressField')), 'Mill Road');
    await tester.enterText(
        find.byKey(const Key('buyerPhoneField')), '7777777777');
    await tester.scrollUntilVisible(
      find.byKey(const Key('submitBuyerButton')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('submitBuyerButton')));
    await tester.pumpAndSettle();

    expect(service.createdInputs, hasLength(1));
    expect(service.createdInputs.single.name, 'New Mill');
    expect(find.text('New Mill'), findsOneWidget);
  });

  testWidgets('Buyer detail shows payable balance and ledger rows',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDetailScreen(
          buyerId: 'buyer-1',
          buyersService: FakeBuyersService(
            ledgers: <BuyerLedger>[
              BuyerLedger(
                buyer: _buyer,
                transactions: const <BuyerLedgerTransaction>[
                  BuyerLedgerTransaction(
                    id: 'txn-1',
                    entryType: 'PURCHASE_AMOUNT',
                    amount: '600.00',
                    occurredAt: '2026-04-20T10:30:00.000Z',
                    notes: 'Purchase bill',
                  ),
                  BuyerLedgerTransaction(
                    id: 'txn-2',
                    entryType: 'COLLECTION_MADE',
                    amount: '100.00',
                    occurredAt: '2026-04-21T10:30:00.000Z',
                    notes: 'UPI',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global Suppliers'), findsWidgets);
    expect(find.textContaining('Pending Payable: 500.00'), findsOneWidget);
    expect(find.text('PURCHASE_AMOUNT'), findsOneWidget);
    expect(find.text('COLLECTION_MADE'), findsOneWidget);
    expect(find.text('Purchase bill'), findsOneWidget);
  });

  testWidgets('add purchase amount, payment made, and adjustment forms',
      (tester) async {
    final service = FakeBuyersService(
      ledgers: <BuyerLedger>[
        BuyerLedger(
            buyer: _buyer, transactions: const <BuyerLedgerTransaction>[]),
        BuyerLedger(
          buyer: _buyer.copyWith(pendingPayable: 700),
          transactions: const <BuyerLedgerTransaction>[
            BuyerLedgerTransaction(
              id: 'txn-3',
              entryType: 'PURCHASE_AMOUNT',
              amount: '200.00',
              occurredAt: '2026-04-20T10:30:00.000Z',
              notes: 'Purchase',
            ),
          ],
        ),
        BuyerLedger(
          buyer: _buyer.copyWith(pendingPayable: 600),
          transactions: const <BuyerLedgerTransaction>[
            BuyerLedgerTransaction(
              id: 'txn-4',
              entryType: 'COLLECTION_MADE',
              amount: '100.00',
              occurredAt: '2026-04-21T10:30:00.000Z',
              notes: 'Paid',
            ),
          ],
        ),
        BuyerLedger(
          buyer: _buyer.copyWith(pendingPayable: 650),
          transactions: const <BuyerLedgerTransaction>[
            BuyerLedgerTransaction(
              id: 'txn-5',
              entryType: 'PAYABLE_INCREASE_ADJUSTMENT',
              amount: '50.00',
              occurredAt: '2026-04-22T10:30:00.000Z',
              notes: 'Correction',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDetailScreen(buyerId: 'buyer-1', buyersService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('purchaseAmountActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Purchase Amount'), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('buyerLedgerAmountField')), '200.10');
    await tester.enterText(
      find.byKey(const Key('buyerLedgerOccurredAtField')),
      '2026-04-20T10:30:00.000Z',
    );
    await tester.enterText(
        find.byKey(const Key('buyerLedgerNotesField')), 'Purchase');
    await tester.tap(find.byKey(const Key('submitBuyerLedgerEntryButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paymentMadeActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Payment Made'), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('buyerLedgerAmountField')), '100');
    await tester.enterText(
      find.byKey(const Key('buyerLedgerOccurredAtField')),
      '2026-04-21T10:30:00.000Z',
    );
    await tester.enterText(
        find.byKey(const Key('buyerLedgerNotesField')), 'Paid');
    await tester.tap(find.byKey(const Key('submitBuyerLedgerEntryButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('payableAdjustmentActionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Payable Adjustment'), findsWidgets);
    await tester.enterText(
        find.byKey(const Key('buyerLedgerAmountField')), '50');
    await tester.enterText(
      find.byKey(const Key('buyerLedgerOccurredAtField')),
      '2026-04-22T10:30:00.000Z',
    );
    await tester.enterText(
        find.byKey(const Key('buyerLedgerNotesField')), 'Correction');
    await tester.tap(find.byKey(const Key('submitBuyerLedgerEntryButton')));
    await tester.pumpAndSettle();

    expect(service.purchaseAmounts, hasLength(1));
    expect(service.purchaseAmounts.single.amount, '200.10');
    expect(service.paymentsMade, hasLength(1));
    expect(service.adjustments, hasLength(1));
    expect(service.fetchBuyerLedgerCount, 4);
    expect(find.textContaining('Pending Payable: 650.00'), findsOneWidget);
  });

  testWidgets('buyer ledger form rejects invalid money with clear error',
      (tester) async {
    final service = FakeBuyersService(
      ledgers: <BuyerLedger>[
        BuyerLedger(
            buyer: _buyer, transactions: const <BuyerLedgerTransaction>[]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDetailScreen(buyerId: 'buyer-1', buyersService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('purchaseAmountActionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('buyerLedgerAmountField')), '1.234');
    await tester.tap(find.byKey(const Key('submitBuyerLedgerEntryButton')));
    await tester.pumpAndSettle();

    expect(
        find.text('Amount must be greater than zero with at most 2 decimals'),
        findsOneWidget);
    expect(service.purchaseAmounts, isEmpty);
  });

  testWidgets('edit button on buyer detail navigates to form', (tester) async {
    final service = FakeBuyersService(
      ledgers: <BuyerLedger>[
        BuyerLedger(
            buyer: _buyer, transactions: const <BuyerLedgerTransaction>[]),
        BuyerLedger(
          buyer: _buyer.copyWith(
            name: 'Global Suppliers Edited',
            pendingPayable: 500,
          ),
          transactions: const <BuyerLedgerTransaction>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDetailScreen(buyerId: 'buyer-1', buyersService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editBuyerButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editBuyerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Edit buyer'), findsOneWidget);
    expect(find.byType(BuyerFormScreen), findsOneWidget);
  });

  testWidgets('buyer form in edit mode pre-fills fields and saves',
      (tester) async {
    final service = FakeBuyersService(
      ledgers: <BuyerLedger>[
        BuyerLedger(
            buyer: _buyer, transactions: const <BuyerLedgerTransaction>[]),
        BuyerLedger(
          buyer: _buyer.copyWith(
            name: 'Updated Suppliers',
            address: 'New Address',
            pendingPayable: 500,
          ),
          transactions: const <BuyerLedgerTransaction>[],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BuyerDetailScreen(buyerId: 'buyer-1', buyersService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editBuyerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Edit buyer'), findsOneWidget);
    expect(
        (tester
                .widget<TextField>(find.byKey(const Key('buyerNameField')))
                .controller
                ?.text ??
            ''),
        'Global Suppliers');

    await tester.enterText(
        find.byKey(const Key('buyerNameField')), 'Updated Suppliers');
    await tester.enterText(
        find.byKey(const Key('buyerAddressField')), 'New Address');
    await tester.scrollUntilVisible(
      find.byKey(const Key('submitBuyerButton')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('submitBuyerButton')));
    await tester.pumpAndSettle();

    expect(service.updateInputs, hasLength(1));
    expect(service.updateInputs.single.input.name, 'Updated Suppliers');
    expect(service.updateInputs.single.input.address, 'New Address');
    expect(find.textContaining('Updated Suppliers'), findsWidgets);
  });
}

const _buyer = Buyer(
  id: 'buyer-1',
  name: 'Global Suppliers',
  address: 'Market Yard',
  phone: null,
  gstin: null,
  state: null,
  stateCode: null,
  isActive: true,
  pendingPayable: 500,
);

class FakeBuyersService implements BuyersService {
  FakeBuyersService({
    this.buyers = const <Buyer>[],
    this.ledgers = const <BuyerLedger>[],
  });

  final List<CreateBuyerInput> createdInputs = <CreateBuyerInput>[];
  final List<BuyerLedgerEntryInput> purchaseAmounts = <BuyerLedgerEntryInput>[];
  final List<BuyerLedgerEntryInput> paymentsMade = <BuyerLedgerEntryInput>[];
  final List<BuyerPayableAdjustmentInput> adjustments =
      <BuyerPayableAdjustmentInput>[];
  final List<({String id, UpdateBuyerInput input})> updateInputs =
      <({String id, UpdateBuyerInput input})>[];
  final List<BuyerLedger> ledgers;
  List<Buyer> buyers;
  var fetchBuyerLedgerCount = 0;

  @override
  Future<Buyer> createBuyer(CreateBuyerInput input) async {
    createdInputs.add(input);
    final buyer = Buyer(
      id: 'buyer-${createdInputs.length}',
      name: input.name,
      address: input.address,
      phone: input.phone,
      gstin: input.gstin,
      state: input.state,
      stateCode: input.stateCode,
      isActive: true,
      pendingPayable: 0,
      whatsappNumber: input.whatsappNumber,
    );
    buyers = <Buyer>[...buyers, buyer];
    return buyer;
  }

  @override
  Future<Buyer> updateBuyer({
    required String id,
    required UpdateBuyerInput input,
  }) async {
    updateInputs.add((id: id, input: input));
    final index = buyers.indexWhere((b) => b.id == id);
    if (index == -1) {
      throw const ApiError(
          code: 'NOT_FOUND', message: 'Buyer not found', statusCode: 404);
    }
    final updated = buyers[index].copyWith(
      name: input.name,
      address: input.address,
      phone: input.phone,
      gstin: input.gstin,
      state: input.state,
      stateCode: input.stateCode,
      whatsappNumber: input.whatsappNumber,
    );
    buyers = <Buyer>[...buyers]..[index] = updated;
    return updated;
  }

  @override
  Future<void> addOpeningPayable({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {}

  @override
  Future<void> addPayableAdjustment({
    required String buyerId,
    required BuyerPayableAdjustmentInput input,
  }) async {
    adjustments.add(input);
  }

  @override
  Future<void> addPaymentMade({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {
    paymentsMade.add(input);
  }

  @override
  Future<void> addPurchaseAmount({
    required String buyerId,
    required BuyerLedgerEntryInput input,
  }) async {
    purchaseAmounts.add(input);
  }

  @override
  Future<BuyerLedger> fetchBuyerLedger(String buyerId) async {
    final index = fetchBuyerLedgerCount;
    fetchBuyerLedgerCount += 1;
    return ledgers[index.clamp(0, ledgers.length - 1)];
  }

  @override
  Future<List<Buyer>> fetchBuyers({String search = ''}) async => buyers;
}
