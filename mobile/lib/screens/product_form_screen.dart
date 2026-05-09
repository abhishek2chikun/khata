import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../services/products_service.dart';
import '../widgets/error_banner.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.productsService,
    this.product,
  });

  final ProductsService productsService;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController _companyController;
  late final TextEditingController _categoryController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _gstController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;

  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = <String, String>{};

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _companyController = TextEditingController(text: product?.company ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _itemNameController = TextEditingController(text: product?.itemName ?? '');
    _itemCodeController = TextEditingController(text: product?.itemCode ?? '');
    _priceController = TextEditingController(
      text:
          product == null ? '' : product.defaultSellingPriceExclTax.toString(),
    );
    _gstController = TextEditingController(
      text: product == null ? '' : product.defaultGstRate.toString(),
    );
    _quantityController = TextEditingController(
      text: product == null ? '' : product.quantityOnHand.toString(),
    );
    _thresholdController = TextEditingController(
      text: product == null ? '' : product.lowStockThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _categoryController.dispose();
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _priceController.dispose();
    _gstController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit product' : 'Add product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildField(_companyController, 'Company'),
            _buildField(_categoryController, 'Category'),
            _buildField(_itemNameController, 'Item name'),
            _buildField(_itemCodeController, 'Item code'),
            _buildField(_priceController, 'Selling price (excl tax)',
                keyboardType: TextInputType.number),
            _buildField(_gstController, 'GST rate',
                keyboardType: TextInputType.number),
            if (!_isEditing)
              _buildField(
                _quantityController,
                'Quantity on hand',
                keyboardType: TextInputType.number,
              ),
            _buildField(_thresholdController, 'Low stock threshold',
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          errorText: _fieldErrors[label],
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final validation = _validateInput();
    if (validation == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final product = _isEditing
          ? await widget.productsService.updateProduct(
              id: widget.product!.id,
              input: UpdateProductInput(
                company: _companyController.text.trim(),
                category: _categoryController.text.trim(),
                itemName: _itemNameController.text.trim(),
                itemCode: _itemCodeController.text.trim(),
                defaultSellingPriceExclTax:
                    validation.defaultSellingPriceExclTax,
                defaultGstRate: validation.defaultGstRate,
                lowStockThreshold: validation.lowStockThreshold,
              ),
            )
          : await widget.productsService.createProduct(
              CreateProductInput(
                company: _companyController.text.trim(),
                category: _categoryController.text.trim(),
                itemName: _itemNameController.text.trim(),
                itemCode: _itemCodeController.text.trim(),
                defaultSellingPriceExclTax:
                    validation.defaultSellingPriceExclTax,
                defaultGstRate: validation.defaultGstRate,
                quantityOnHand: validation.quantityOnHand,
                lowStockThreshold: validation.lowStockThreshold,
              ),
            );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(product);
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

  _ValidatedProductInput? _validateInput() {
    final errors = <String, String>{};
    _requireText(errors, _companyController, 'Company');
    _requireText(errors, _categoryController, 'Category');
    _requireText(errors, _itemNameController, 'Item name');
    _requireText(errors, _itemCodeController, 'Item code');
    final sellingPrice = _parseRequiredNumber(
      errors,
      _priceController,
      'Selling price (excl tax)',
      'Selling price',
    );
    final gstRate = _parseRequiredNumber(
      errors,
      _gstController,
      'GST rate',
      'GST rate',
    );
    final quantityOnHand = _isEditing
        ? widget.product!.quantityOnHand
        : _parseRequiredNumber(
            errors,
            _quantityController,
            'Quantity on hand',
            'Quantity on hand',
          );
    final lowStockThreshold = _parseRequiredNumber(
      errors,
      _thresholdController,
      'Low stock threshold',
      'Low stock threshold',
    );

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
      _errorMessage = null;
    });

    if (errors.isNotEmpty) {
      return null;
    }
    return _ValidatedProductInput(
      defaultSellingPriceExclTax: sellingPrice!,
      defaultGstRate: gstRate!,
      quantityOnHand: quantityOnHand!,
      lowStockThreshold: lowStockThreshold!,
    );
  }

  void _requireText(
    Map<String, String> errors,
    TextEditingController controller,
    String label,
  ) {
    if (controller.text.trim().isEmpty) {
      errors[label] = '$label is required.';
    }
  }

  double? _parseRequiredNumber(
    Map<String, String> errors,
    TextEditingController controller,
    String label,
    String displayName,
  ) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      errors[label] = '$displayName is required.';
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) {
      errors[label] = '$displayName must be a valid number.';
      return null;
    }
    return parsed;
  }
}

class _ValidatedProductInput {
  const _ValidatedProductInput({
    required this.defaultSellingPriceExclTax,
    required this.defaultGstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  });

  final double defaultSellingPriceExclTax;
  final double defaultGstRate;
  final double quantityOnHand;
  final double lowStockThreshold;
}
