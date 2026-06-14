import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/screens/customer_list_screen.dart';
import 'package:internal_billing_khata_mobile/services/balance_share_service.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
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

  testWidgets('previews daily all due summary', (tester) async {
    final shareService = _RecordingBalanceShareService();
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
          companyProfileService: _FakeCompanyProfileService(),
          balanceShareService: shareService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shareDailyBalanceButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Total: 600.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDailyBalanceShareButton')));
    await tester.pumpAndSettle();

    expect(shareService.sharedMessages, hasLength(1));
    expect(shareService.sharedMessages.single, contains('Total: 600.00'));
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
  Future<CompanyProfile> upsertCompanyProfile(
      UpsertCompanyProfileInput input) {
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
