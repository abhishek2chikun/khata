import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/buyer.dart';
import '../services/buyers_service.dart';
import '../widgets/error_banner.dart';

class BuyerFormScreen extends StatefulWidget {
  const BuyerFormScreen({
    super.key,
    required this.buyersService,
    this.buyer,
  });

  final BuyersService buyersService;
  final Buyer? buyer;

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
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

  bool get _isEditing => widget.buyer != null;

  @override
  void initState() {
    super.initState();
    final buyer = widget.buyer;
    _nameController = TextEditingController(text: buyer?.name ?? '');
    _addressController = TextEditingController(text: buyer?.address ?? '');
    _phoneController = TextEditingController(text: buyer?.phone ?? '');
    _whatsappController =
        TextEditingController(text: buyer?.whatsappNumber ?? '');
    _gstinController = TextEditingController(text: buyer?.gstin ?? '');
    _stateController = TextEditingController(text: buyer?.state ?? '');
    _stateCodeController = TextEditingController(text: buyer?.stateCode ?? '');

    if (buyer != null &&
        buyer.whatsappNumber != null &&
        buyer.whatsappNumber == buyer.phone) {
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit buyer' : 'Add buyer')),
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
              key: const Key('buyerWhatsappField'),
              controller: _whatsappController,
              label: 'WhatsApp number',
              enabled: !_whatsappSameAsPhone,
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
                  : Text(_isEditing ? 'Save changes' : 'Save buyer'),
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
      final Buyer buyer;
      if (_isEditing) {
        buyer = await widget.buyersService.updateBuyer(
          id: widget.buyer!.id,
          input: UpdateBuyerInput(
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
        buyer = await widget.buyersService.createBuyer(
          CreateBuyerInput(
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
