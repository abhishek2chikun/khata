import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/product.dart';
import '../models/seller.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';

class InvoiceDraftController extends ChangeNotifier {
  InvoiceDraftController({required InvoicesService invoicesService, Seller? initialSeller})
      : _invoicesService = invoicesService,
        _draft = InvoiceDraft(seller: initialSeller);

  final InvoicesService _invoicesService;

  InvoiceDraft _draft;
  InvoiceQuote? _quote;
  InvoiceDetail? _createdInvoice;
  List<InvoiceWarning> _createWarnings = const <InvoiceWarning>[];
  bool _isQuoting = false;
  bool _isSubmitting = false;
  String? _quoteErrorMessage;
  String? _submitErrorMessage;
  String? _requestId;

  InvoiceDraft get draft => _draft;
  InvoiceQuote? get quote => _quote;
  InvoiceDetail? get createdInvoice => _createdInvoice;
  List<InvoiceWarning> get createWarnings => _createWarnings;
  bool get isQuoting => _isQuoting;
  bool get isSubmitting => _isSubmitting;
  String? get quoteErrorMessage => _quoteErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  String? get requestId => _requestId;

  void updateSeller(Seller? seller) {
    _updateDraft(_draft.copyWith(seller: seller, clearSeller: seller == null));
  }

  void updateInvoiceDate(String invoiceDate) {
    _updateDraft(_draft.copyWith(invoiceDate: invoiceDate.trim()));
  }

  void updatePaymentMode(String paymentMode) {
    _updateDraft(_draft.copyWith(paymentMode: paymentMode));
  }

  void updatePlaceOfSupplyStateCode(String value) {
    final trimmed = value.trim();
    _updateDraft(
      _draft.copyWith(
        placeOfSupplyStateCode: trimmed,
        clearPlaceOfSupplyStateCode: trimmed.isEmpty,
      ),
    );
  }

  void updateNotes(String value) {
    final trimmed = value.trim();
    _updateDraft(_draft.copyWith(notes: trimmed, clearNotes: trimmed.isEmpty));
  }

  void updateItemProduct(int index, Product? product) {
    final current = _draft.items[index];
    _updateItem(
      index,
      current.copyWith(
        product: product,
        clearProduct: product == null,
        unitPrice: product?.defaultSellingPriceExclTax,
        clearUnitPrice: product == null,
        gstRate: product?.defaultGstRate,
        clearGstRate: product == null,
      ),
    );
  }

  void updateItemQuantity(int index, double quantity) {
    _updateItem(index, _draft.items[index].copyWith(quantity: quantity));
  }

  void updateItemPricingMode(int index, String pricingMode) {
    _updateItem(index, _draft.items[index].copyWith(pricingMode: pricingMode));
  }

  void updateItemUnitPrice(int index, double? unitPrice) {
    _updateItem(
      index,
      _draft.items[index].copyWith(unitPrice: unitPrice, clearUnitPrice: unitPrice == null),
    );
  }

  void updateItemGstRate(int index, double? gstRate) {
    _updateItem(index, _draft.items[index].copyWith(gstRate: gstRate, clearGstRate: gstRate == null));
  }

  void updateItemDiscountPercent(int index, double discountPercent) {
    _updateItem(index, _draft.items[index].copyWith(discountPercent: discountPercent));
  }

  Future<bool> requestQuote() async {
    _isQuoting = true;
    _quoteErrorMessage = null;
    notifyListeners();

    try {
      _quote = await _invoicesService.quoteInvoice(_draft);
      return true;
    } on Object catch (error) {
      _quoteErrorMessage = _messageForError(error, forSubmit: false);
      return false;
    } finally {
      _isQuoting = false;
      notifyListeners();
    }
  }

  Future<bool> submitInvoice() async {
    _isSubmitting = true;
    _submitErrorMessage = null;
    _createdInvoice = null;
    _createWarnings = const <InvoiceWarning>[];
    _requestId ??= generateRequestId();
    notifyListeners();

    try {
      final result = await _invoicesService.createInvoice(draft: _draft, requestId: _requestId!);
      _createdInvoice = result.invoice;
      _createWarnings = result.warnings;
      _requestId = null;
      return true;
    } on Object catch (error) {
      _submitErrorMessage = _messageForError(error, forSubmit: true);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _updateItem(int index, InvoiceDraftItem item) {
    final items = List<InvoiceDraftItem>.from(_draft.items);
    items[index] = item;
    _updateDraft(_draft.copyWith(items: items));
  }

  void _updateDraft(InvoiceDraft nextDraft) {
    final changed = nextDraft.toJson().toString() != _draft.toJson().toString();
    _draft = nextDraft;
    if (changed) {
      _quote = null;
      _quoteErrorMessage = null;
      if (_submitErrorMessage != null || _requestId != null) {
        _submitErrorMessage = null;
        _requestId = null;
      }
    }
    notifyListeners();
  }

  String _messageForError(Object error, {required bool forSubmit}) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException) {
      return forSubmit ? 'Connect to the server before saving the invoice' : 'Unable to reach the server';
    }
    if (error is HttpException) {
      return 'Unable to reach the server';
    }
    return forSubmit ? 'Unable to save invoice' : 'Unable to prepare invoice preview';
  }
}
