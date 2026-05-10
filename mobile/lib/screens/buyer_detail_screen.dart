import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/buyer.dart';
import '../models/buyer_ledger.dart';
import '../services/buyers_service.dart';
import '../services/money_validator.dart';
import '../widgets/error_banner.dart';
import 'buyer_form_screen.dart';

class BuyerDetailScreen extends StatefulWidget {
  const BuyerDetailScreen({
    super.key,
    required this.buyerId,
    required this.buyersService,
  });

  final String buyerId;
  final BuyersService buyersService;

  @override
  State<BuyerDetailScreen> createState() => _BuyerDetailScreenState();
}

class _BuyerDetailScreenState extends State<BuyerDetailScreen> {
  BuyerLedger? _ledger;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuyer();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final buyer = ledger?.buyer;

    return Scaffold(
      appBar: AppBar(
        title: Text(buyer?.name ?? 'Buyer detail'),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _loadBuyer,
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
                  if (buyer != null) ...<Widget>[
                    Text(
                      buyer.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(buyer.address),
                    if (buyer.phone != null && buyer.phone!.isNotEmpty)
                      Text('Phone: ${buyer.phone}'),
                    if (buyer.gstin != null && buyer.gstin!.isNotEmpty)
                      Text('GSTIN: ${buyer.gstin}'),
                    if (buyer.state != null && buyer.state!.isNotEmpty)
                      Text('State: ${buyer.state} (${buyer.stateCode ?? ''})'),
                    const SizedBox(height: 12),
                    Text(
                      'Pending Payable: ${buyer.pendingPayable.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('editBuyerButton'),
                      onPressed: _isLoading ? null : _handleEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit buyer'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          key: const Key('purchaseAmountActionButton'),
                          onPressed: () => _openEntryForm(
                            buyer: buyer,
                            title: 'Purchase Amount',
                            submit: (input) => widget.buyersService
                                .addPurchaseAmount(
                                    buyerId: buyer.id, input: input),
                          ),
                          child: const Text('Purchase Amount'),
                        ),
                        FilledButton.tonal(
                          key: const Key('paymentMadeActionButton'),
                          onPressed: () => _openEntryForm(
                            buyer: buyer,
                            title: 'Payment Made',
                            submit: (input) => widget.buyersService
                                .addPaymentMade(
                                    buyerId: buyer.id, input: input),
                          ),
                          child: const Text('Payment Made'),
                        ),
                        FilledButton.tonal(
                          key: const Key('openingPayableActionButton'),
                          onPressed: () => _openEntryForm(
                            buyer: buyer,
                            title: 'Opening Payable',
                            submit: (input) => widget.buyersService
                                .addOpeningPayable(
                                    buyerId: buyer.id, input: input),
                          ),
                          child: const Text('Opening Payable'),
                        ),
                        OutlinedButton(
                          key: const Key('payableAdjustmentActionButton'),
                          onPressed: () => _openAdjustmentForm(buyer),
                          child: const Text('Payable Adjustment'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Ledger rows',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (ledger!.transactions.isEmpty)
                      const Text('No ledger rows yet')
                    else
                      ...ledger.transactions.map(_buildTransactionTile),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionTile(BuyerLedgerTransaction transaction) {
    return Card(
      child: ListTile(
        title: Text(transaction.entryType),
        subtitle: Text(transaction.notes ?? transaction.occurredAt),
        trailing: Text(transaction.amount),
      ),
    );
  }

  Future<void> _loadBuyer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ledger =
          await widget.buyersService.fetchBuyerLedger(widget.buyerId);
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

  Future<void> _handleEdit() async {
    final buyer = _ledger?.buyer;
    if (buyer == null) return;
    final result = await Navigator.of(context).push<Buyer>(
      MaterialPageRoute<Buyer>(
        builder: (_) => BuyerFormScreen(
          buyersService: widget.buyersService,
          buyer: buyer,
        ),
      ),
    );
    if (result != null && mounted) {
      await _loadBuyer();
    }
  }

  Future<void> _openEntryForm({
    required Buyer buyer,
    required String title,
    required Future<void> Function(BuyerLedgerEntryInput input) submit,
  }) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => _BuyerLedgerEntryScreen(
              buyer: buyer,
              title: title,
              submit: submit,
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadBuyer();
    }
  }

  Future<void> _openAdjustmentForm(Buyer buyer) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => _BuyerLedgerEntryScreen(
              buyer: buyer,
              title: 'Payable Adjustment',
              showDirection: true,
              submitAdjustment: (input) => widget.buyersService
                  .addPayableAdjustment(buyerId: buyer.id, input: input),
            ),
          ),
        ) ??
        false;
    if (shouldRefresh && mounted) {
      await _loadBuyer();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load buyer detail';
  }
}

class _BuyerLedgerEntryScreen extends StatefulWidget {
  const _BuyerLedgerEntryScreen({
    required this.buyer,
    required this.title,
    this.showDirection = false,
    this.submit,
    this.submitAdjustment,
  });

  final Buyer buyer;
  final String title;
  final bool showDirection;
  final Future<void> Function(BuyerLedgerEntryInput input)? submit;
  final Future<void> Function(BuyerPayableAdjustmentInput input)?
      submitAdjustment;

  @override
  State<_BuyerLedgerEntryScreen> createState() =>
      _BuyerLedgerEntryScreenState();
}

class _BuyerLedgerEntryScreenState extends State<_BuyerLedgerEntryScreen> {
  final _amountController = TextEditingController();
  final _occurredAtController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String _direction = 'INCREASE';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _occurredAtController.text = DateTime.now().toUtc().toIso8601String();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _occurredAtController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.buyer.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            if (widget.showDirection) ...<Widget>[
              DropdownButtonFormField<String>(
                key: const Key('buyerLedgerDirectionField'),
                value: _direction,
                decoration: const InputDecoration(
                  labelText: 'Direction',
                  border: OutlineInputBorder(),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'INCREASE', child: Text('Increase')),
                  DropdownMenuItem(value: 'DECREASE', child: Text('Decrease')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _direction = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
            ],
            _buildField(
              key: const Key('buyerLedgerAmountField'),
              controller: _amountController,
              label: widget.title,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildField(
              key: const Key('buyerLedgerOccurredAtField'),
              controller: _occurredAtController,
              label: 'Date / time',
            ),
            _buildField(
              key: const Key('buyerLedgerNotesField'),
              controller: _notesController,
              label: 'Notes',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitBuyerLedgerEntryButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_isSaving,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = _amountController.text.trim();
    final occurredAt = _occurredAtController.text.trim();
    try {
      validateMoneyAmount(amount);
    } on ApiError catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
      return;
    }
    if (occurredAt.isEmpty) {
      setState(() {
        _errorMessage = 'Date / time is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      if (widget.showDirection) {
        await widget.submitAdjustment!(
          BuyerPayableAdjustmentInput(
            requestId: generateBuyerRequestId(),
            direction: _direction,
            amount: amount,
            occurredAt: occurredAt,
            notes: notes,
          ),
        );
      } else {
        await widget.submit!(
          BuyerLedgerEntryInput(
            requestId: generateBuyerRequestId(),
            amount: amount,
            occurredAt: occurredAt,
            notes: notes,
          ),
        );
      }
      if (!mounted) {
        return;
      }
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
          _isSaving = false;
        });
      }
    }
  }
}
