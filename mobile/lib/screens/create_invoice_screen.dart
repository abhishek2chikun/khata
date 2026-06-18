import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/company_profile.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/decimal_validators.dart';
import '../services/company_profile_service.dart';
import '../services/invoices_service.dart';
import '../services/invoice_settlement.dart';
import '../services/invoice_share_service.dart';
import '../services/products_service.dart';
import '../services/customers_service.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';
import '../widgets/money_text_field.dart';
import '../widgets/product_picker.dart';
import '../widgets/customer_picker.dart';
import '../widgets/app_ui.dart';
import 'customer_quick_add_dialog.dart';
import 'product_quick_add_dialog.dart';
import 'invoice_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    required this.invoicesService,
    required this.productsService,
    required this.customersService,
    this.companyProfileService,
    this.initialCustomer,
    this.shareService,
  });

  final InvoicesService invoicesService;
  final ProductsService productsService;
  final CustomersService customersService;
  final CompanyProfileService? companyProfileService;
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
  CompanyProfile? _sellerProfile;
  bool _isLoading = true;
  bool _showPlaceOfSupplyOverride = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = InvoiceDraftController(
      invoicesService: widget.invoicesService,
      initialCustomer: widget.initialCustomer,
    );
    _invoiceDateController = TextEditingController(
      text: _formatDate(DateTime.now()),
    );
    _controller.updateInvoiceDate(_invoiceDateController.text);
    _controller.addListener(_syncControllers);
    _syncControllers();
    _loadOptions();
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
        _unitPriceControllers[i].text =
            canonicalUnitPriceString(item.unitPrice!);
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
                      const AppSectionHeader(
                        title: 'Invoice details',
                        subtitle: 'Choose the customer, date and payment mode.',
                      ),
                      const SizedBox(height: 12),
                      _buildCustomerSection(),
                      const SizedBox(height: 12),
                      _buildGstModeSection(),
                      const SizedBox(height: 12),
                      _buildDateField(),
                      const SizedBox(height: 12),
                      _buildPaymentModeSection(),
                      const SizedBox(height: 12),
                      if (_showGstControls) ...[
                        _buildPlaceOfSupplySection(),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        onChanged: _controller.updateNotes,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildItemsSection(),
                      const SizedBox(height: 16),
                      if (_showGstControls) ...<Widget>[
                        _buildApplyGstToAll(),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildPlaceOfSupplySection() {
    final company = _sellerProfile;
    if (company == null) {
      return const SizedBox.shrink();
    }
    final customer = _controller.draft.customer;
    final override = _controller.draft.placeOfSupplyStateCode;
    final effectiveCode =
        (override != null && override.isNotEmpty)
            ? override
            : (customer?.stateCode?.isNotEmpty == true
                ? customer!.stateCode!
                : company.stateCode);
    final effectiveState = (override != null && override.isNotEmpty)
        ? null
        : (customer?.state?.isNotEmpty == true
            ? customer!.state!
            : company.state);
    final displayValue = effectiveState != null
        ? '$effectiveState ($effectiveCode)'
        : effectiveCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InputDecorator(
          key: const Key('placeOfSupplyDisplay'),
          decoration: const InputDecoration(
            labelText: 'Place of supply',
            border: OutlineInputBorder(),
          ),
          child: Text(displayValue),
        ),
        TextButton(
          key: const Key('changePlaceOfSupplyButton'),
          onPressed: () {
            setState(() {
              _showPlaceOfSupplyOverride = !_showPlaceOfSupplyOverride;
            });
          },
          child: Text(
            _showPlaceOfSupplyOverride
                ? 'Use default place of supply'
                : 'Change place of supply',
          ),
        ),
        if (_showPlaceOfSupplyOverride) ...<Widget>[
          TextField(
            key: const Key('placeOfSupplyStateCodeField'),
            controller: _placeOfSupplyStateCodeController,
            keyboardType: TextInputType.number,
            onChanged: _controller.updatePlaceOfSupplyStateCode,
            decoration: const InputDecoration(
              labelText: 'Override state code (optional)',
              hintText: 'e.g. 27',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGstModeSection() {
    final profile = _sellerProfile;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    if (!profile.gstFlag) {
      return const Text(
        'Non-GST invoice (seller is not GST registered)',
        key: Key('nonGstSellerNotice'),
      );
    }
    final draftGstFlag = _controller.draft.gstFlag ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SwitchListTile(
          key: const Key('invoiceGstFlagSwitch'),
          title: const Text('GST invoice'),
          subtitle: const Text('Turn off for zero-rate non-GST bills'),
          value: draftGstFlag,
          onChanged: _controller.setGstFlag,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return TextField(
      key: const Key('invoiceDateField'),
      controller: _invoiceDateController,
      readOnly: true,
      onTap: _pickDate,
      decoration: const InputDecoration(
        labelText: 'Invoice date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final formatted = _formatDate(date);
    _invoiceDateController.text = formatted;
    _controller.updateInvoiceDate(formatted);
  }

  bool get _showGstControls {
    final profile = _sellerProfile;
    if (profile == null || !profile.gstFlag) {
      return false;
    }
    return _controller.draft.gstFlag ?? true;
  }

  Widget _buildPaymentModeSection() {
    final settlementMode = _controller.draft.paymentMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<String>(
          key: const Key('paymentModeField'),
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: settlementModeCash,
              label: Text('Cash'),
            ),
            ButtonSegment<String>(
              value: settlementModeCredit,
              label: Text('Credit'),
            ),
          ],
          selected: <String>{settlementMode},
          onSelectionChanged: (selection) {
            _controller.updateSettlementMode(selection.first);
            if (selection.first == settlementModeCash) {
              _paidAmountController.clear();
            }
          },
        ),
        if (settlementMode == settlementModeCredit) ...<Widget>[
          const SizedBox(height: 12),
          MoneyTextField(
            fieldKey: const Key('amountReceivedField'),
            controller: _paidAmountController,
            label: 'Amount received',
            onChanged: (value) =>
                _controller.updateAmountReceived(_parseNumber(value) ?? 0),
          ),
          if (_controller.amountReceivedError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              key: const Key('amountReceivedError'),
              _controller.amountReceivedError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildItemsSection() {
    final items = _controller.draft.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(
          title: 'Invoice items',
          subtitle: 'Add products and confirm quantity and selling price.',
        ),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          return _buildItemCard(index, items.length > 1);
        }),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('addProductButton'),
                onPressed: _openProductQuickAdd,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('New product'),
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
                          canonicalUnitPriceString(product.sellingPrice);
                      if (_showGstControls) {
                        _gstRateControllers[index].text =
                            product.gstRate.toStringAsFixed(2);
                      }
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
            Row(children: [
              Expanded(
                child: MoneyTextField(
                  fieldKey: Key('quantityField-$index'),
                  controller: _quantityControllers[index],
                  label: 'Quantity',
                  onChanged: (value) => _controller.updateItemQuantity(
                    index,
                    _parseNumber(value) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MoneyTextField(
                  fieldKey: Key('unitPriceField-$index'),
                  controller: _unitPriceControllers[index],
                  label: 'Selling price',
                  onChanged: (value) => _controller.updateItemUnitPrice(
                    index,
                    _parseNumber(value),
                  ),
                ),
              ),
            ]),
            if (_showGstControls) ...<Widget>[
              const SizedBox(height: 8),
              MoneyTextField(
                fieldKey: Key('gstRateField-$index'),
                controller: _gstRateControllers[index],
                label: 'GST rate',
                onChanged: (value) =>
                    _controller.updateItemGstRate(index, _parseNumber(value)),
              ),
            ],
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
      if (widget.companyProfileService != null) {
        try {
          _sellerProfile =
              await widget.companyProfileService!.fetchCompanyProfile();
          _controller.initializeGstFlag(_sellerProfile!.gstFlag);
        } on ApiError catch (error) {
          if (error.statusCode != 404) {
            rethrow;
          }
        }
      }
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
              companyProfile: _sellerProfile,
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
