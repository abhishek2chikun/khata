import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_share_service.dart';
import '../services/invoices_service.dart';
import '../widgets/error_banner.dart';

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
                    Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${invoice.customerName}'),
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
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('downloadPdfButton'),
                      onPressed: _isGeneratingPdf ? null : _generatePdf,
                      child: _isGeneratingPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Download PDF'),
                    ),
                    const SizedBox(height: 12),
                    if (widget.shareService != null)
                      OutlinedButton(
                        key: const Key('sharePdfButton'),
                        onPressed:
                            _isGeneratingPdf ? null : _sharePdf,
                        child: _isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Share'),
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

  Future<void> _sharePdf() async {
    final invoice = _invoice;
    if (invoice == null || widget.shareService == null) return;
    final hasPhone = (invoice.customerPhone ?? '').isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Share Invoice',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (hasPhone) ...<Widget>[
                ListTile(
                  key: const Key('shareViaWhatsAppOption'),
                  leading: const Icon(Icons.chat),
                  title: const Text('Share via WhatsApp'),
                  onTap: () => _doShareWhatsApp(invoice),
                ),
                ListTile(
                  key: const Key('shareViaSmsOption'),
                  leading: const Icon(Icons.sms),
                  title: const Text('Share via SMS'),
                  onTap: () => _doShareSms(invoice),
                ),
              ],
              ListTile(
                key: const Key('shareViaSystemOption'),
                leading: const Icon(Icons.share),
                title: const Text('Share...'),
                onTap: () => _doShareSystem(invoice),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doShareWhatsApp(InvoiceDetail invoice) async {
    Navigator.of(context).pop();
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });
    try {
      final path = await _ensurePdf();
      await widget.shareService!.shareViaWhatsApp(
        path,
        invoice.customerPhone ?? '',
        whatsappNumber: invoice.customerWhatsappNumber,
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

  Future<void> _doShareSms(InvoiceDetail invoice) async {
    Navigator.of(context).pop();
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });
    try {
      final path = await _ensurePdf();
      await widget.shareService!.shareViaSms(
        path,
        invoice.customerPhone ?? '',
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

  Future<void> _doShareSystem(InvoiceDetail invoice) async {
    Navigator.of(context).pop();
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });
    try {
      final path = await _ensurePdf();
      await widget.shareService!.shareInvoicePdf(path);
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
