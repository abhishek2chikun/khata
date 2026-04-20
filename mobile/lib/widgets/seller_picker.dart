import 'package:flutter/material.dart';

import '../models/seller.dart';

class SellerPicker extends StatelessWidget {
  const SellerPicker({
    super.key,
    required this.sellers,
    required this.selectedSeller,
    required this.onSelected,
    required this.fieldKey,
    this.enabled = true,
  });

  final List<Seller> sellers;
  final Seller? selectedSeller;
  final ValueChanged<Seller> onSelected;
  final Key fieldKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: !enabled
          ? null
          : () async {
              final seller = await showDialog<Seller>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Select seller'),
                  children: sellers
                      .map(
                        (seller) => SimpleDialogOption(
                          onPressed: () => Navigator.of(context).pop(seller),
                          child: Text(seller.name),
                        ),
                      )
                      .toList(),
                ),
              );
              if (seller != null) {
                onSelected(seller);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Seller',
          border: OutlineInputBorder(),
        ),
        child: Text(selectedSeller?.name ?? 'Select seller'),
      ),
    );
  }
}
