import 'package:flutter/material.dart';

import '../models/company_profile.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_quote.dart';
import '../services/invoice_pdf_service.dart';
import '../services/decimal_validators.dart';
import '../services/invoice_preview_builder.dart';
import '../services/invoice_settlement.dart';
import '../services/invoice_share_service.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';
import 'invoice_pdf_preview_screen.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.controller,
    this.companyProfile,
    this.shareService,
  });

  final InvoiceDraftController controller;
  final CompanyProfile? companyProfile;
  final InvoiceShareService? shareService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final quote = controller.quote;
        final createdInvoice = controller.createdInvoice;
        return Scaffold(
          appBar: AppBar(title: const Text('Invoice preview')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (controller.submitErrorMessage != null) ...<Widget>[
                  ErrorBanner(message: controller.submitErrorMessage!),
                  const SizedBox(height: 16),
                ],
                if (quote != null) ...<Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppInfoRow(
                            label: 'Customer',
                            value: controller.draft.customer?.name ?? '',
                            emphasized: true,
                          ),
                          AppInfoRow(
                            label: 'Invoice type',
                            value: quote.gstFlag
                                ? 'GST invoice'
                                : 'Non-GST invoice',
                          ),
                          AppInfoRow(
                            label: 'Date',
                            value: controller.draft.invoiceDate,
                          ),
                          if (quote.gstFlag)
                            AppInfoRow(
                              label: 'Place of supply',
                              value:
                                  '${quote.placeOfSupplyState} (${quote.placeOfSupplyStateCode})',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentModeSection(context),
                  const SizedBox(height: 12),
                  ...quote.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(warning.message),
                    ),
                  ),
                  const AppSectionHeader(title: 'Items'),
                  const SizedBox(height: 8),
                  _buildItemsTable(context, quote),
                  const SizedBox(height: 16),
                  const AppSectionHeader(title: 'Totals'),
                  const SizedBox(height: 8),
                  _buildTotals(context, quote),
                ],
                if (createdInvoice != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text('Invoice created',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Invoice #${createdInvoice.invoiceNumber}'),
                  ...controller.createWarnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(warning.message),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (shareService != null)
                    _PostCreationShareButtons(
                      invoice: createdInvoice,
                      customerPhone: controller.draft.customer?.phone,
                      shareService: shareService!,
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Done'),
                  ),
                ] else ...<Widget>[
                  const SizedBox(height: 16),
                  if (quote != null && companyProfile != null)
                    OutlinedButton(
                      key: const Key('viewPdfButton'),
                      onPressed: () => _openPdfPreview(context, quote),
                      child: const Text('View PDF'),
                    ),
                  if (quote != null && companyProfile != null)
                    const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('confirmInvoiceButton'),
                    onPressed: controller.isSubmitting
                        ? null
                        : () async {
                            final created = await controller.submitInvoice();
                            if (!context.mounted || !created) {
                              return;
                            }
                          },
                    child: controller.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm invoice'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPdfPreview(BuildContext context, InvoiceQuote quote) {
    final profile = companyProfile;
    if (profile == null) {
      return;
    }
    final previewInvoice = buildPreviewInvoiceDetail(
      draft: controller.draft,
      quote: quote,
      company: profile,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InvoicePdfPreviewScreen(invoice: previewInvoice),
      ),
    );
  }

  Widget _buildPaymentModeSection(BuildContext context) {
    final draft = controller.draft;
    final label = invoiceSettlementLabel(
      paymentMode: draft.paymentMode,
      paymentState: draft.paymentState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(key: const Key('paymentModeLabel'), 'Payment: $label'),
        if (draft.paymentMode == settlementModeCredit &&
            draft.paidAmount > 0) ...<Widget>[
          Text(
            key: const Key('amountReceivedLabel'),
            'Received: ${draft.paidAmount.toStringAsFixed(2)}',
          ),
        ],
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, InvoiceQuote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Items', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...List.generate(quote.items.length, (index) {
          final item = quote.items[index];
          return _buildItemRow(context, item, index, gstFlag: quote.gstFlag);
        }),
      ],
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    InvoiceQuoteItem item,
    int index, {
    required bool gstFlag,
  }) {
    final draftItem = controller.draft.items
        .where((di) => di.product?.id == item.productId)
        .firstOrNull;
    final productName = draftItem?.product?.itemName ?? item.productItemName;
    final productItemNumber =
        draftItem?.product?.itemNumber ?? item.productItemNumber;
    final productCategory =
        draftItem?.product?.category ?? item.productCategory;
    final subtitle = gstFlag
        ? '$productItemNumber | $productCategory'
        : productCategory;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                key: Key('lineTotal-$index'),
                item.lineTotal.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle),
          Row(
            children: <Widget>[
              Text(
                  key: Key('quantity-$index'),
                  '${item.unit ?? 'PCS'} x ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'),
              const SizedBox(width: 16),
              Text(
                  key: Key('pricePerUnit-$index'),
                  '@ ${canonicalUnitPriceString(item.enteredUnitPrice)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context, InvoiceQuote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text('Subtotal: ${quote.totals.subtotal.toStringAsFixed(2)}'),
        if (quote.totals.discountTotal > 0)
          Text('Discount: ${quote.totals.discountTotal.toStringAsFixed(2)}'),
        Text('Taxable total: ${quote.totals.taxableTotal.toStringAsFixed(2)}'),
        if (quote.gstFlag)
          Text(
            key: const Key('gstTotal'),
            'GST total: ${quote.totals.gstTotal.toStringAsFixed(2)}',
          ),
        Text(
          key: const Key('grandTotal'),
          'Grand total: ${quote.totals.grandTotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PostCreationShareButtons extends StatelessWidget {
  const _PostCreationShareButtons({
    required this.invoice,
    required this.customerPhone,
    required this.shareService,
  });

  final InvoiceDetail invoice;
  final String? customerPhone;
  final InvoiceShareService shareService;

  @override
  Widget build(BuildContext context) {
    final hasPhone = (customerPhone ?? '').isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton(
          key: const Key('sharePdfButton'),
          onPressed: () => _sharePdfWithCaption(context),
          child: const Text('Share PDF (WhatsApp and more)'),
        ),
        if (hasPhone) ...<Widget>[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('sendSmsButton'),
            onPressed: () => _sendSms(context),
            child: const Text('Send SMS'),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _sharePdfWithCaption(BuildContext context) async {
    try {
      final pdfService = InvoicePdfService.production();
      final path = await pdfService.generateInvoicePdf(invoice);
      await shareService.shareInvoicePdf(
        path,
        text: formatInvoiceShareCaption(invoice),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _sendSms(BuildContext context) async {
    try {
      await shareService.shareViaSms(customerPhone ?? '');
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
