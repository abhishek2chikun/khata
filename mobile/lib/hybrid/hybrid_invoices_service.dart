import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/invoice_summary.dart';
import '../services/decimal_validators.dart';
import '../services/invoices_service.dart';
import '../local/local_customers_service.dart';
import '../local/local_invoices_service.dart';
import 'hybrid_rpc_client.dart';

class HybridInvoicesService implements InvoicesService {
  HybridInvoicesService({
    required LocalInvoicesService localInvoicesService,
    required HybridRpcExecutor rpcClient,
    required Future<void> Function() refreshAfterWrite,
  })  : _localInvoicesService = localInvoicesService,
        _rpcClient = rpcClient,
        _refreshAfterWrite = refreshAfterWrite;

  final LocalInvoicesService _localInvoicesService;
  final HybridRpcExecutor _rpcClient;
  final Future<void> Function() _refreshAfterWrite;

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) {
    return _localInvoicesService.quoteInvoice(draft);
  }

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) async {
    final quote = await quoteInvoice(draft);
    final invoiceDatetime =
        '${draft.invoiceDate}T${DateTime.now().toUtc().toIso8601String().substring(11)}';
    final requestHash = _buildRequestHash(
      draft: draft,
      quote: quote,
      invoiceDatetime: invoiceDatetime,
    );
    final payload = _buildRpcPayload(
      draft: draft,
      quote: quote,
      invoiceDatetime: invoiceDatetime,
    );
    final result = await _rpcClient.invokeWrite(
      'create_invoice',
      <String, dynamic>{
        'p_request_id': requestId,
        'p_request_hash': requestHash,
        'p_invoice': payload,
      },
    );
    await _refreshAfterWrite();
    final invoiceId =
        (result['invoice'] as Map<String, dynamic>)['id'] as String;
    final invoice = await _localInvoicesService.fetchInvoiceDetail(invoiceId);
    return CreateInvoiceResult(invoice: invoice, warnings: quote.warnings);
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) {
    return _localInvoicesService.listInvoices(status: status);
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) {
    return _localInvoicesService.fetchInvoiceDetail(invoiceId);
  }

  @override
  Future<InvoiceDetail> cancelInvoice({
    required String invoiceId,
    required String reason,
  }) async {
    final cancelRequestId = generateLocalUuid();
    final requestHash = sha256
        .convert(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'request_id': cancelRequestId,
              'cancel_reason': reason,
            }),
          ),
        )
        .toString();
    await _rpcClient.invokeWrite(
      'cancel_invoice',
      <String, dynamic>{
        'p_invoice_id': invoiceId,
        'p_cancel_request_id': cancelRequestId,
        'p_cancel_request_hash': requestHash,
        'p_cancel_reason': reason,
      },
    );
    await _refreshAfterWrite();
    return _localInvoicesService.fetchInvoiceDetail(invoiceId);
  }

  Map<String, dynamic> _buildRpcPayload({
    required InvoiceDraft draft,
    required InvoiceQuote quote,
    required String invoiceDatetime,
  }) {
    final customer = draft.customer!;
    return <String, dynamic>{
      'customer_id': customer.id,
      'customer_name': customer.name,
      'customer_address': customer.address,
      'customer_state': customer.state,
      'customer_state_code': customer.stateCode,
      'customer_phone': customer.phone,
      'customer_gstin': customer.gstin,
      'place_of_supply_state': quote.placeOfSupplyState,
      'place_of_supply_state_code': quote.placeOfSupplyStateCode,
      'gst_flag': quote.gstFlag,
      'invoice_date': draft.invoiceDate,
      'invoice_datetime': invoiceDatetime,
      'tax_regime': quote.taxRegime,
      'payment_state': draft.paymentState,
      'paid_amount': draft.paidAmount,
      'subtotal': quote.totals.subtotal,
      'discount_total': quote.totals.discountTotal,
      'taxable_total': quote.totals.taxableTotal,
      'gst_total': quote.totals.gstTotal,
      'grand_total': quote.totals.grandTotal,
      'notes': draft.notes,
      'items': quote.items
          .map(
            (line) => <String, dynamic>{
              'product_id': line.productId,
              'quantity': line.quantity,
              'pricing_mode': line.pricingMode,
              'entered_unit_price': line.enteredUnitPrice,
              'unit_price_excl_tax': line.unitPriceExclTax,
              'unit_price_incl_tax': line.unitPriceInclTax,
              'gst_rate': line.gstRate,
              'cgst_rate': line.cgstRate,
              'sgst_rate': line.sgstRate,
              'igst_rate': line.igstRate,
              'discount_percent': line.discountPercent,
              'discount_amount': line.discountAmount,
              'taxable_amount': line.taxableAmount,
              'gst_amount': line.gstAmount,
              'cgst_amount': line.cgstAmount,
              'sgst_amount': line.sgstAmount,
              'igst_amount': line.igstAmount,
              'line_total': line.lineTotal,
              'revenue_amount': line.taxableAmount,
              'buying_amount': line.buyingPrice * line.quantity,
              'profit_amount':
                  line.taxableAmount - (line.buyingPrice * line.quantity),
            },
          )
          .toList(),
    };
  }

  String _buildRequestHash({
    required InvoiceDraft draft,
    required InvoiceQuote quote,
    required String invoiceDatetime,
  }) {
    final payload = <String, dynamic>{
      'customer_id': draft.customer?.id,
      'invoice_datetime': invoiceDatetime,
      'payment_state': draft.paymentState,
      'paid_amount': draft.paidAmount.toStringAsFixed(2),
      'place_of_supply_state_code': quote.placeOfSupplyStateCode,
      'gst_flag': quote.gstFlag,
      'notes': draft.notes?.trim().isEmpty ?? true ? null : draft.notes?.trim(),
      'items': quote.items
          .map(
            (line) => <String, dynamic>{
              'product_id': line.productId,
              'quantity': canonicalIntegralQuantityString(line.quantity),
              'pricing_mode': line.pricingMode,
              'unit_price': canonicalUnitPriceString(line.enteredUnitPrice),
              'gst_rate': line.gstRate.toStringAsFixed(2),
              'discount_percent': line.discountPercent.toStringAsFixed(2),
            },
          )
          .toList(),
    };
    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }
}
