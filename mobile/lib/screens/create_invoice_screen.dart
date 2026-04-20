import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/product.dart';
import '../models/seller.dart';
import '../services/invoices_service.dart';
import '../services/products_service.dart';
import '../services/sellers_service.dart';
import '../state/invoice_draft_controller.dart';
import '../widgets/error_banner.dart';
import '../widgets/money_text_field.dart';
import '../widgets/product_picker.dart';
import '../widgets/seller_picker.dart';
import 'invoice_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    required this.invoicesService,
    required this.productsService,
    required this.sellersService,
    this.initialSeller,
  });

  final InvoicesService invoicesService;
  final ProductsService productsService;
  final SellersService sellersService;
  final Seller? initialSeller;

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late final InvoiceDraftController _controller;
  final _invoiceDateController = TextEditingController();
  final _placeOfSupplyStateCodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _gstRateController = TextEditingController();
  final _discountPercentController = TextEditingController(text: '0');

  List<Seller> _sellers = const <Seller>[];
  List<Product> _products = const <Product>[];
  bool _isLoading = true;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = InvoiceDraftController(
      invoicesService: widget.invoicesService,
      initialSeller: widget.initialSeller,
    );
    _loadOptions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _invoiceDateController.dispose();
    _placeOfSupplyStateCodeController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _gstRateController.dispose();
    _discountPercentController.dispose();
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
                      if (widget.initialSeller != null)
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Seller',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(widget.initialSeller!.name),
                        )
                      else
                        SellerPicker(
                          fieldKey: const Key('sellerPickerField'),
                          sellers: _sellers,
                          selectedSeller: _controller.draft.seller,
                          onSelected: _controller.updateSeller,
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('invoiceDateField'),
                        controller: _invoiceDateController,
                        onChanged: _controller.updateInvoiceDate,
                        decoration: const InputDecoration(
                          labelText: 'Invoice date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _controller.draft.paymentMode,
                        onChanged: (value) {
                          if (value != null) {
                            _controller.updatePaymentMode(value);
                          }
                        },
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
                          DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Payment mode',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
                      Text('Items', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ProductPicker(
                        fieldKey: const Key('productPickerField-0'),
                        products: _products,
                        selectedProduct: _controller.draft.items.first.product,
                        onSelected: (product) {
                          _controller.updateItemProduct(0, product);
                          _unitPriceController.text = product.defaultSellingPriceExclTax.toStringAsFixed(2);
                          _gstRateController.text = product.defaultGstRate.toStringAsFixed(2);
                        },
                      ),
                      const SizedBox(height: 12),
                      MoneyTextField(
                        fieldKey: const Key('quantityField-0'),
                        controller: _quantityController,
                        label: 'Quantity',
                        onChanged: (value) => _controller.updateItemQuantity(0, _parseNumber(value) ?? 0),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _controller.draft.items.first.pricingMode,
                        onChanged: (value) {
                          if (value != null) {
                            _controller.updateItemPricingMode(0, value);
                          }
                        },
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'PRE_TAX', child: Text('Pre tax')),
                          DropdownMenuItem(value: 'TAX_INCLUSIVE', child: Text('Tax inclusive')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Pricing mode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MoneyTextField(
                        controller: _unitPriceController,
                        label: 'Unit price',
                        onChanged: (value) => _controller.updateItemUnitPrice(0, _parseNumber(value)),
                      ),
                      const SizedBox(height: 12),
                      MoneyTextField(
                        controller: _gstRateController,
                        label: 'GST rate',
                        onChanged: (value) => _controller.updateItemGstRate(0, _parseNumber(value)),
                      ),
                      const SizedBox(height: 12),
                      MoneyTextField(
                        controller: _discountPercentController,
                        label: 'Discount percent',
                        onChanged: (value) =>
                            _controller.updateItemDiscountPercent(0, _parseNumber(value) ?? 0),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('previewInvoiceButton'),
                        onPressed: _controller.isQuoting || _isLoading ? null : _openPreview,
                        child: _controller.isQuoting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final products = await widget.productsService.fetchProducts(filter: const ProductFilter(active: true));
      final sellers = widget.initialSeller != null
          ? <Seller>[widget.initialSeller!]
          : (await widget.sellersService.fetchSellers()).where((seller) => seller.isActive).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
        _sellers = sellers;
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
            builder: (_) => InvoicePreviewScreen(controller: _controller),
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
