import 'package:flutter_test/flutter_test.dart';
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

  test('shareInvoicePdf calls shareFile with path and text', () async {
    await service.shareInvoicePdf('/tmp/invoice_42.pdf');

    expect(shareCalls, hasLength(1));
    expect(shareCalls.single.path, '/tmp/invoice_42.pdf');
    expect(shareCalls.single.text, 'Invoice');
  });

  test('shareViaWhatsApp calls launchUrl with cleaned wa.me URL', () async {
    await service.shareViaWhatsApp('/tmp/invoice_42.pdf', '9876543210');

    expect(launchCalls, hasLength(1));
    expect(launchCalls.single, 'https://wa.me/919876543210');
  });

  test('shareViaWhatsApp uses whatsapp number when provided', () async {
    await service.shareViaWhatsApp('/tmp/invoice_42.pdf', '9876543210',
        whatsappNumber: '919876543210');

    expect(launchCalls, hasLength(1));
    expect(launchCalls.single, 'https://wa.me/919876543210');
  });

  test('shareViaSms calls launchUrl with sms URI', () async {
    await service.shareViaSms('/tmp/invoice_42.pdf', '9876543210');

    expect(launchCalls, hasLength(1));
    expect(launchCalls.single, 'sms:919876543210');
  });

  group('phone number cleaning', () {
    test('adds 91 prefix to 10-digit number', () async {
      await service.shareViaWhatsApp('/tmp/f.pdf', '9876543210');
      expect(launchCalls.single, 'https://wa.me/919876543210');
    });

    test('does not add prefix if already has country code', () async {
      await service.shareViaWhatsApp('/tmp/f.pdf', '919876543210');
      expect(launchCalls.single, 'https://wa.me/919876543210');
    });

    test('strips spaces and dashes', () async {
      await service.shareViaWhatsApp('/tmp/f.pdf', '987-654 3210');
      expect(launchCalls.single, 'https://wa.me/919876543210');
    });

    test('strips plus sign', () async {
      await service.shareViaWhatsApp('/tmp/f.pdf', '+919876543210');
      expect(launchCalls.single, 'https://wa.me/919876543210');
    });

    test('strips parentheses', () async {
      await service.shareViaWhatsApp('/tmp/f.pdf', '(987) 654-3210');
      expect(launchCalls.single, 'https://wa.me/919876543210');
    });
  });
}

class _ShareCall {
  const _ShareCall({required this.path, required this.text});
  final String path;
  final String? text;
}
