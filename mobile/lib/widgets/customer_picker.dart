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
                builder: (_) => _CustomerSearchDialog(customers: customers),
              );
              if (customer != null) {
                onSelected(customer);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Customer',
          suffixIcon: Icon(Icons.search),
        ),
        child: Text(selectedCustomer?.name ?? 'Select customer'),
      ),
    );
  }
}

class _CustomerSearchDialog extends StatefulWidget {
  const _CustomerSearchDialog({required this.customers});

  final List<Customer> customers;

  @override
  State<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<_CustomerSearchDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = widget.customers.where((customer) {
      if (query.isEmpty) return true;
      return customer.name.toLowerCase().contains(query) ||
          customer.address.toLowerCase().contains(query) ||
          (customer.phone?.toLowerCase().contains(query) ?? false) ||
          (customer.gstin?.toLowerCase().contains(query) ?? false);
    }).toList();
    return AlertDialog(
      title: const Text('Select customer'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('customerSearchPickerField'),
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search customers',
                hintText: 'Name, phone, address or GSTIN',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Text('${visible.length} result${visible.length == 1 ? '' : 's'}'),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No customers match your search'))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final customer = visible[index];
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(customer.name),
                          subtitle: customer.address.trim().isEmpty
                              ? null
                              : Text(
                                  customer.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => Navigator.of(context).pop(customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
