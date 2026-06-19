import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/services/invoice_share_service.dart';

void main() {
  late InvoiceShareService service;
  late List<_ShareCall> shareCalls;
  late List<String> launchCalls;

  setUp(() {
    shareCalls = <_ShareCall>[];
    launchCalls = <String>[];
    service = InvoiceShareService.withHandlers(
      shareFile: (path, text) async {
        shareCalls.add(_ShareCall(path: path, text: text));
      },
      launchUrl: (url) async {
        launchCalls.add(url);
        return true;
      },
    );
  });

  InvoiceDetail sampleInvoice({bool gstFlag = true}) {
    return InvoiceDetail(
      id: 'inv-1',
      customerId: 'cust-1',
      invoiceNumber: '42',
      status: 'ACTIVE',
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      paidAmount: 0,
      gstFlag: gstFlag,
      customerName: 'Acme Stores',
      customerGstin: '27ABCDE1234F1Z5',
      invoiceDate: '2026-01-10',
      grandTotal: 236,
      companyName: 'Khata Traders',
      companyGstin: '27XYZW9876A1Z5',
      companyBankAccount: '1234567890',
      notes: null,
      cancelReason: null,
      items: const <InvoiceDetailItem>[],
    );
  }

  test('shares pdf and formatted caption', () async {
    final invoice = sampleInvoice();
    final caption = formatInvoiceShareCaption(invoice);
    await service.shareInvoicePdf('/tmp/invoice_42.pdf', text: caption);

    expect(shareCalls, hasLength(1));
    expect(shareCalls.single.path, '/tmp/invoice_42.pdf');
    expect(shareCalls.single.text, contains('Khata Traders'));
    expect(
        shareCalls.single.text, contains('Tax Invoice #42 dated 2026-01-10'));
    expect(shareCalls.single.text, contains('Customer: Acme Stores'));
    expect(shareCalls.single.text, contains('Grand Total: 236.00'));
    expect(shareCalls.single.text, contains('Balance Due: 236.00'));
    expect(shareCalls.single.text, isNot(contains('GSTIN')));
    expect(shareCalls.single.text, isNot(contains('1234567890')));
    expect(shareCalls.single.text, isNot(contains('inv-1')));
  });

  test('non-gst caption uses invoice document type', () {
    final caption = formatInvoiceShareCaption(sampleInvoice(gstFlag: false));
    expect(caption, contains('Invoice #42 dated 2026-01-10'));
    expect(caption, isNot(contains('Tax Invoice')));
  });

  test('shareViaSms calls launchUrl with sms URI', () async {
    await service.shareViaSms('9876543210');

    expect(launchCalls, hasLength(1));
    expect(launchCalls.single, 'sms:919876543210');
  });

  group('phone number cleaning', () {
    test('adds 91 prefix to 10-digit number', () async {
      await service.shareViaSms('9876543210');
      expect(launchCalls.single, 'sms:919876543210');
    });

    test('does not add prefix if already has country code', () async {
      await service.shareViaSms('919876543210');
      expect(launchCalls.single, 'sms:919876543210');
    });

    test('strips spaces and dashes', () async {
      await service.shareViaSms('987-654 3210');
      expect(launchCalls.single, 'sms:919876543210');
    });

    test('strips plus sign', () async {
      await service.shareViaSms('+919876543210');
      expect(launchCalls.single, 'sms:919876543210');
    });

    test('strips parentheses', () async {
      await service.shareViaSms('(987) 654-3210');
      expect(launchCalls.single, 'sms:919876543210');
    });
  });
}

class _ShareCall {
  const _ShareCall({required this.path, required this.text});
  final String path;
  final String text;
}
