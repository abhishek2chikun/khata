import 'dart:convert';

import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import 'api_client.dart';

class CreateInvoiceResult {
  const CreateInvoiceResult({required this.invoice, required this.warnings});

  final InvoiceDetail invoice;
  final List<InvoiceWarning> warnings;
}

abstract class InvoicesService {
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft);

  Future<CreateInvoiceResult> createInvoice({required InvoiceDraft draft, required String requestId});
}

class ApiInvoicesService implements InvoicesService {
  ApiInvoicesService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CreateInvoiceResult> createInvoice({required InvoiceDraft draft, required String requestId}) async {
    final response = await _apiClient.post(
      '/invoices',
      body: <String, dynamic>{
        ...draft.toJson(),
        'request_id': requestId,
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateInvoiceResult(
      invoice: InvoiceDetail.fromJson(decoded['invoice'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      warnings: (decoded['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(InvoiceWarning.fromJson)
          .toList(),
    );
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async {
    final response = await _apiClient.post('/invoices/quote', body: draft.toJson());
    return InvoiceQuote.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
