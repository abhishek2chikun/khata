import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../services/products_service.dart';
import '../widgets/error_banner.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({
    super.key,
    required this.productsService,
    required this.onAddProduct,
    required this.onProductSelected,
    this.drawer,
  });

  final ProductsService productsService;
  final Future<bool> Function() onAddProduct;
  final Future<Product?> Function(Product product) onProductSelected;
  final Widget? drawer;

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _searchController = TextEditingController();
  final _companyController = TextEditingController();
  final _categoryController = TextEditingController();

  List<Product> _products = const <Product>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('addProductButton'),
                    onPressed: _handleAddProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('searchFilterField'),
              controller: _searchController,
              onChanged: (_) => _loadProducts(),
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('companyFilterField'),
              controller: _companyController,
              onChanged: (_) => _loadProducts(),
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('categoryFilterField'),
              controller: _categoryController,
              onChanged: (_) => _loadProducts(),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return ListView.separated(
      itemCount: _products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          child: ListTile(
            key: Key('productRow-${product.id}'),
            onTap: () => _handleProductSelected(product),
            title: Text(product.itemName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(product.itemNumber),
                    _InfoChip(product.companyName),
                    _InfoChip(product.category),
                    _InfoChip('Stock: ${_formatQuantity(product)}'),
                    _InfoChip(
                        'Selling: ${product.sellingPrice.toStringAsFixed(2)}'),
                    _InfoChip('GST: ${_formatPercent(product.gstRate)}'),
                    _InfoChip(product.isActive ? 'Active' : 'Archived'),
                  ],
                ),
                if (product.isLowStock)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Low stock'),
                  ),
                if (!product.isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Editing disabled for archived products'),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!product.isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Chip(label: Text('Archived')),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await widget.productsService.fetchProducts(
        filter: ProductFilter(
          search: _searchController.text.trim(),
          companyName: _companyController.text.trim(),
          category: _categoryController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
      });
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _products = const <Product>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddProduct() async {
    final shouldRefresh = await widget.onAddProduct();
    if (shouldRefresh && mounted) {
      await _loadProducts();
    }
  }

  Future<void> _handleProductSelected(Product product) async {
    final updatedProduct = await widget.onProductSelected(product);
    if (updatedProduct != null && mounted) {
      await _loadProducts();
    }
  }

  String _formatQuantity(Product product) {
    final quantity = _formatNumber(product.quantityOnHand);
    final unit = product.unit;
    return unit == null || unit.isEmpty ? quantity : '$quantity $unit';
  }

  String _formatPercent(double value) => '${_formatNumber(value)}%';

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}
