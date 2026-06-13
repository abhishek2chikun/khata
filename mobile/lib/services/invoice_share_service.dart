import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as launch_url;

import '../models/invoice_detail.dart';

String formatInvoiceShareCaption(InvoiceDetail invoice) {
  final documentType = invoice.gstFlag ? 'Tax Invoice' : 'Invoice';
  final balanceDue = invoice.grandTotal - invoice.paidAmount;
  final lines = <String>[
    invoice.companyName,
    '$documentType #${invoice.invoiceNumber} dated ${invoice.invoiceDate}',
    'Customer: ${invoice.customerName}',
    'Grand Total: ${invoice.grandTotal.toStringAsFixed(2)}',
  ];
  if (invoice.paidAmount > 0) {
    lines.add('Paid: ${invoice.paidAmount.toStringAsFixed(2)}');
  }
  if (balanceDue > 0.009) {
    lines.add('Balance Due: ${balanceDue.toStringAsFixed(2)}');
  }
  lines.add('Thank you for your business.');
  return lines.join('\n');
}

abstract class InvoiceShareService {
  Future<void> shareInvoicePdf(String filePath, {required String text});

  Future<void> shareViaSms(String phoneNumber);

  factory InvoiceShareService.production() = _ProductionInvoiceShareService;

  factory InvoiceShareService.withHandlers({
    required Future<void> Function(String filePath, String text) shareFile,
    required Future<bool> Function(String url) launchUrl,
  }) = _HandlerInvoiceShareService;
}

class _ProductionInvoiceShareService implements InvoiceShareService {
  @override
  Future<void> shareInvoicePdf(String filePath, {required String text}) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  @override
  Future<void> shareViaSms(String phoneNumber) async {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    await launch_url.launchUrl(Uri.parse('sms:$cleaned'));
  }

  static String _cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (!cleaned.startsWith('91') && cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned;
  }
}

class _HandlerInvoiceShareService implements InvoiceShareService {
  _HandlerInvoiceShareService({
    required Future<void> Function(String filePath, String text) shareFile,
    required Future<bool> Function(String url) launchUrl,
  })  : _shareFile = shareFile,
        _launchUrl = launchUrl;

  final Future<void> Function(String filePath, String text) _shareFile;
  final Future<bool> Function(String url) _launchUrl;

  @override
  Future<void> shareInvoicePdf(String filePath, {required String text}) async {
    await _shareFile(filePath, text);
  }

  @override
  Future<void> shareViaSms(String phoneNumber) async {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    await _launchUrl('sms:$cleaned');
  }

  static String _cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (!cleaned.startsWith('91') && cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned;
  }
}
