import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/buyer.dart';
import '../services/buyers_service.dart';
import '../widgets/error_banner.dart';

class BuyerFormScreen extends StatefulWidget {
  const BuyerFormScreen({
    super.key,
    required this.buyersService,
  });

  final BuyersService buyersService;

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _stateController = TextEditingController();
  final _stateCodeController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add buyer')),
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
              key: const Key('buyerNameField'),
              controller: _nameController,
              label: 'Name',
            ),
            _buildField(
              key: const Key('buyerAddressField'),
              controller: _addressController,
              label: 'Address',
            ),
            _buildField(
              key: const Key('buyerPhoneField'),
              controller: _phoneController,
              label: 'Phone',
            ),
            _buildField(
              key: const Key('buyerGstinField'),
              controller: _gstinController,
              label: 'GSTIN',
            ),
            _buildField(
              key: const Key('buyerStateField'),
              controller: _stateController,
              label: 'State',
            ),
            _buildField(
              key: const Key('buyerStateCodeField'),
              controller: _stateCodeController,
              label: 'State code',
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('submitBuyerButton'),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save buyer'),
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
      final buyer = await widget.buyersService.createBuyer(
        CreateBuyerInput(
          name: name,
          address: _addressController.text.trim(),
          phone: _nullableText(_phoneController),
          gstin: _nullableText(_gstinController),
          state: _nullableText(_stateController),
          stateCode: _nullableText(_stateCodeController),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<Buyer>(buyer);
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
