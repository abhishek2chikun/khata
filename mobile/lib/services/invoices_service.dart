import 'dart:convert';

import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/invoice_summary.dart';
import 'payments_service.dart';
import 'api_client.dart';

class CreateInvoiceResult {
  const CreateInvoiceResult({required this.invoice, required this.warnings});

  final InvoiceDetail invoice;
  final List<InvoiceWarning> warnings;
}

abstract class InvoicesService {
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft);

  Future<CreateInvoiceResult> createInvoice(
      {required InvoiceDraft draft, required String requestId});

  Future<List<InvoiceSummary>> listInvoices({String? status});

  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId);

  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason});
}

class ApiInvoicesService implements InvoicesService {
  ApiInvoicesService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CreateInvoiceResult> createInvoice(
      {required InvoiceDraft draft, required String requestId}) async {
    final response = await _apiClient.post(
      '/invoices',
      body: <String, dynamic>{
        ...draft.toJson(),
        'request_id': requestId,
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateInvoiceResult(
      invoice: InvoiceDetail.fromJson(
          decoded['invoice'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
      warnings: (decoded['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceWarning.fromJson)
          .toList(),
    );
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async {
    final response =
        await _apiClient.post('/invoices/quote', body: draft.toJson());
    return InvoiceQuote.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) async {
    final response = await _apiClient.get(
      '/invoices',
      queryParameters: <String, String?>{
        'status': status,
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final invoices = decoded['invoices'] as List<dynamic>? ?? const <dynamic>[];
    return invoices
        .cast<Map<String, dynamic>>()
        .map(InvoiceSummary.fromJson)
        .toList();
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) async {
    final response = await _apiClient.get('/invoices/$invoiceId');
    return InvoiceDetail.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) async {
    final response = await _apiClient.post(
      '/invoices/$invoiceId/cancel',
      body: <String, dynamic>{
        'request_id': generateRequestId(),
        'cancel_reason': reason,
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return InvoiceDetail.fromJson(decoded['invoice'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
  }
}
