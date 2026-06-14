import 'package:flutter/material.dart';

import '../models/product.dart';

const productPickerInitialLimit = 50;

class ProductPicker extends StatelessWidget {
  const ProductPicker({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onSelected,
    required this.fieldKey,
    this.enabled = true,
  });

  final List<Product> products;
  final Product? selectedProduct;
  final ValueChanged<Product> onSelected;
  final Key fieldKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: !enabled
          ? null
          : () async {
              final product = await showDialog<Product>(
                context: context,
                builder: (_) => _ProductSearchDialog(products: products),
              );
              if (product != null) {
                onSelected(product);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Product',
          border: OutlineInputBorder(),
        ),
        child: Text(selectedProduct?.itemName ?? 'Select product'),
      ),
    );
  }
}

class _ProductSearchDialog extends StatefulWidget {
  const _ProductSearchDialog({required this.products});

  final List<Product> products;

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final _searchController = TextEditingController();
  late final List<_SearchableProduct> _searchableProducts;
  List<_SearchableProduct> _visibleProducts = const <_SearchableProduct>[];

  @override
  void initState() {
    super.initState();
    _searchableProducts = widget.products
        .map(_SearchableProduct.fromProduct)
        .toList(growable: false);
    _visibleProducts = _initialProducts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchableProduct> _initialProducts() {
    final sorted = List<_SearchableProduct>.from(_searchableProducts)
      ..sort((a, b) => a.product.itemName.compareTo(b.product.itemName));
    return sorted.take(productPickerInitialLimit).toList(growable: false);
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _visibleProducts = _initialProducts();
      });
      return;
    }

    final matches = _searchableProducts
        .where((entry) => entry.normalizedSearchText.contains(query))
        .toList(growable: false);
    setState(() {
      _visibleProducts = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select product'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('productSearchField'),
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              key: const Key('productSearchResultCount'),
              '${_visibleProducts.length} result${_visibleProducts.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _visibleProducts.isEmpty
                  ? const Center(
                      key: Key('productSearchNoResults'),
                      child: Text('No products match your search'),
                    )
                  : ListView.builder(
                      itemCount: _visibleProducts.length,
                      itemBuilder: (context, index) {
                        final entry = _visibleProducts[index];
                        final product = entry.product;
                        final secondaryParts = <String>[
                          product.companyName,
                          product.itemNumber,
                        ];
                        if ((product.hsnCode ?? '').isNotEmpty) {
                          secondaryParts.add('HSN ${product.hsnCode}');
                        }
                        return ListTile(
                          key: Key('productSearchResult-$index'),
                          title: Text(product.itemName),
                          subtitle: Text(secondaryParts.join(' • ')),
                          onTap: () => Navigator.of(context).pop(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SearchableProduct {
  const _SearchableProduct({
    required this.product,
    required this.normalizedSearchText,
  });

  final Product product;
  final String normalizedSearchText;

  factory _SearchableProduct.fromProduct(Product product) {
    final parts = <String>[
      product.itemName,
      product.itemNumber,
      product.companyName,
      if ((product.hsnCode ?? '').isNotEmpty) product.hsnCode!,
    ];
    return _SearchableProduct(
      product: product,
      normalizedSearchText: parts.join(' ').toLowerCase(),
    );
  }
}
