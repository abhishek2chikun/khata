import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/customer.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';

class OpeningBalanceScreen extends StatefulWidget {
  const OpeningBalanceScreen({
    super.key,
    required this.paymentsService,
    required this.customer,
  });

  final PaymentsService paymentsService;
  final Customer customer;

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
  void initState() {
    super.initState();
    _occurredOnController.text =
        DateTime.now().toIso8601String().substring(0, 10);
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
            AppFormSection(
              title: widget.customer.name,
              subtitle: 'Record the balance carried into Khata.',
              children: [
                _buildField(
                  key: const Key('openingBalanceAmountField'),
                  controller: _amountController,
                  label: 'Amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '₹ ',
                ),
                _buildField(
                  key: const Key('openingBalanceOccurredOnField'),
                  controller: _occurredOnController,
                  label: 'Occurred on',
                  suffixIcon: Icons.calendar_today_outlined,
                  onSuffixTap: _pickDate,
                ),
              ],
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
    TextInputType? keyboardType,
    String? prefixText,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
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
          prefixText: prefixText,
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon),
                ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_occurredOnController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      _occurredOnController.text = selected.toIso8601String().substring(0, 10);
    }
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
        customerId: widget.customer.id,
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
