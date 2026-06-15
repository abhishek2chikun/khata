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
        actions: <Widget>[
          IconButton.filledTonal(
            key: const Key('addProductButton'),
            onPressed: _handleAddProduct,
            icon: const Icon(Icons.add),
            tooltip: 'Add product',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('searchFilterField'),
              controller: _searchController,
              onChanged: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Search name, item number, HSN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('companyFilterField'),
                    controller: _companyController,
                    onChanged: (_) => _loadProducts(),
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('categoryFilterField'),
                    controller: _categoryController,
                    onChanged: (_) => _loadProducts(),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  '${_products.length} products',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                if (_companyController.text.isNotEmpty ||
                    _categoryController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _companyController.clear();
                      _categoryController.clear();
                      _loadProducts();
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Clear filters'),
                  ),
              ],
            ),
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
          margin: EdgeInsets.zero,
          child: ListTile(
            key: Key('productRow-${product.id}'),
            onTap: () => _handleProductSelected(product),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(
              product.itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        product.itemNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text('  •  '),
                    Flexible(
                      child: Text(
                        product.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text('  •  '),
                    Flexible(
                      child: Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock ${_formatQuantity(product)}',
                      warning: product.isLowStock,
                    ),
                    _InfoChip(
                      icon: Icons.currency_rupee,
                      label: product.sellingPrice.toStringAsFixed(2),
                    ),
                    if (product.gstRate > 0)
                      _InfoChip(
                        icon: Icons.receipt_long_outlined,
                        label: 'GST ${_formatPercent(product.gstRate)}',
                      ),
                    if (!product.isActive)
                      const _InfoChip(
                        icon: Icons.archive_outlined,
                        label: 'Archived',
                        warning: true,
                      ),
                  ],
                ),
                if (product.isLowStock)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Low stock',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (!product.isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Editing disabled for archived products'),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
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
  const _InfoChip({
    required this.icon,
    required this.label,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
