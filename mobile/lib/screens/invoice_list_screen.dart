import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/invoice_summary.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_share_service.dart';
import '../services/invoice_settlement.dart';
import '../services/invoices_service.dart';
import '../services/products_service.dart';
import '../services/customers_service.dart';
import '../services/company_profile_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    super.key,
    required this.invoicesService,
    required this.productsService,
    required this.customersService,
    required this.drawer,
    this.companyProfileService,
    this.shareService,
  });

  final InvoicesService invoicesService;
  final ProductsService productsService;
  final CustomersService customersService;
  final CompanyProfileService? companyProfileService;
  final Widget drawer;
  final InvoiceShareService? shareService;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<InvoiceSummary> _invoices = const <InvoiceSummary>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newInvoiceButton'),
        onPressed: _openCreateInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'ALL', label: Text('All')),
                ButtonSegment<String>(value: 'ACTIVE', label: Text('Active')),
                ButtonSegment<String>(
                    value: 'CANCELED', label: Text('Canceled')),
              ],
              selected: <String>{_statusFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  _statusFilter = selection.first;
                });
                _loadInvoices();
              },
            ),
            const SizedBox(height: 16),
            if (!_isLoading)
              Text(
                '${_invoices.length} ${_invoices.length == 1 ? 'invoice' : 'invoices'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            if (!_isLoading) const SizedBox(height: 10),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_invoices.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No invoices found',
        message: 'Create an invoice or choose another status filter.',
      );
    }
    return ListView.separated(
      itemCount: _invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Card(
          child: ListTile(
            key: Key('invoiceTile-${invoice.id}'),
            onTap: () => _openInvoice(invoice),
            leading: CircleAvatar(
              child: Icon(
                invoice.status == 'CANCELED'
                    ? Icons.block_outlined
                    : Icons.receipt_outlined,
              ),
            ),
            title: Text(
              'Invoice #${invoice.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${invoice.customerName} • ${invoice.invoiceDate} • ${invoiceSettlementLabel(
                paymentMode: invoice.paymentMode,
                paymentState: invoice.paymentState,
              )}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.shareService != null)
                  IconButton(
                    key: Key('shareButton-${invoice.id}'),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share PDF',
                    onPressed: () => _sharePdfForInvoice(invoice),
                  )
                else
                  IconButton(
                    key: Key('pdfButton-${invoice.id}'),
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Generate PDF',
                    onPressed: () => _generatePdfForInvoice(invoice),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '₹${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (invoice.status == 'CANCELED')
                      Text(
                        'Canceled',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invoices = await widget.invoicesService.listInvoices(
        status: _statusFilter == 'ALL' ? null : _statusFilter,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _invoices = invoices;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePdfForInvoice(InvoiceSummary summary) async {
    try {
      final invoice =
          await widget.invoicesService.fetchInvoiceDetail(summary.id);
      final service = InvoicePdfService.production();
      final path = await service.generateInvoicePdf(invoice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to $path')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _sharePdfForInvoice(InvoiceSummary summary) async {
    try {
      final invoice =
          await widget.invoicesService.fetchInvoiceDetail(summary.id);
      final pdfService = InvoicePdfService.production();
      final path = await pdfService.generateInvoicePdf(invoice);
      if (!mounted) return;
      await widget.shareService!.shareInvoicePdf(
        path,
        text: formatInvoiceShareCaption(invoice),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _openCreateInvoice() async {
    final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CreateInvoiceScreen(
              invoicesService: widget.invoicesService,
              productsService: widget.productsService,
              customersService: widget.customersService,
              companyProfileService: widget.companyProfileService,
              shareService: widget.shareService,
            ),
          ),
        ) ??
        false;
    if (created && mounted) {
      await _loadInvoices();
    }
  }

  Future<void> _openInvoice(InvoiceSummary invoice) async {
    final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => InvoiceDetailScreen(
              invoiceId: invoice.id,
              invoicesService: widget.invoicesService,
              shareService: widget.shareService,
            ),
          ),
        ) ??
        false;
    if (changed && mounted) {
      await _loadInvoices();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load invoices';
  }
}
