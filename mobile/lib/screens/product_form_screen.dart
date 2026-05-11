import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/buyer.dart';
import '../models/product.dart';
import '../services/buyers_service.dart';
import '../services/products_service.dart';
import '../widgets/error_banner.dart';
import 'buyer_form_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.productsService,
    this.buyersService,
    this.product,
  });

  final ProductsService productsService;
  final BuyersService? buyersService;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController _companyController;
  late final TextEditingController _categoryController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _buyingPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _unitController;
  late final TextEditingController _gstController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;

  final FocusNode _companyFocusNode = FocusNode();

  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = <String, String>{};

  List<Buyer> _buyers = const <Buyer>[];
  bool _isLoadingBuyers = true;
  Buyer? _selectedBuyer;
  String? _selectedBuyerId;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _companyController =
        TextEditingController(text: product?.companyName ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _itemNameController = TextEditingController(text: product?.itemName ?? '');
    _itemCodeController =
        TextEditingController(text: product?.itemNumber ?? '');
    _buyingPriceController = TextEditingController(
      text: product == null ? '' : product.buyingPrice.toString(),
    );
    _sellingPriceController = TextEditingController(
      text: product == null ? '' : product.sellingPrice.toString(),
    );
    _unitController = TextEditingController(text: product?.unit ?? '');
    _gstController = TextEditingController(
      text: product == null ? '' : product.gstRate.toString(),
    );
    _quantityController = TextEditingController(
      text: product == null ? '' : product.quantityOnHand.toString(),
    );
    _thresholdController = TextEditingController(
      text: product == null ? '' : product.lowStockThreshold.toString(),
    );
    _selectedBuyerId = product?.buyerId;
    _loadBuyers();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _categoryController.dispose();
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _unitController.dispose();
    _gstController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBuyers() async {
    final buyersService = widget.buyersService;
    if (buyersService == null) {
      setState(() {
        _isLoadingBuyers = false;
      });
      return;
    }
    try {
      final buyers = await buyersService.fetchBuyers();
      if (!mounted) return;
      final initialBuyerId = _selectedBuyerId;
      setState(() {
        _buyers = buyers;
        _isLoadingBuyers = false;
        if (initialBuyerId != null) {
          _selectedBuyer = _buyers.where((b) => b.id == initialBuyerId).firstOrNull;
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingBuyers = false;
      });
    }
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
            _buildCompanyField(),
            _buildField(_categoryController, 'Category'),
            _buildField(_itemNameController, 'Item name'),
            _buildField(_itemCodeController, 'Item number'),
            _buildField(_buyingPriceController, 'Buying price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            _buildField(_sellingPriceController, 'Selling price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            _buildField(_unitController, 'Unit'),
            _buildField(_gstController, 'GST rate',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            if (!_isEditing)
              _buildField(
                _quantityController,
                'Quantity on hand',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            _buildField(_thresholdController, 'Low stock threshold',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
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

  Widget _buildCompanyField() {
    final buyersService = widget.buyersService;
    if (buyersService == null || _isLoadingBuyers) {
      return _buildField(_companyController, 'Company / buyer',
          errorKey: 'Company');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawAutocomplete<Buyer>(
            focusNode: _companyFocusNode,
            textEditingController: _companyController,
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<Buyer> onSelected,
                Iterable<Buyer> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final buyer = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(buyer),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(buyer.name),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Company / buyer',
                  errorText: _fieldErrors['Company'],
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedBuyer != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _selectedBuyer = null;
                                    _selectedBuyerId = null;
                                    _companyController.clear();
                                  });
                                },
                        ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add new buyer',
                        onPressed: _isSaving ? null : _addNewBuyer,
                      ),
                    ],
                  ),
                ),
              );
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.toLowerCase();
              if (query.isEmpty) return _buyers;
              return _buyers.where(
                (buyer) => buyer.name.toLowerCase().contains(query),
              );
            },
            displayStringForOption: (Buyer buyer) => buyer.name,
            onSelected: (Buyer buyer) {
              setState(() {
                _selectedBuyer = buyer;
                _selectedBuyerId = buyer.id;
                _companyController.text = buyer.name;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addNewBuyer() async {
    final buyersService = widget.buyersService;
    if (buyersService == null) return;
    final result = await Navigator.of(context).push<Buyer>(
      MaterialPageRoute<Buyer>(
        builder: (_) => BuyerFormScreen(buyersService: buyersService),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _buyers = [..._buyers, result];
        _selectedBuyer = result;
        _selectedBuyerId = result.id;
        _companyController.text = result.name;
      });
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? errorKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          errorText: _fieldErrors[errorKey ?? label],
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
                companyName: _companyController.text.trim(),
                category: _categoryController.text.trim(),
                itemName: _itemNameController.text.trim(),
                itemNumber: _itemCodeController.text.trim(),
                buyingPrice: validation.buyingPrice,
                sellingPrice: validation.sellingPrice,
                unit: validation.unit,
                gstRate: validation.gstRate,
                lowStockThreshold: validation.lowStockThreshold,
                buyerId: _selectedBuyerId,
              ),
            )
          : await widget.productsService.createProduct(
              CreateProductInput(
                companyName: _companyController.text.trim(),
                category: _categoryController.text.trim(),
                itemName: _itemNameController.text.trim(),
                itemNumber: _itemCodeController.text.trim(),
                buyingPrice: validation.buyingPrice,
                sellingPrice: validation.sellingPrice,
                unit: validation.unit,
                gstRate: validation.gstRate,
                quantityOnHand: validation.quantityOnHand,
                lowStockThreshold: validation.lowStockThreshold,
                buyerId: _selectedBuyerId,
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
    _requireText(errors, _companyController, 'Company',
        message: 'Company or buyer is required.');
    _requireText(errors, _categoryController, 'Category');
    _requireText(errors, _itemNameController, 'Item name');
    _requireText(errors, _itemCodeController, 'Item number');
    final buyingPrice = _parseRequiredNumber(
      errors,
      _buyingPriceController,
      'Buying price',
      'Buying price',
      invalidMessage: 'Buying price must be a valid amount.',
    );
    final sellingPrice = _parseRequiredNumber(
      errors,
      _sellingPriceController,
      'Selling price',
      'Selling price',
      invalidMessage: 'Selling price must be a valid amount.',
    );
    final gstRate = _parseRequiredNumber(
      errors,
      _gstController,
      'GST rate',
      'GST rate',
      invalidMessage: 'GST rate must be a valid percentage.',
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
      buyingPrice: buyingPrice!,
      sellingPrice: sellingPrice!,
      unit: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      gstRate: gstRate!,
      quantityOnHand: quantityOnHand!,
      lowStockThreshold: lowStockThreshold!,
    );
  }

  void _requireText(
    Map<String, String> errors,
    TextEditingController controller,
    String label, {
    String? message,
  }) {
    if (controller.text.trim().isEmpty) {
      errors[label] = message ?? '$label is required.';
    }
  }

  double? _parseRequiredNumber(
    Map<String, String> errors,
    TextEditingController controller,
    String label,
    String displayName, {
    String? invalidMessage,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      errors[label] = '$displayName is required.';
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) {
      errors[label] = invalidMessage ?? '$displayName must be a valid number.';
      return null;
    }
    if (parsed < 0) {
      errors[label] = '$displayName must be zero or greater.';
      return null;
    }
    return parsed;
  }
}

class _ValidatedProductInput {
  const _ValidatedProductInput({
    required this.buyingPrice,
    required this.sellingPrice,
    required this.unit,
    required this.gstRate,
    required this.quantityOnHand,
    required this.lowStockThreshold,
  });

  final double buyingPrice;
  final double sellingPrice;
  final String? unit;
  final double gstRate;
  final double quantityOnHand;
  final double lowStockThreshold;
}
