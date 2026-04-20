import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/seller.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';

class BalanceAdjustmentScreen extends StatefulWidget {
  const BalanceAdjustmentScreen({
    super.key,
    required this.paymentsService,
    required this.seller,
  });

  final PaymentsService paymentsService;
  final Seller seller;

  @override
  State<BalanceAdjustmentScreen> createState() => _BalanceAdjustmentScreenState();
}

class _BalanceAdjustmentScreenState extends State<BalanceAdjustmentScreen> {
  final _amountController = TextEditingController();
  final _occurredOnController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String _direction = 'INCREASE';
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _occurredOnController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balance adjustment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              key: const Key('balanceAdjustmentDirectionField'),
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
            _buildField(
              key: const Key('balanceAdjustmentAmountField'),
              controller: _amountController,
              label: 'Amount',
            ),
            _buildField(
              key: const Key('balanceAdjustmentOccurredOnField'),
              controller: _occurredOnController,
              label: 'Occurred on',
            ),
            _buildField(
              key: const Key('balanceAdjustmentNotesField'),
              controller: _notesController,
              label: 'Notes',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitBalanceAdjustmentButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save adjustment'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = _parseAmount();
    final occurredOn = _occurredOnController.text.trim();
    if (amount == null) {
      setState(() {
        _errorMessage = 'Enter a valid amount';
      });
      return;
    }
    if (occurredOn.isEmpty) {
      setState(() {
        _errorMessage = 'Occurred on is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.paymentsService.addBalanceAdjustment(
        sellerId: widget.seller.id,
        input: BalanceAdjustmentInput(
          requestId: generateRequestId(),
          direction: _direction,
          amount: amount,
          occurredOn: occurredOn,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );
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

  double? _parseAmount() {
    final rawValue = _amountController.text.trim();
    if (rawValue.isEmpty) {
      return null;
    }
    final amount = double.tryParse(rawValue);
    if (amount == null || amount <= 0) {
      return null;
    }
    return amount;
  }
}
