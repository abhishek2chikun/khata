import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/seller.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.paymentsService,
    required this.seller,
    this.onSubmitted,
  });

  final PaymentsService paymentsService;
  final Seller seller;
  final VoidCallback? onSubmitted;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _amountController = TextEditingController();
  final _occurredOnController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
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
      appBar: AppBar(title: const Text('Record payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.seller.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildField(
              key: const Key('paymentAmountField'),
              controller: _amountController,
              label: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildField(
              key: const Key('paymentOccurredOnField'),
              controller: _occurredOnController,
              label: 'Occurred on',
            ),
            _buildField(
              key: const Key('paymentNotesField'),
              controller: _notesController,
              label: 'Notes',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitPaymentButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save payment'),
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
      await widget.paymentsService.recordPayment(
        RecordPaymentInput(
          requestId: generateRequestId(),
          sellerId: widget.seller.id,
          amount: amount,
          occurredOn: occurredOn,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      widget.onSubmitted?.call();
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
