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
    required this.onEditProduct,
    this.drawer,
  });

  final ProductsService productsService;
  final Future<bool> Function() onAddProduct;
  final Future<bool> Function(Product product) onEditProduct;
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
                    label: const Text('Add product'),
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
            title: Text(product.itemName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                    '${product.company} • ${product.category} • ${product.itemCode}'),
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
                IconButton(
                  key: Key('editProductButton-${product.id}'),
                  onPressed: product.isActive
                      ? () => _handleEditProduct(product)
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit product',
                ),
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
          company: _companyController.text.trim(),
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

  Future<void> _handleEditProduct(Product product) async {
    final shouldRefresh = await widget.onEditProduct(product);
    if (shouldRefresh && mounted) {
      await _loadProducts();
    }
  }
}
