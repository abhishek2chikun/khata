import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/customer.dart';
import '../services/customers_service.dart';
import '../widgets/error_banner.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    super.key,
    required this.customersService,
    this.customer,
  });

  final CustomersService customersService;
  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _gstinController;
  late final TextEditingController _stateController;
  late final TextEditingController _stateCodeController;

  bool _isSaving = false;
  bool _whatsappSameAsPhone = false;
  String? _errorMessage;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _whatsappController =
        TextEditingController(text: customer?.whatsappNumber ?? '');
    _gstinController = TextEditingController(text: customer?.gstin ?? '');
    _stateController = TextEditingController(text: customer?.state ?? '');
    _stateCodeController =
        TextEditingController(text: customer?.stateCode ?? '');

    if (customer != null &&
        customer.whatsappNumber != null &&
        customer.whatsappNumber == customer.phone) {
      _whatsappSameAsPhone = true;
    }

    _phoneController.addListener(_syncWhatsappIfSame);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_syncWhatsappIfSame);
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _gstinController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    super.dispose();
  }

  void _syncWhatsappIfSame() {
    if (_whatsappSameAsPhone) {
      _whatsappController.text = _phoneController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? 'Edit customer' : 'Add customer')),
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
              key: const Key('customerNameField'),
              controller: _nameController,
              label: 'Name',
            ),
            _buildField(
              key: const Key('customerAddressField'),
              controller: _addressController,
              label: 'Address',
            ),
            _buildField(
              key: const Key('customerPhoneField'),
              controller: _phoneController,
              label: 'Phone',
            ),
            SwitchListTile(
              key: const Key('whatsappSameAsPhoneToggle'),
              title: const Text('WhatsApp same as phone'),
              value: _whatsappSameAsPhone,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _whatsappSameAsPhone = value;
                        if (value) {
                          _whatsappController.text = _phoneController.text;
                        }
                      });
                    },
            ),
            _buildField(
              key: const Key('customerWhatsappField'),
              controller: _whatsappController,
              label: 'WhatsApp number',
              enabled: !_whatsappSameAsPhone,
            ),
            _buildField(
              key: const Key('customerGstinField'),
              controller: _gstinController,
              label: 'GSTIN',
            ),
            _buildField(
              key: const Key('customerStateField'),
              controller: _stateController,
              label: 'State',
            ),
            _buildField(
              key: const Key('customerStateCodeField'),
              controller: _stateCodeController,
              label: 'State code',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitCustomerButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save customer'),
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
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        enabled: enabled && !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Name is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final Customer customer;
      if (_isEditing) {
        customer = await widget.customersService.updateCustomer(
          id: widget.customer!.id,
          input: UpdateCustomerInput(
            name: name,
            address: _addressController.text.trim(),
            phone: _nullableText(_phoneController),
            whatsappNumber: _whatsappSameAsPhone
                ? _nullableText(_phoneController)
                : _nullableText(_whatsappController),
            gstin: _nullableText(_gstinController),
            state: _nullableText(_stateController),
            stateCode: _nullableText(_stateCodeController),
          ),
        );
      } else {
        customer = await widget.customersService.createCustomer(
          CreateCustomerInput(
            name: name,
            address: _addressController.text.trim(),
            phone: _nullableText(_phoneController),
            whatsappNumber: _whatsappSameAsPhone
                ? _nullableText(_phoneController)
                : _nullableText(_whatsappController),
            gstin: _nullableText(_gstinController),
            state: _nullableText(_stateController),
            stateCode: _nullableText(_stateCodeController),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<Customer>(customer);
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

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}
