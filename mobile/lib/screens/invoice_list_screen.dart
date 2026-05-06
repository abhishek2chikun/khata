import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/invoice_summary.dart';
import '../services/invoices_service.dart';
import '../services/products_service.dart';
import '../services/sellers_service.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/error_banner.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    super.key,
    required this.invoicesService,
    required this.productsService,
    required this.sellersService,
    required this.drawer,
  });

  final InvoicesService invoicesService;
  final ProductsService productsService;
  final SellersService sellersService;
  final Widget drawer;

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
      return const Center(child: Text('No invoices found'));
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
            title: Text('Invoice #${invoice.invoiceNumber}'),
            subtitle: Text(
              '${invoice.sellerName} • ${invoice.invoiceDate} • ${invoice.paymentMode}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(invoice.grandTotal.toStringAsFixed(2)),
                Text(invoice.status),
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

  Future<void> _openCreateInvoice() async {
    final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CreateInvoiceScreen(
              invoicesService: widget.invoicesService,
              productsService: widget.productsService,
              sellersService: widget.sellersService,
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
