import 'package:flutter/material.dart';

import '../models/customer.dart';

class CustomerPicker extends StatelessWidget {
  const CustomerPicker({
    super.key,
    required this.customers,
    required this.selectedCustomer,
    required this.onSelected,
    required this.fieldKey,
    this.enabled = true,
  });

  final List<Customer> customers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer> onSelected;
  final Key fieldKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: !enabled
          ? null
          : () async {
              final customer = await showDialog<Customer>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text('Select customer'),
                  children: customers
                      .map(
                        (customer) => SimpleDialogOption(
                          onPressed: () => Navigator.of(context).pop(customer),
                          child: Text(customer.name),
                        ),
                      )
                      .toList(),
                ),
              );
              if (customer != null) {
                onSelected(customer);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Customer',
          border: OutlineInputBorder(),
        ),
        child: Text(selectedCustomer?.name ?? 'Select customer'),
      ),
    );
  }
}
