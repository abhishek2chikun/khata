import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../services/products_service.dart';
import '../widgets/error_banner.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productsService,
    required this.onEditProduct,
  });

  final Product product;
  final ProductsService productsService;
  final Future<bool> Function(Product product) onEditProduct;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _buildDetail('Buying price', _money(_product.buyingPrice)),
                _buildDetail('Selling price', _money(_product.sellingPrice)),
                _buildDetail('GST', _percent(_product.gstRate)),
                _buildDetail('Unit', _product.unit ?? 'Not set'),
              ],
            ),
            const SizedBox(height: 12),
            _buildSection(
              'Stock',
              <Widget>[
                _buildDetail(
                    'Stock on hand', _quantity(_product.quantityOnHand)),
                _buildDetail(
                  'Low stock threshold',
                  _quantity(_product.lowStockThreshold),
                ),
                if (_product.isLowStock) const Text('Low stock'),
                const Text('Stock movement history is deferred for this task.'),
              ],
            ),
            const SizedBox(height: 12),
            _buildSection(
              'Status',
              <Widget>[
                _buildDetail(
                    'Status', _product.isActive ? 'Active' : 'Archived'),
                if (!_product.isActive)
                  const Text('Archived products are hidden from new invoices.'),
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
            OutlinedButton.icon(
              key: const Key('adjustStockButton'),
              onPressed: _isSaving ? null : _showStockAdjustmentDialog,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Adjust stock'),
            ),
            const SizedBox(height: 8),
            if (_product.isActive)
              OutlinedButton.icon(
                key: const Key('archiveProductButton'),
                onPressed: _isSaving ? null : _confirmArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive product'),
              )
            else
              FilledButton.icon(
                key: const Key('reactivateProductButton'),
                onPressed: _isSaving ? null : () => _setActive(true),
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('Reactivate product'),
              ),
          ],
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
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                Text(_product.itemNumber),
                Text(_product.companyName),
                Text(_product.category),
                Text(_product.isActive ? 'Active' : 'Archived'),
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Future<void> _handleEdit() async {
    final shouldRefresh = await widget.onEditProduct(_product);
    if (shouldRefresh && mounted) {
      Navigator.of(context).pop(_product);
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
      await _setActive(false, popOnSuccess: true);
    }
  }

  Future<void> _setActive(bool isActive, {bool popOnSuccess = false}) async {
    await _saveChange(() {
      return widget.productsService.updateProduct(
        id: _product.id,
        input: UpdateProductInput(
          companyName: _product.companyName,
          category: _product.category,
          itemName: _product.itemName,
          itemNumber: _product.itemNumber,
          buyingPrice: _product.buyingPrice,
          sellingPrice: _product.sellingPrice,
          unit: _product.unit,
          gstRate: _product.gstRate,
          lowStockThreshold: _product.lowStockThreshold,
          isActive: isActive,
        ),
      );
    }, successMessage: isActive ? 'Product reactivated' : 'Product archived');
    if (popOnSuccess && mounted && _errorMessage == null) {
      Navigator.of(context).pop(_product);
    }
  }

  Future<void> _showStockAdjustmentDialog() async {
    final controller = TextEditingController();
    final delta = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust stock'),
        content: TextField(
          key: const Key('stockAdjustmentField'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Quantity change',
            helperText: 'Use a negative number to reduce stock.',
            border: OutlineInputBorder(),
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
              if (parsed != null && parsed.isFinite) {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop(parsed);
              }
            },
            child: const Text('Apply adjustment'),
          ),
        ],
      ),
    );
    if (delta == null) {
      return;
    }
    await _saveChange(
      () =>
          widget.productsService.adjustQuantity(id: _product.id, delta: delta),
      successMessage: 'Stock adjusted. Movement history is deferred.',
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
