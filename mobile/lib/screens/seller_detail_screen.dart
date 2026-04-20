import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/seller.dart';
import '../models/seller_ledger.dart';
import '../services/payments_service.dart';
import '../services/sellers_service.dart';
import '../widgets/error_banner.dart';
import 'balance_adjustment_screen.dart';
import 'opening_balance_screen.dart';
import 'record_payment_screen.dart';

class SellerDetailScreen extends StatefulWidget {
  const SellerDetailScreen({
    super.key,
    required this.sellerId,
    required this.sellersService,
    required this.paymentsService,
    required this.onCreateInvoice,
  });

  final String sellerId;
  final SellersService sellersService;
  final PaymentsService paymentsService;
  final Future<bool> Function(Seller seller) onCreateInvoice;

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen> {
  SellerLedger? _ledger;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final seller = ledger?.seller;

    return Scaffold(
      appBar: AppBar(
        title: Text(seller?.name ?? 'Seller detail'),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _loadSeller,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
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
                  if (seller != null) ...<Widget>[
                    Text(seller.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(seller.address),
                    if (seller.phone != null && seller.phone!.isNotEmpty) Text('Phone: ${seller.phone}'),
                    if (seller.gstin != null && seller.gstin!.isNotEmpty) Text('GSTIN: ${seller.gstin}'),
                    if (seller.state != null && seller.state!.isNotEmpty)
                      Text('State: ${seller.state} (${seller.stateCode ?? ''})'),
                    const SizedBox(height: 12),
                    Text(
                      'Pending balance: ${seller.pendingBalance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          key: const Key('recordPaymentActionButton'),
                          onPressed: () => _openRecordPayment(seller),
                          child: const Text('Record payment'),
                        ),
                        FilledButton.tonal(
                          key: const Key('openingBalanceActionButton'),
                          onPressed: () => _openOpeningBalance(seller),
                          child: const Text('Add opening balance'),
                        ),
                        FilledButton.tonal(
                          key: const Key('balanceAdjustmentActionButton'),
                          onPressed: () => _openBalanceAdjustment(seller),
                          child: const Text('Balance adjustment'),
                        ),
                        OutlinedButton(
                          key: const Key('createInvoiceActionButton'),
                          onPressed: seller.isActive ? () => _openCreateInvoice(seller) : null,
                          child: const Text('Create invoice'),
                        ),
                        if (!seller.isActive)
                          const Text('Create invoice unavailable for archived sellers'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Ledger timeline', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (ledger!.transactions.isEmpty)
                      const Text('No ledger transactions yet')
                    else
                      ...ledger.transactions.map(_buildTransactionTile),
                    const SizedBox(height: 24),
                    Text('Invoice history', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (ledger.invoices.isEmpty)
                      const Text('No invoices yet')
                    else
                      ...ledger.invoices.map(_buildInvoiceTile),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionTile(SellerLedgerTransaction transaction) {
    return Card(
      child: ListTile(
        title: Text(transaction.entryType),
        subtitle: Text(transaction.notes ?? transaction.occurredOn),
        trailing: Text(transaction.amount.toStringAsFixed(2)),
      ),
    );
  }

  Widget _buildInvoiceTile(SellerInvoiceHistoryEntry invoice) {
    return Card(
      child: ListTile(
        title: Text(invoice.invoiceNumber),
        subtitle: Text('${invoice.invoiceDate} • ${invoice.paymentMode} • ${invoice.status}'),
        trailing: Text(invoice.grandTotal.toStringAsFixed(2)),
      ),
    );
  }

  Future<void> _loadSeller() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ledger = await widget.sellersService.fetchSellerLedger(widget.sellerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _ledger = ledger;
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

  Future<void> _openRecordPayment(Seller seller) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RecordPaymentScreen(
              paymentsService: widget.paymentsService,
              seller: seller,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadSeller();
    }
  }

  Future<void> _openOpeningBalance(Seller seller) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OpeningBalanceScreen(
              paymentsService: widget.paymentsService,
              seller: seller,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadSeller();
    }
  }

  Future<void> _openBalanceAdjustment(Seller seller) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => BalanceAdjustmentScreen(
              paymentsService: widget.paymentsService,
              seller: seller,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadSeller();
    }
  }

  Future<void> _openCreateInvoice(Seller seller) async {
    final shouldRefresh = await widget.onCreateInvoice(seller);
    if (shouldRefresh && mounted) {
      await _loadSeller();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load seller detail';
  }
}
