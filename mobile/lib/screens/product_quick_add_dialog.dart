import 'package:flutter/material.dart';

import '../services/products_service.dart';

class ProductQuickAddDialog extends StatefulWidget {
  const ProductQuickAddDialog({
    super.key,
    required this.productsService,
  });

  final ProductsService productsService;

  @override
  State<ProductQuickAddDialog> createState() => _ProductQuickAddDialogState();
}

class _ProductQuickAddDialogState extends State<ProductQuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _itemNumberController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _gstRateController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNumberController.dispose();
    _companyNameController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
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
                key: const Key('productItemNameField'),
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productItemNumberField'),
                controller: _itemNumberController,
                decoration: const InputDecoration(
                  labelText: 'Item number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productCompanyNameField'),
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productCategoryField'),
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productSellingPriceField'),
                controller: _sellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Selling price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productGstRateField'),
                controller: _gstRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'GST rate',
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
          key: const Key('saveProductButton'),
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
      final product = await widget.productsService.createProduct(
        CreateProductInput(
          companyName: _companyNameController.text.trim(),
          category: _categoryController.text.trim(),
          itemName: _itemNameController.text.trim(),
          itemNumber: _itemNumberController.text.trim(),
          buyingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0,
          sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0,
          gstRate: double.tryParse(_gstRateController.text.trim()) ?? 0,
          quantityOnHand: 0,
          lowStockThreshold: 0,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(product);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to create product';
        _isSaving = false;
      });
    }
  }
}
