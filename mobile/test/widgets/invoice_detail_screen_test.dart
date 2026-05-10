import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/screens/invoice_detail_screen.dart';
import 'package:internal_billing_khata_mobile/services/invoice_share_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';

void main() {
  testWidgets('share button is visible when invoice is loaded',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceDetailScreen(
          invoiceId: 'inv-1',
          invoicesService: _FakeInvoicesService(
            invoice: _sampleInvoice(customerPhone: '9876543210'),
          ),
          shareService: _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sharePdfButton')), findsOneWidget);
  });

  testWidgets('tapping share button shows bottom sheet with options',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceDetailScreen(
          invoiceId: 'inv-1',
          invoicesService: _FakeInvoicesService(
            invoice: _sampleInvoice(customerPhone: '9876543210'),
          ),
          shareService: _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sharePdfButton')));
    await tester.pumpAndSettle();

    expect(find.text('Share Invoice'), findsOneWidget);
    expect(find.byKey(const Key('shareViaWhatsAppOption')), findsOneWidget);
    expect(find.byKey(const Key('shareViaSmsOption')), findsOneWidget);
    expect(find.byKey(const Key('shareViaSystemOption')), findsOneWidget);
  });

  testWidgets('share bottom sheet hides WhatsApp when no phone number',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceDetailScreen(
          invoiceId: 'inv-1',
          invoicesService: _FakeInvoicesService(
            invoice: _sampleInvoice(customerPhone: null),
          ),
          shareService: _FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sharePdfButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shareViaWhatsAppOption')), findsNothing);
    expect(find.byKey(const Key('shareViaSmsOption')), findsNothing);
    expect(find.byKey(const Key('shareViaSystemOption')), findsOneWidget);
  });
}

InvoiceDetail _sampleInvoice({String? customerPhone, String? customerWhatsappNumber}) {
  return InvoiceDetail(
    id: 'inv-1',
    customerId: 'cust-1',
    invoiceNumber: '42',
    status: 'ACTIVE',
    paymentState: 'CREDIT',
    paymentMode: 'CREDIT',
    customerName: 'Acme Stores',
    customerPhone: customerPhone,
    customerWhatsappNumber: customerWhatsappNumber,
    invoiceDate: '2026-01-10',
    grandTotal: 236,
    notes: null,
    cancelReason: null,
    items: const <InvoiceDetailItem>[
      InvoiceDetailItem(
        productId: 'prod-1',
        productName: 'Blue Pen',
        quantity: 2,
        lineTotal: 236,
      ),
    ],
  );
}

class _FakeInvoicesService implements InvoicesService {
  _FakeInvoicesService({required this.invoice});

  final InvoiceDetail invoice;

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) async => invoice;

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) {
    throw UnimplementedError();
  }
}

class _FakeShareService implements InvoiceShareService {
  final List<String> shareCalls = <String>[];
  final List<String> whatsAppCalls = <String>[];
  final List<String> smsCalls = <String>[];

  @override
  Future<void> shareInvoicePdf(String filePath) async {
    shareCalls.add(filePath);
  }

  @override
  Future<void> shareViaWhatsApp(String filePath, String phoneNumber,
      {String? whatsappNumber}) async {
    whatsAppCalls.add(whatsappNumber ?? phoneNumber);
  }

  @override
  Future<void> shareViaSms(String filePath, String phoneNumber) async {
    smsCalls.add(phoneNumber);
  }
}
