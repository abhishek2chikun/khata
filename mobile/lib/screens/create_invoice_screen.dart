import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/invoices_service.dart';
import '../services/invoice_share_service.dart';
import '../services/products_service.dart';
import '../services/customers_service.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';
import '../widgets/money_text_field.dart';
import '../widgets/product_picker.dart';
import '../widgets/customer_picker.dart';
import 'customer_quick_add_dialog.dart';
import 'product_quick_add_dialog.dart';
import 'invoice_preview_screen.dart';
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    required this.invoicesService,
    required this.productsService,
    required this.customersService,
    this.initialCustomer,
    this.shareService,
  });

  final InvoicesService invoicesService;
  final ProductsService productsService;
  final CustomersService customersService;
  final Customer? initialCustomer;
  final InvoiceShareService? shareService;

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late final InvoiceDraftController _controller;
  late final TextEditingController _invoiceDateController;
  final _placeOfSupplyStateCodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _applyGstController = TextEditingController();
  final _paidAmountController = TextEditingController();

  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _unitPriceControllers = [];
  final List<TextEditingController> _gstRateControllers = [];

  List<Customer> _customers = const <Customer>[];
  List<Product> _products = const <Product>[];
  bool _isLoading = true;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = InvoiceDraftController(
      invoicesService: widget.invoicesService,
      initialCustomer: widget.initialCustomer,
    );
    _invoiceDateController = TextEditingController(
      text: _formatDateTime(DateTime.now()),
    );
    final initialDate = _invoiceDateController.text.split(' ').first;
    _controller.updateInvoiceDate(initialDate);
    _controller.updateInvoiceDatetime(_invoiceDateController.text);
    _controller.addListener(_syncControllers);
    _syncControllers();
    _loadOptions();
  }

  static String _formatDateTime(DateTime dt) {
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  void _syncControllers() {
    final items = _controller.draft.items;
    while (_quantityControllers.length < items.length) {
      _quantityControllers.add(TextEditingController(text: '1'));
    }
    while (_unitPriceControllers.length < items.length) {
      _unitPriceControllers.add(TextEditingController());
    }
    while (_gstRateControllers.length < items.length) {
      _gstRateControllers.add(TextEditingController());
    }
    while (_quantityControllers.length > items.length) {
      _quantityControllers.removeLast().dispose();
      _unitPriceControllers.removeLast().dispose();
      _gstRateControllers.removeLast().dispose();
    }
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (_unitPriceControllers[i].text.isEmpty && item.unitPrice != null) {
        _unitPriceControllers[i].text = item.unitPrice!.toStringAsFixed(2);
      }
      if (_gstRateControllers[i].text.isEmpty && item.gstRate != null) {
        _gstRateControllers[i].text = item.gstRate!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncControllers);
    _controller.dispose();
    _invoiceDateController.dispose();
    _placeOfSupplyStateCodeController.dispose();
    _notesController.dispose();
    _applyGstController.dispose();
    _paidAmountController.dispose();
    for (final c in _quantityControllers) {
      c.dispose();
    }
    for (final c in _unitPriceControllers) {
      c.dispose();
    }
    for (final c in _gstRateControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create invoice')),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_loadErrorMessage != null) ...<Widget>[
                        ErrorBanner(message: _loadErrorMessage!),
                        const SizedBox(height: 16),
                      ],
                      if (_controller.quoteErrorMessage != null) ...<Widget>[
                        ErrorBanner(message: _controller.quoteErrorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildCustomerSection(),
                      const SizedBox(height: 12),
                      _buildDateTimeField(),
                      const SizedBox(height: 12),
                      _buildPaymentStateSection(),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('placeOfSupplyStateCodeField'),
                        controller: _placeOfSupplyStateCodeController,
                        onChanged: _controller.updatePlaceOfSupplyStateCode,
                        decoration: const InputDecoration(
                          labelText: 'Place of supply state code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        onChanged: _controller.updateNotes,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildItemsSection(),
                      const SizedBox(height: 16),
                      _buildApplyGstToAll(),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('previewInvoiceButton'),
                        onPressed: _controller.isQuoting || _isLoading
                            ? null
                            : _openPreview,
                        child: _controller.isQuoting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Preview invoice'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.initialCustomer != null)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Customer',
              border: OutlineInputBorder(),
            ),
            child: Text(widget.initialCustomer!.name),
          )
        else
          Row(
            children: <Widget>[
              Expanded(
                child: CustomerPicker(
                  fieldKey: const Key('customerPickerField'),
                  customers: _customers,
                  selectedCustomer: _controller.draft.customer,
                  onSelected: _controller.updateCustomer,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('addCustomerButton'),
                icon: const Icon(Icons.person_add),
                tooltip: 'Add customer',
                onPressed: _openCustomerQuickAdd,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return TextField(
      key: const Key('invoiceDatetimeField'),
      controller: _invoiceDateController,
      readOnly: true,
      onTap: _pickDateTime,
      decoration: const InputDecoration(
        labelText: 'Invoice date & time',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildPaymentStateSection() {
    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: const Key('paymentStateField'),
          value: _controller.draft.paymentState,
          onChanged: (value) {
            if (value != null) {
              _controller.updatePaymentState(value);
            }
          },
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
            DropdownMenuItem(value: 'TOTAL_PAID', child: Text('Total Paid')),
            DropdownMenuItem(value: 'PARTIAL_PAID', child: Text('Partial Paid')),
          ],
          decoration: const InputDecoration(
            labelText: 'Payment state',
            border: OutlineInputBorder(),
          ),
        ),
        if (_controller.draft.paymentState == 'PARTIAL_PAID') ...<Widget>[
          const SizedBox(height: 12),
          MoneyTextField(
            fieldKey: const Key('paidAmountField'),
            controller: _paidAmountController,
            label: 'Paid amount',
            onChanged: (value) =>
                _controller.updatePaidAmount(_parseNumber(value) ?? 0),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsSection() {
    final items = _controller.draft.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          return _buildItemCard(index, items.length > 1);
        }),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: IconButton(
                key: const Key('addProductButton'),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add product',
                onPressed: _openProductQuickAdd,
              ),
            ),
            Expanded(
              child: OutlinedButton(
                key: const Key('addItemButton'),
                onPressed: _controller.addItem,
                child: const Text('Add line'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, bool canRemove) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ProductPicker(
                    fieldKey: Key('productPickerField-$index'),
                    products: _products,
                    selectedProduct: _controller.draft.items[index].product,
                    onSelected: (product) {
                      _controller.updateItemProduct(index, product);
                      _unitPriceControllers[index].text =
                          product.sellingPrice.toStringAsFixed(2);
                      _gstRateControllers[index].text =
                          product.gstRate.toStringAsFixed(2);
                    },
                  ),
                ),
                if (canRemove)
                  IconButton(
                    key: Key('removeItemButton-$index'),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => _controller.removeItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            MoneyTextField(
              fieldKey: Key('quantityField-$index'),
              controller: _quantityControllers[index],
              label: 'Quantity',
              onChanged: (value) => _controller.updateItemQuantity(
                  index, _parseNumber(value) ?? 0),
            ),
            const SizedBox(height: 8),
            MoneyTextField(
              fieldKey: Key('unitPriceField-$index'),
              controller: _unitPriceControllers[index],
              label: 'Selling price',
              onChanged: (value) =>
                  _controller.updateItemUnitPrice(index, _parseNumber(value)),
            ),
            const SizedBox(height: 8),
            MoneyTextField(
              fieldKey: Key('gstRateField-$index'),
              controller: _gstRateControllers[index],
              label: 'GST rate',
              onChanged: (value) =>
                  _controller.updateItemGstRate(index, _parseNumber(value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyGstToAll() {
    return Row(
      children: <Widget>[
        Expanded(
          child: MoneyTextField(
            fieldKey: const Key('applyGstToAllField'),
            controller: _applyGstController,
            label: 'Apply GST to all lines',
            onChanged: (value) {
              final rate = _parseNumber(value);
              if (rate != null) {
                _controller.applyGstToAllLines(rate);
                for (final c in _gstRateControllers) {
                  c.text = rate.toStringAsFixed(2);
                }
              } else {
                _controller.applyGstToAllLines(null);
                for (final c in _gstRateControllers) {
                  c.text = '';
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    final formatted = _formatDateTime(combined);
    _invoiceDateController.text = formatted;
    _controller.updateInvoiceDate(formatted.split(' ').first);
    _controller.updateInvoiceDatetime(formatted);
  }

  Future<void> _openCustomerQuickAdd() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => CustomerQuickAddDialog(
        customersService: widget.customersService,
      ),
    );
    if (customer == null || !mounted) return;
    setState(() {
      _customers = <Customer>[..._customers, customer];
    });
    _controller.updateCustomer(customer);
  }

  Future<void> _openProductQuickAdd() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => ProductQuickAddDialog(
        productsService: widget.productsService,
      ),
    );
    if (product == null || !mounted) return;
    setState(() {
      _products = <Product>[..._products, product];
    });
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final products = await widget.productsService
          .fetchProducts(filter: const ProductFilter(active: true));
      final customers = widget.initialCustomer != null
          ? <Customer>[widget.initialCustomer!]
          : (await widget.customersService.fetchCustomers())
              .where((customer) => customer.isActive)
              .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
        _customers = customers;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadErrorMessage = _messageForLoadError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPreview() async {
    if (!await _controller.requestQuote()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => InvoicePreviewScreen(
              controller: _controller,
              shareService: widget.shareService,
            ),
          ),
        ) ??
        false;
    if (created && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load invoice options';
  }
}
