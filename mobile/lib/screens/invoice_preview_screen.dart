import 'package:flutter/material.dart';

import '../models/invoice_detail.dart';
import '../models/invoice_quote.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_share_service.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.controller,
    this.shareService,
  });

  final InvoiceDraftController controller;
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
                  Text('Customer: ${controller.draft.customer?.name ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    quote.gstFlag ? 'GST invoice' : 'Non-GST invoice',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('Date: ${controller.draft.invoiceDate}'),
                  if (quote.gstFlag) ...<Widget>[
                    Text('Tax regime: ${quote.taxRegime}'),
                    Text(
                        'Place of supply: ${quote.placeOfSupplyState} (${quote.placeOfSupplyStateCode})'),
                  ],
                  const SizedBox(height: 8),
                  _buildPaymentStateSection(context),
                  const SizedBox(height: 12),
                  ...quote.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(warning.message),
                    ),
                  ),
                  const Divider(),
                  _buildItemsTable(context, quote),
                  const Divider(),
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

  Widget _buildPaymentStateSection(BuildContext context) {
    final state = controller.draft.paymentState;
    final paidAmount = controller.draft.paidAmount;
    final label = _paymentStateLabel(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(key: const Key('paymentStateLabel'), 'Payment: $label'),
        if (state != 'CREDIT')
          Text(
            key: const Key('paidAmountLabel'),
            'Paid: ${paidAmount.toStringAsFixed(2)}',
          ),
      ],
    );
  }

  String _paymentStateLabel(String state) {
    switch (state) {
      case 'TOTAL_PAID':
        return 'Total Paid';
      case 'PARTIAL_PAID':
        return 'Partial Paid';
      default:
        return 'Credit';
    }
  }

  Widget _buildItemsTable(BuildContext context, InvoiceQuote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Items', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...List.generate(quote.items.length, (index) {
          final item = quote.items[index];
          return _buildItemRow(context, item, index);
        }),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, InvoiceQuoteItem item, int index) {
    final draftItem = controller.draft.items
        .where((di) => di.product?.id == item.productId)
        .firstOrNull;
    final productName = draftItem?.product?.itemName ?? item.productItemName;
    final productItemNumber =
        draftItem?.product?.itemNumber ?? item.productItemNumber;
    final productCategory =
        draftItem?.product?.category ?? item.productCategory;

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
          Text('$productItemNumber | $productCategory'),
          Row(
            children: <Widget>[
              Text(
                  key: Key('quantity-$index'),
                  '${item.unit ?? 'PCS'} x ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'),
              const SizedBox(width: 16),
              Text(
                  key: Key('pricePerUnit-$index'),
                  '@ ${item.enteredUnitPrice.toStringAsFixed(2)}'),
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
