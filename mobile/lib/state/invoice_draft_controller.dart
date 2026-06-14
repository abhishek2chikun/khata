import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/decimal_validators.dart';
import '../services/invoice_settlement.dart';
import '../services/invoices_service.dart';
import '../services/payments_service.dart';

class InvoiceDraftController extends ChangeNotifier {
  InvoiceDraftController(
      {required InvoicesService invoicesService, Customer? initialCustomer})
      : _invoicesService = invoicesService,
        _draft = InvoiceDraft(customer: initialCustomer);

  final InvoicesService _invoicesService;

  InvoiceDraft _draft;
  InvoiceQuote? _quote;
  InvoiceDetail? _createdInvoice;
  List<InvoiceWarning> _createWarnings = const <InvoiceWarning>[];
  bool _isQuoting = false;
  bool _isSubmitting = false;
  String? _quoteErrorMessage;
  String? _submitErrorMessage;
  String? _amountReceivedError;
  String? _requestId;

  InvoiceDraft get draft => _draft;
  InvoiceQuote? get quote => _quote;
  InvoiceDetail? get createdInvoice => _createdInvoice;
  List<InvoiceWarning> get createWarnings => _createWarnings;
  bool get isQuoting => _isQuoting;
  bool get isSubmitting => _isSubmitting;
  String? get quoteErrorMessage => _quoteErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;
  String? get amountReceivedError => _amountReceivedError;
  String? get requestId => _requestId;

  void updateCustomer(Customer? customer) {
    _updateDraft(_draft.copyWith(customer: customer, clearCustomer: customer == null));
  }

  void updateInvoiceDate(String invoiceDate) {
    _updateDraft(_draft.copyWith(invoiceDate: invoiceDate.trim()));
  }

  void updatePaymentMode(String paymentMode) {
    _updateDraft(
      _draft.copyWith(
        paymentMode: paymentMode,
        paymentState: paymentMode == settlementModeCash
            ? 'TOTAL_PAID'
            : paymentMode == settlementModeCredit
                ? 'CREDIT'
                : paymentMode,
        paidAmount: paymentMode == settlementModeCash ? 0 : _draft.paidAmount,
      ),
    );
    if (paymentMode == settlementModeCash) {
      _amountReceivedError = null;
    }
  }

  void updateSettlementMode(String settlementMode) {
    updatePaymentMode(settlementMode);
  }

  void updateAmountReceived(double amount) {
    final error = validateCreditAmountReceived(
      amount: amount,
      grandTotal: _quote?.totals.grandTotal,
    );
    _amountReceivedError = error;
    _updateDraft(_draft.copyWith(paidAmount: amount));
    notifyListeners();
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
        unitPrice: product?.sellingPrice,
        clearUnitPrice: product == null,
        gstRate: product?.gstRate,
        clearGstRate: product == null,
      ),
    );
  }

  void updateItemQuantity(int index, double quantity) {
    _updateItem(
      index,
      _draft.items[index].copyWith(
        quantity: validatePositiveIntegralQuantity(quantity),
      ),
    );
  }

  void updateItemPricingMode(int index, String pricingMode) {
    _updateItem(index, _draft.items[index].copyWith(pricingMode: pricingMode));
  }

  void updateItemUnitPrice(int index, double? unitPrice) {
    _updateItem(
      index,
      _draft.items[index].copyWith(
        unitPrice: unitPrice == null ? null : validateUnitPrice(unitPrice),
        clearUnitPrice: unitPrice == null,
      ),
    );
  }

  void updateItemGstRate(int index, double? gstRate) {
    _updateItem(
        index,
        _draft.items[index]
            .copyWith(gstRate: gstRate, clearGstRate: gstRate == null));
  }

  void updateItemDiscountPercent(int index, double discountPercent) {
    _updateItem(
        index, _draft.items[index].copyWith(discountPercent: discountPercent));
  }

  void addItem() {
    final items = List<InvoiceDraftItem>.from(_draft.items)
      ..add(const InvoiceDraftItem());
    _updateDraft(_draft.copyWith(items: items));
  }

  void removeItem(int index) {
    if (_draft.items.length <= 1) return;
    final items = List<InvoiceDraftItem>.from(_draft.items)..removeAt(index);
    _updateDraft(_draft.copyWith(items: items));
  }

  void setGstFlag(bool value) {
    final items = _draft.items
        .map(
          (item) => value
              ? item
              : item.copyWith(gstRate: 0, clearGstRate: false),
        )
        .toList();
    _updateDraft(_draft.copyWith(gstFlag: value, items: items));
  }

  void initializeGstFlag(bool value) {
    if (_draft.gstFlag == null) {
      _updateDraft(_draft.copyWith(gstFlag: value));
    }
  }

  void updatePaymentState(String paymentState) {
    final settlementMode = paymentState == 'TOTAL_PAID'
        ? settlementModeCash
        : settlementModeCredit;
    _updateDraft(
      _draft.copyWith(
        paymentState: paymentState,
        paymentMode: settlementMode,
      ),
    );
  }

  void updatePaidAmount(double paidAmount) {
    updateAmountReceived(paidAmount);
  }

  void applyGstToAllLines(double? gstRate) {
    final items = _draft.items
        .map((item) => item.copyWith(
              gstRate: gstRate,
              clearGstRate: gstRate == null,
            ))
        .toList();
    _updateDraft(_draft.copyWith(items: items));
  }

  Future<bool> requestQuote() async {
    if (_amountReceivedError != null) {
      _quoteErrorMessage = _amountReceivedError;
      notifyListeners();
      return false;
    }
    _isQuoting = true;
    _quoteErrorMessage = null;
    notifyListeners();

    try {
      _quote = await _invoicesService.quoteInvoice(_draft);
      if (_draft.paymentMode == settlementModeCash) {
        _draft = _draft.copyWith(
          paidAmount: _quote!.totals.grandTotal,
          paymentState: 'TOTAL_PAID',
        );
      } else {
        final error = validateCreditAmountReceived(
          amount: _draft.paidAmount,
          grandTotal: _quote!.totals.grandTotal,
        );
        _amountReceivedError = error;
        if (error != null) {
          _quoteErrorMessage = error;
          return false;
        }
      }
      notifyListeners();
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
    if (_amountReceivedError != null) {
      _submitErrorMessage = _amountReceivedError;
      notifyListeners();
      return false;
    }
    if (_quote != null && _draft.paymentMode == settlementModeCash) {
      _draft = _draft.copyWith(
        paidAmount: _quote!.totals.grandTotal,
        paymentState: 'TOTAL_PAID',
      );
    }
    _isSubmitting = true;
    _submitErrorMessage = null;
    _createdInvoice = null;
    _createWarnings = const <InvoiceWarning>[];
    _requestId ??= generateRequestId();
    notifyListeners();

    try {
      final result = await _invoicesService.createInvoice(
          draft: _draft, requestId: _requestId!);
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
      if (_draft.paymentMode == settlementModeCredit) {
        _amountReceivedError = null;
      }
    }
    notifyListeners();
  }

  String _messageForError(Object error, {required bool forSubmit}) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException) {
      return forSubmit
          ? 'Connect to the server before saving the invoice'
          : 'Unable to reach the server';
    }
    if (error is HttpException) {
      return 'Unable to reach the server';
    }
    return forSubmit
        ? 'Unable to save invoice'
        : 'Unable to prepare invoice preview';
  }
}
