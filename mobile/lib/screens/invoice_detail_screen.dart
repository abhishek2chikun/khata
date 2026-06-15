import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../services/invoice_settlement.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_share_service.dart';
import '../services/invoices_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.invoicesService,
    this.shareService,
  });

  final String invoiceId;
  final InvoicesService invoicesService;
  final InvoiceShareService? shareService;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceDetail? _invoice;
  bool _isLoading = true;
  bool _isCanceling = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  String? _generatedPdfPath;

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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            AppSectionHeader(
                              title: 'Invoice #${invoice.invoiceNumber}',
                              trailing: invoice.status == 'CANCELED'
                                  ? Chip(
                                      label: const Text('Canceled'),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            AppInfoRow(
                              label: 'Customer',
                              value: invoice.customerName,
                            ),
                            AppInfoRow(
                              label: 'Date',
                              value: invoice.invoiceDate,
                            ),
                            AppInfoRow(
                              label: 'Payment: ${invoiceSettlementLabel(
                                paymentMode: invoice.paymentMode,
                                paymentState: invoice.paymentState,
                              )}',
                              value: '',
                            ),
                            AppInfoRow(
                              label: 'Grand total',
                              value:
                                  '₹${invoice.grandTotal.toStringAsFixed(2)}',
                              emphasized: true,
                            ),
                            if ((invoice.notes ?? '').isNotEmpty)
                              AppInfoRow(label: 'Notes', value: invoice.notes!),
                            if ((invoice.cancelReason ?? '').isNotEmpty)
                              AppInfoRow(
                                label: 'Cancel reason',
                                value: invoice.cancelReason!,
                              ),
                          ],
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('downloadPdfButton'),
                      onPressed: _isGeneratingPdf ? null : _generatePdf,
                      child: _isGeneratingPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Download PDF'),
                    ),
                    const SizedBox(height: 12),
                    if (widget.shareService != null) ...<Widget>[
                      OutlinedButton(
                        key: const Key('sharePdfButton'),
                        onPressed:
                            _isGeneratingPdf ? null : _sharePdfWithCaption,
                        child: _isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Share PDF (WhatsApp and more)'),
                      ),
                      if ((invoice.customerPhone ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const Key('sendSmsButton'),
                          onPressed: _isGeneratingPdf ? null : _sendSms,
                          child: const Text('Send SMS'),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const AppSectionHeader(title: 'Items'),
                    const SizedBox(height: 12),
                    ...invoice.items.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                              'Qty ${formatInvoiceQuantity(item.quantity)}'),
                          trailing: Text(
                            '₹${item.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
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

  Future<String> _ensurePdf() async {
    if (_generatedPdfPath != null) {
      return _generatedPdfPath!;
    }
    if (_invoice == null) throw StateError('Invoice not loaded');
    final service = InvoicePdfService.production();
    final path = await service.generateInvoicePdf(_invoice!);
    _generatedPdfPath = path;
    return path;
  }

  Future<void> _generatePdf() async {
    if (_invoice == null) return;
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });
    try {
      final path = await _ensurePdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $path')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _sharePdfWithCaption() async {
    final invoice = _invoice;
    if (invoice == null || widget.shareService == null) return;
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });
    try {
      final path = await _ensurePdf();
      final caption = formatInvoiceShareCaption(invoice);
      await widget.shareService!.shareInvoicePdf(path, text: caption);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _sendSms() async {
    final invoice = _invoice;
    if (invoice == null || widget.shareService == null) return;
    final phone = invoice.customerPhone ?? '';
    if (phone.isEmpty) return;
    setState(() {
      _errorMessage = null;
    });
    try {
      await widget.shareService!.shareViaSms(phone);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
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
