import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/invoice_summary.dart';

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
