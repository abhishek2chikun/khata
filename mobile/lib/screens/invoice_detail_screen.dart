import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../services/invoices_service.dart';
import '../widgets/error_banner.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.invoicesService,
  });

  final String invoiceId;
  final InvoicesService invoicesService;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceDetail? _invoice;
  bool _isLoading = true;
  bool _isCanceling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice detail')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_errorMessage != null) ...<Widget>[
                    ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (invoice != null) ...<Widget>[
                    Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Seller: ${invoice.sellerName}'),
                    Text('Date: ${invoice.invoiceDate}'),
                    Text('Status: ${invoice.status}'),
                    Text('Payment mode: ${invoice.paymentMode}'),
                    Text(
                        'Grand total: ${invoice.grandTotal.toStringAsFixed(2)}'),
                    if ((invoice.notes ?? '').isNotEmpty)
                      Text('Notes: ${invoice.notes}'),
                    if ((invoice.cancelReason ?? '').isNotEmpty)
                      Text('Cancel reason: ${invoice.cancelReason}'),
                    const SizedBox(height: 16),
                    if (invoice.status == 'ACTIVE')
                      FilledButton.tonal(
                        key: const Key('cancelInvoiceButton'),
                        onPressed: _isCanceling ? null : _promptCancel,
                        child: _isCanceling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Cancel invoice'),
                      ),
                    const SizedBox(height: 24),
                    Text('Items',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...invoice.items.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle:
                              Text('Qty ${item.quantity.toStringAsFixed(3)}'),
                          trailing: Text(item.lineTotal.toStringAsFixed(2)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invoice =
          await widget.invoicesService.fetchInvoiceDetail(widget.invoiceId);
      if (!mounted) {
        return;
      }
      setState(() {
        _invoice = invoice;
      });
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _promptCancel() async {
    final reasonController = TextEditingController();
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel invoice'),
            content: TextField(
              key: const Key('cancelInvoiceReasonField'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancel reason',
                border: OutlineInputBorder(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Back'),
              ),
              FilledButton(
                key: const Key('confirmCancelInvoiceButton'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel invoice'),
              ),
            ],
          ),
        ) ??
        false;
    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (!shouldCancel || reason.isEmpty) {
      return;
    }

    setState(() {
      _isCanceling = true;
      _errorMessage = null;
    });

    try {
      final invoice = await widget.invoicesService.cancelInvoice(
        invoiceId: widget.invoiceId,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _invoice = invoice;
      });
      Navigator.of(context).pop(true);
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCanceling = false;
        });
      }
    }
  }
}
