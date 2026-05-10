import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as launch_url;

abstract class InvoiceShareService {
  Future<void> shareInvoicePdf(String filePath);

  Future<void> shareViaWhatsApp(String filePath, String phoneNumber,
      {String? whatsappNumber});

  Future<void> shareViaSms(String filePath, String phoneNumber);

  factory InvoiceShareService.production() = _ProductionInvoiceShareService;

  factory InvoiceShareService.withHandlers({
    required Future<void> Function(String filePath, String? text) shareFile,
    required Future<bool> Function(String url) launchUrl,
  }) = _HandlerInvoiceShareService;
}

class _ProductionInvoiceShareService implements InvoiceShareService {
  @override
  Future<void> shareInvoicePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Invoice');
  }

  @override
  Future<void> shareViaWhatsApp(String filePath, String phoneNumber,
      {String? whatsappNumber}) async {
    final number = whatsappNumber ?? phoneNumber;
    final cleaned = _cleanPhoneNumber(number);
    await launch_url.launchUrl(Uri.parse('https://wa.me/$cleaned'));
  }

  @override
  Future<void> shareViaSms(String filePath, String phoneNumber) async {
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
    required Future<void> Function(String filePath, String? text) shareFile,
    required Future<bool> Function(String url) launchUrl,
  })  : _shareFile = shareFile,
        _launchUrl = launchUrl;

  final Future<void> Function(String filePath, String? text) _shareFile;
  final Future<bool> Function(String url) _launchUrl;

  @override
  Future<void> shareInvoicePdf(String filePath) async {
    await _shareFile(filePath, 'Invoice');
  }

  @override
  Future<void> shareViaWhatsApp(String filePath, String phoneNumber,
      {String? whatsappNumber}) async {
    final number = whatsappNumber ?? phoneNumber;
    final cleaned = _cleanPhoneNumber(number);
    await _launchUrl('https://wa.me/$cleaned');
  }

  @override
  Future<void> shareViaSms(String filePath, String phoneNumber) async {
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
