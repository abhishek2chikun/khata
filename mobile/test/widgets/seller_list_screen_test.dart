import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/models/seller_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/seller_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/payments_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  testWidgets('seller list filters sellers client side without refetching', (tester) async {
    final sellersService = FakeSellersService(
      sellers: const <Seller>[
        Seller(
          id: 'seller-1',
          name: 'ABC Stores',
          address: 'Market Yard',
          phone: null,
          gstin: null,
          state: null,
          stateCode: null,
          isActive: true,
          pendingBalance: 500,
        ),
        Seller(
          id: 'seller-2',
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
        home: SellerListScreen(
          sellersService: sellersService,
          paymentsService: FakePaymentsService(),
          onCreateInvoice: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsOneWidget);
    expect(find.text('XYZ Traders'), findsOneWidget);
    expect(sellersService.fetchCount, 1);

    await tester.enterText(find.byKey(const Key('sellerSearchField')), 'abc');
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsOneWidget);
    expect(find.text('XYZ Traders'), findsNothing);
    expect(sellersService.fetchCount, 1);
  });

  testWidgets('seller list shows network error banner when load throws socket exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SellerListScreen(
          sellersService: FakeSellersService(
            sellers: const <Seller>[],
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

class FakeSellersService implements SellersService {
  FakeSellersService({required this.sellers, this.error});

  final List<Seller> sellers;
  final Object? error;
  var fetchCount = 0;

  @override
  Future<Seller> createSeller(CreateSellerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Seller>> fetchSellers({String search = ''}) async {
    fetchCount += 1;
    if (error != null) {
      throw error!;
    }
    return sellers;
  }
}

class FakePaymentsService implements PaymentsService {
  @override
  Future<void> addBalanceAdjustment({
    required String sellerId,
    required BalanceAdjustmentInput input,
  }) async {}

  @override
  Future<void> addOpeningBalance({
    required String sellerId,
    required OpeningBalanceInput input,
  }) async {}

  @override
  Future<void> recordPayment(RecordPaymentInput input) async {}
}
