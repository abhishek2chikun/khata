import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/customer.dart';
import '../models/customer_ledger.dart';
import '../services/balance_share_service.dart';
import '../services/company_profile_service.dart';
import '../services/payments_service.dart';
import '../services/customers_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';
import 'balance_adjustment_screen.dart';
import 'customer_form_screen.dart';
import 'opening_balance_screen.dart';
import 'record_payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customersService,
    required this.paymentsService,
    required this.onCreateInvoice,
    this.companyProfileService,
    this.balanceShareService,
  });

  final String customerId;
  final CustomersService customersService;
  final PaymentsService paymentsService;
  final Future<bool> Function(Customer customer) onCreateInvoice;
  final CompanyProfileService? companyProfileService;
  final BalanceShareService? balanceShareService;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _ledgerDateController = TextEditingController();
  CustomerLedger? _ledger;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ledgerDateController.text =
        DateTime.now().toIso8601String().substring(0, 10);
    _loadCustomer();
  }

  @override
  void dispose() {
    _ledgerDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final customer = ledger?.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer == null ? 'Customer detail' : 'Customer khata'),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _loadCustomer,
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
                  if (customer != null) ...<Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(customer.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                              'Balance receivable',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              '₹${customer.pendingBalance.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (widget.balanceShareService != null &&
                                widget.companyProfileService !=
                                    null) ...<Widget>[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                key: const Key('shareIndividualBalanceButton'),
                                onPressed: _isLoading
                                    ? null
                                    : () => _previewShareIndividualBalance(
                                          customer,
                                        ),
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Share balance'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            AppInfoRow(
                              label: 'Address',
                              value: customer.address.trim().isEmpty
                                  ? 'Not added'
                                  : customer.address,
                            ),
                            if (customer.phone != null &&
                                customer.phone!.isNotEmpty)
                              AppInfoRow(
                                label: 'Phone',
                                value: customer.phone!,
                              ),
                            if (customer.gstin != null &&
                                customer.gstin!.isNotEmpty)
                              AppInfoRow(
                                label: 'GSTIN',
                                value: customer.gstin!,
                              ),
                            if (customer.state != null &&
                                customer.state!.isNotEmpty)
                              AppInfoRow(
                                label: 'State',
                                value:
                                    '${customer.state} (${customer.stateCode ?? ''})',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          key: const Key('recordCollectionActionButton'),
                          onPressed: () => _openRecordCollection(customer),
                          child: const Text('Collect money'),
                        ),
                        FilledButton.tonal(
                          key: const Key('openingBalanceActionButton'),
                          onPressed: () => _openOpeningBalance(customer),
                          child: const Text('Add opening balance'),
                        ),
                        FilledButton.tonal(
                          key: const Key('balanceAdjustmentActionButton'),
                          onPressed: () =>
                              _openBalanceAdjustment(customer, 'INCREASE'),
                          child: const Text('Increase balance'),
                        ),
                        FilledButton.tonal(
                          key: const Key('decreaseBalanceActionButton'),
                          onPressed: () =>
                              _openBalanceAdjustment(customer, 'DECREASE'),
                          child: const Text('Decrease balance'),
                        ),
                        OutlinedButton(
                          key: const Key('createInvoiceActionButton'),
                          onPressed: customer.isActive
                              ? () => _openCreateInvoice(customer)
                              : null,
                          child: const Text('Create invoice'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('editCustomerButton'),
                          onPressed: _isLoading ? null : _handleEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit customer'),
                        ),
                        if (!customer.isActive)
                          const Text(
                              'Create invoice unavailable for archived customers'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader(
                      title: 'Ledger history',
                      subtitle: 'Collections and balance changes by date.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('ledgerDateFilterField'),
                      controller: _ledgerDateController,
                      enabled: !_isLoading,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Ledger date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _openLedgerDatePicker,
                    ),
                    const SizedBox(height: 12),
                    if (ledger!.transactions.isEmpty)
                      const Text('No ledger transactions yet')
                    else
                      ...ledger.transactions.map(_buildTransactionTile),
                    const SizedBox(height: 24),
                    const AppSectionHeader(title: 'Invoice history'),
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

  Widget _buildTransactionTile(CustomerLedgerTransaction transaction) {
    return Card(
      child: ListTile(
        title: Text(transaction.entryType),
        subtitle: _buildTransactionSubtitle(transaction),
        trailing: Text(transaction.amount.toStringAsFixed(2)),
      ),
    );
  }

  Widget _buildTransactionSubtitle(CustomerLedgerTransaction transaction) {
    final timestamp = _formatCreatedAt(transaction.createdAt);
    final note = transaction.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(timestamp.isEmpty ? transaction.occurredOn : timestamp),
        if (note != null && note.isNotEmpty) Text(note),
      ],
    );
  }

  Widget _buildInvoiceTile(CustomerInvoiceHistoryEntry invoice) {
    return Card(
      child: ListTile(
        title: Text(invoice.invoiceNumber),
        subtitle: Text(
            '${invoice.invoiceDate} • ${invoice.paymentMode} • ${invoice.status}'),
        trailing: Text(invoice.grandTotal.toStringAsFixed(2)),
      ),
    );
  }

  Future<void> _handleEdit() async {
    final customer = _ledger?.customer;
    if (customer == null) return;
    final result = await Navigator.of(context).push<Customer>(
      MaterialPageRoute<Customer>(
        builder: (_) => CustomerFormScreen(
          customersService: widget.customersService,
          customer: customer,
        ),
      ),
    );
    if (result != null && mounted) {
      await _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ledger = await widget.customersService.fetchCustomerLedger(
        widget.customerId,
        onDate: _ledgerDateController.text.trim(),
      );
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

  Future<void> _openLedgerDatePicker() async {
    final currentDate = _parseLedgerDate() ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null || !mounted) {
      return;
    }
    _ledgerDateController.text = _dateString(selectedDate);
    await _loadCustomer();
  }

  DateTime? _parseLedgerDate() {
    final parts = _ledgerDateController.text.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  Future<void> _openRecordCollection(Customer customer) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RecordCollectionScreen(
              paymentsService: widget.paymentsService,
              customer: customer,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadCustomer();
    }
  }

  Future<void> _openOpeningBalance(Customer customer) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OpeningBalanceScreen(
              paymentsService: widget.paymentsService,
              customer: customer,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadCustomer();
    }
  }

  Future<void> _openBalanceAdjustment(
      Customer customer, String direction) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => BalanceAdjustmentScreen(
              paymentsService: widget.paymentsService,
              customer: customer,
              initialDirection: direction,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadCustomer();
    }
  }

  Future<void> _openCreateInvoice(Customer customer) async {
    final shouldRefresh = await widget.onCreateInvoice(customer);
    if (shouldRefresh && mounted) {
      await _loadCustomer();
    }
  }

  Future<void> _previewShareIndividualBalance(Customer customer) async {
    final profileService = widget.companyProfileService;
    final shareService = widget.balanceShareService;
    if (profileService == null || shareService == null) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final profile = await profileService.fetchCompanyProfile();
      if (!mounted) {
        return;
      }
      final asOfDate = _dateString(DateTime.now());
      final message = formatIndividualBalanceShareMessage(
        sellerName: profile.name,
        customerName: customer.name,
        pendingBalance: customer.pendingBalance,
        asOfDate: asOfDate,
      );
      await _previewAndShareBalance(message, shareService);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
      });
    }
  }

  Future<void> _previewAndShareBalance(
    String message,
    BalanceShareService shareService,
  ) async {
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share balance'),
        content: SingleChildScrollView(child: Text(message)),
        actions: <Widget>[
          TextButton(
            key: const Key('cancelBalanceShareButton'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmBalanceShareButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (shouldShare == true) {
      await shareService.shareText(message);
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load customer detail';
  }

  String _formatCreatedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '';
    }
    final local = parsed.toLocal();
    return '${_dateString(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _dateString(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
