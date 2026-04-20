import 'package:flutter/material.dart';

import '../models/invoice_quote.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({super.key, required this.controller});

  final InvoiceDraftController controller;

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
                  Text('Tax regime: ${quote.taxRegime}'),
                  Text('Place of supply: ${quote.placeOfSupplyState} (${quote.placeOfSupplyStateCode})'),
                  const SizedBox(height: 12),
                  ...quote.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(warning.message),
                    ),
                  ),
                  ...quote.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_labelForQuoteItem(item)),
                      subtitle: Text('Qty ${item.quantity}'),
                      trailing: Text(item.lineTotal.toStringAsFixed(2)),
                    ),
                  ),
                  const Divider(),
                  Text('Subtotal: ${quote.totals.subtotal.toStringAsFixed(2)}'),
                  Text('Discount: ${quote.totals.discountTotal.toStringAsFixed(2)}'),
                  Text('Taxable total: ${quote.totals.taxableTotal.toStringAsFixed(2)}'),
                  Text('GST total: ${quote.totals.gstTotal.toStringAsFixed(2)}'),
                  Text('Grand total: ${quote.totals.grandTotal.toStringAsFixed(2)}'),
                ],
                if (createdInvoice != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text('Invoice created', style: Theme.of(context).textTheme.titleMedium),
                  Text('Invoice #${createdInvoice.invoiceNumber}'),
                  ...controller.createWarnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(warning.message),
                    ),
                  ),
                  const SizedBox(height: 16),
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

  String _labelForQuoteItem(InvoiceQuoteItem item) {
    final draftProduct = controller.draft.items
        .map((draftItem) => draftItem.product)
        .whereType<Object>()
        .cast<dynamic>()
        .firstWhere(
          (product) => product.id == item.productId,
          orElse: () => null,
        );
    if (draftProduct != null) {
      return draftProduct.itemName as String;
    }
    return item.productId.isEmpty ? 'Item' : 'Item ${item.productId}';
  }
}
