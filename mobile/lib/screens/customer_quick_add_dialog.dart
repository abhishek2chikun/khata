import 'package:flutter/material.dart';

import '../services/customers_service.dart';

class CustomerQuickAddDialog extends StatefulWidget {
  const CustomerQuickAddDialog({
    super.key,
    required this.customersService,
  });

  final CustomersService customersService;

  @override
  State<CustomerQuickAddDialog> createState() => _CustomerQuickAddDialogState();
}

class _CustomerQuickAddDialogState extends State<CustomerQuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_errorMessage != null) ...<Widget>[
                Text(_errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('customerNameField'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('customerAddressField'),
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveCustomerButton'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final customer = await widget.customersService.createCustomer(
        CreateCustomerInput(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(customer);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to create customer';
        _isSaving = false;
      });
    }
  }
}
