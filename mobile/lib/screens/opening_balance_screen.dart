import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/seller.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';

class OpeningBalanceScreen extends StatefulWidget {
  const OpeningBalanceScreen({
    super.key,
    required this.paymentsService,
    required this.seller,
  });

  final PaymentsService paymentsService;
  final Seller seller;

  @override
  State<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends State<OpeningBalanceScreen> {
  final _amountController = TextEditingController();
  final _occurredOnController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _occurredOnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add opening balance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildField(
              key: const Key('openingBalanceAmountField'),
              controller: _amountController,
              label: 'Amount',
            ),
            _buildField(
              key: const Key('openingBalanceOccurredOnField'),
              controller: _occurredOnController,
              label: 'Occurred on',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitOpeningBalanceButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save opening balance'),
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
      await widget.paymentsService.addOpeningBalance(
        sellerId: widget.seller.id,
        input: OpeningBalanceInput(
          requestId: generateRequestId(),
          amount: amount,
          occurredOn: occurredOn,
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
