import 'package:flutter/material.dart';

import '../models/product.dart';

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
                builder: (_) => SimpleDialog(
                  title: const Text('Select product'),
                  children: products
                      .map(
                        (product) => SimpleDialogOption(
                          onPressed: () => Navigator.of(context).pop(product),
                          child: Text(product.itemName),
                        ),
                      )
                      .toList(),
                ),
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
