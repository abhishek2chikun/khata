import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../services/buyers_service.dart';
import 'product_form_screen.dart';
import '../services/payments_service.dart';
import '../services/products_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productsService,
    this.buyersService,
    this.supportsProductReactivation = false,
  });

  final Product product;
  final ProductsService productsService;
  final BuyersService? buyersService;
  final bool supportsProductReactivation;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _isSaving = false;
  bool _wasEdited = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_wasEdited,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_product);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Product details')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_errorMessage != null) ...<Widget>[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSection(
                'Pricing',
                <Widget>[
                  AppInfoRow(
                    label: 'Buying price',
                    value: _money(_product.buyingPrice),
                  ),
                  AppInfoRow(
                    label: 'Selling price',
                    value: _money(_product.sellingPrice),
                    emphasized: true,
                  ),
                  AppInfoRow(label: 'GST', value: _percent(_product.gstRate)),
                  AppInfoRow(label: 'Unit', value: _product.unit ?? 'Not set'),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                'Stock',
                <Widget>[
                  AppInfoRow(
                    label: 'Stock on hand',
                    value: _quantity(_product.quantityOnHand),
                    emphasized: true,
                  ),
                  AppInfoRow(
                    label: 'Low stock threshold',
                    value: _quantity(_product.lowStockThreshold),
                  ),
                  if (_product.isLowStock)
                    Chip(
                      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text('Low stock'),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSection(
                'Status',
                <Widget>[
                  AppInfoRow(
                    label: 'Availability',
                    value: _product.isActive ? 'Active' : 'Archived',
                  ),
                  if (!_product.isActive) ...<Widget>[
                    const Text(
                        'Archived products are hidden from new invoices.'),
                    if (!widget.supportsProductReactivation)
                      const Text(
                          'Reactivation is only available in local mode.'),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('editProductButton'),
                onPressed: _isSaving ? null : _handleEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit product'),
              ),
              const SizedBox(height: 8),
              if (_product.isActive) ...<Widget>[
                OutlinedButton.icon(
                  key: const Key('adjustStockButton'),
                  onPressed: _isSaving ? null : _showStockAdjustmentDialog,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Adjust stock'),
                ),
                const SizedBox(height: 8),
              ],
              if (_product.isActive)
                OutlinedButton.icon(
                  key: const Key('archiveProductButton'),
                  onPressed: _isSaving ? null : _confirmArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive product'),
                )
              else if (widget.supportsProductReactivation)
                FilledButton.icon(
                  key: const Key('reactivateProductButton'),
                  onPressed: _isSaving ? null : _reactivate,
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Reactivate product'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_product.itemName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(_product.itemNumber)),
                Chip(label: Text(_product.companyName)),
                Chip(label: Text(_product.category)),
                if (_product.hsnCode != null && _product.hsnCode!.isNotEmpty)
                  Chip(label: Text('HSN ${_product.hsnCode}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSectionHeader(title: title),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute<Product>(
        builder: (_) => ProductFormScreen(
          productsService: widget.productsService,
          buyersService: widget.buyersService,
          product: _product,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _product = result;
        _wasEdited = true;
      });
    }
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archive product?'),
            content: const Text(
              'Archived products are hidden from new invoices until reactivated.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await _archive(popOnSuccess: true);
    }
  }

  Future<void> _archive({bool popOnSuccess = false}) async {
    await _saveChange(
      () => widget.productsService.archiveProduct(id: _product.id),
      successMessage: 'Product archived',
    );
    if (popOnSuccess && mounted && _errorMessage == null) {
      Navigator.of(context).pop(_product);
    }
  }

  Future<void> _reactivate() async {
    await _saveChange(
      () => widget.productsService.reactivateProduct(id: _product.id),
      successMessage: 'Product reactivated',
    );
  }

  Future<void> _showStockAdjustmentDialog() async {
    final controller = TextEditingController();
    String? stockAdjustmentError;
    final delta = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust stock'),
          content: TextField(
            key: const Key('stockAdjustmentField'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: 'Quantity change',
              helperText: 'Use a negative number to reduce stock.',
              errorText: stockAdjustmentError,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed != null && parsed.isFinite && parsed != 0) {
                  Navigator.of(context).pop(parsed);
                } else if (parsed == 0) {
                  setDialogState(() {
                    stockAdjustmentError = 'Quantity change must be non-zero.';
                  });
                }
              },
              child: const Text('Apply adjustment'),
            ),
          ],
        ),
      ),
    );
    if (delta == null) {
      return;
    }
    await _saveChange(
      () => widget.productsService.adjustStock(
        id: _product.id,
        input: AdjustStockInput(
          requestId: generateRequestId(),
          quantityDelta: delta,
          reason: 'Manual inventory adjustment',
        ),
      ),
      successMessage: 'Stock adjusted',
    );
  }

  Future<void> _saveChange(
    Future<Product> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final product = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _product = product;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on ApiError catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _quantity(double value) {
    final unit = _product.unit;
    final formatted = _number(value);
    return unit == null || unit.isEmpty ? formatted : '$formatted $unit';
  }

  String _money(double value) => value.toStringAsFixed(2);

  String _percent(double value) => '${_number(value)}%';

  String _number(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
