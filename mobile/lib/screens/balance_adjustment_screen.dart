import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/customer.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';

class BalanceAdjustmentScreen extends StatefulWidget {
  const BalanceAdjustmentScreen({
    super.key,
    required this.paymentsService,
    required this.customer,
    this.initialDirection = 'INCREASE',
  });

  final PaymentsService paymentsService;
  final Customer customer;
  final String initialDirection;

  @override
  State<BalanceAdjustmentScreen> createState() =>
      _BalanceAdjustmentScreenState();
}

class _BalanceAdjustmentScreenState extends State<BalanceAdjustmentScreen> {
  final _amountController = TextEditingController();
  final _occurredOnController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  late String _direction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _occurredOnController.text =
        DateTime.now().toIso8601String().substring(0, 10);
  }

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
            AppFormSection(
              title: widget.customer.name,
              subtitle: 'Correct the balance without creating an invoice.',
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('balanceAdjustmentDirectionField'),
                  initialValue: _direction,
                  decoration: const InputDecoration(labelText: 'Direction'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                        value: 'INCREASE', child: Text('Increase')),
                    DropdownMenuItem(
                        value: 'DECREASE', child: Text('Decrease')),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _direction = value);
                        },
                ),
                const SizedBox(height: 12),
                _buildField(
                  key: const Key('balanceAdjustmentAmountField'),
                  controller: _amountController,
                  label: 'Amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '₹ ',
                ),
                _buildField(
                  key: const Key('balanceAdjustmentOccurredOnField'),
                  controller: _occurredOnController,
                  label: 'Occurred on',
                  suffixIcon: Icons.calendar_today_outlined,
                  onSuffixTap: _pickDate,
                ),
                _buildField(
                  key: const Key('balanceAdjustmentNotesField'),
                  controller: _notesController,
                  label: 'Reason / notes',
                  maxLines: 3,
                ),
              ],
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
    TextInputType? keyboardType,
    String? prefixText,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_isSaving,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
      await widget.paymentsService.addBalanceAdjustment(
        customerId: widget.customer.id,
        input: BalanceAdjustmentInput(
          requestId: generateRequestId(),
          direction: _direction,
          amount: amount,
          occurredOn: occurredOn,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
