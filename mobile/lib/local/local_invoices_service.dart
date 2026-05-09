import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';
import '../models/invoice_summary.dart';
import '../services/invoices_service.dart';
import 'local_database.dart';
import 'local_customers_service.dart';

class LocalInvoicesService implements InvoicesService {
  LocalInvoicesService({required LocalDatabase database})
      : _database = database;

  static const _systemUserId = 'local-system-user';

  final LocalDatabase _database;

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async {
    final prepared = await _prepareInvoice(draft);
    return _toQuote(prepared);
  }

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) async {
    _validateRequestId(requestId);
    final existing = await (_database.select(_database.invoices)
          ..where((invoice) => invoice.requestId.equals(requestId)))
        .getSingleOrNull();
    if (existing != null) {
      final requestHash = _invoiceRequestHash(
        draft,
        existing.placeOfSupplyStateCode,
      );
      if (existing.requestHash != requestHash) {
        throw _idempotencyConflictError();
      }
      return CreateInvoiceResult(
        invoice: await _buildInvoiceDetail(existing.id),
        warnings: const <InvoiceWarning>[],
      );
    }

    final prepared = await _prepareInvoice(draft);
    final requestHash = _invoiceRequestHash(
      draft,
      prepared.placeOfSupplyStateCode,
    );
    final invoiceId = generateLocalUuid();
    await _ensureSystemUser();

    await _database.transaction(() async {
      final invoiceNumber = await _nextInvoiceNumber();
      final now = DateTime.now().toUtc().toIso8601String();
      await _database.into(_database.invoices).insert(
            InvoicesCompanion.insert(
              id: invoiceId,
              requestId: requestId,
              requestHash: requestHash,
              invoiceNumber: invoiceNumber,
              customerId: prepared.customer.id,
              customerName: prepared.customer.name,
              customerAddress: prepared.customer.address,
              customerState: Value(prepared.customer.state),
              customerStateCode: Value(prepared.customer.stateCode),
              customerPhone: Value(prepared.customer.phone),
              customerGstin: Value(prepared.customer.gstin),
              placeOfSupplyState: prepared.placeOfSupplyState,
              placeOfSupplyStateCode: prepared.placeOfSupplyStateCode,
              companyName: prepared.company.name,
              companyAddress: prepared.company.address,
              companyCity: prepared.company.city,
              companyState: prepared.company.state,
              companyStateCode: prepared.company.stateCode,
              companyGstin: Value(prepared.company.gstin),
              companyPhone: Value(prepared.company.phone),
              companyEmail: Value(prepared.company.email),
              companyBankName: Value(prepared.company.bankName),
              companyBankAccount: Value(prepared.company.bankAccount),
              companyBankIfsc: Value(prepared.company.bankIfsc),
              companyBankBranch: Value(prepared.company.bankBranch),
              companyJurisdiction: Value(prepared.company.jurisdiction),
              invoiceDate: prepared.invoiceDate,
              invoiceDatetime: Value(prepared.invoiceDatetime),
              taxRegime: prepared.taxRegime,
              status: 'ACTIVE',
              paymentState: Value(prepared.paymentState),
              paidAmount: Value(_normalizeDecimal(prepared.paidAmount)),
              paymentMode: prepared.paymentState,
              subtotal: _normalizeDecimal(prepared.totals.subtotal),
              discountTotal: _normalizeDecimal(prepared.totals.discountTotal),
              taxableTotal: _normalizeDecimal(prepared.totals.taxableTotal),
              gstTotal: _normalizeDecimal(prepared.totals.gstTotal),
              grandTotal: _normalizeDecimal(prepared.totals.grandTotal),
              notes: Value(_emptyToNull(draft.notes)),
              createdByUserId: _systemUserId,
              createdAt: now,
            ),
          );

      final stockQuantitiesByProductId = <String, double>{};
      for (final line in prepared.lines) {
        await _database.into(_database.invoiceItems).insert(
              InvoiceItemsCompanion.insert(
                id: generateLocalUuid(),
                invoiceId: invoiceId,
                productId: line.product.id,
                lineNumber: line.lineNumber,
                productName: line.product.itemName,
                productCode: line.product.itemNumber,
                productItemNumber: Value(line.product.itemNumber),
                productItemName: Value(line.product.itemName),
                productCategory: Value(line.product.category),
                productBuyerId: Value(line.product.buyerId),
                productCompanyName: Value(line.product.companyName),
                buyingPrice: Value(
                    _normalizeDecimal(double.parse(line.product.buyingPrice))),
                sellingPrice: Value(
                    _normalizeDecimal(double.parse(line.product.sellingPrice))),
                unit: Value(line.product.unit),
                company: line.product.companyName,
                category: line.product.category,
                quantity: _normalizeDecimal(line.item.quantity),
                pricingMode: line.item.pricingMode,
                enteredUnitPrice: _normalizeDecimal(line.enteredUnitPrice),
                unitPriceExclTax: _normalizeDecimal(line.unitPriceExclTax),
                unitPriceInclTax: _normalizeDecimal(line.unitPriceInclTax),
                gstRate: _normalizeDecimal(line.gstRate),
                cgstRate: _normalizeDecimal(line.cgstRate),
                sgstRate: _normalizeDecimal(line.sgstRate),
                igstRate: _normalizeDecimal(line.igstRate),
                discountPercent: _normalizeDecimal(line.discountPercent),
                discountAmount: _normalizeDecimal(line.discountAmount),
                taxableAmount: _normalizeDecimal(line.taxableAmount),
                gstAmount: _normalizeDecimal(line.gstAmount),
                cgstAmount: _normalizeDecimal(line.cgstAmount),
                sgstAmount: _normalizeDecimal(line.sgstAmount),
                igstAmount: _normalizeDecimal(line.igstAmount),
                lineTotal: _normalizeDecimal(line.lineTotal),
              ),
            );
        await _database.into(_database.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: generateLocalUuid(),
                productId: line.product.id,
                invoiceId: Value(invoiceId),
                movementType: 'INVOICE_SALE',
                quantityDelta: _normalizeDecimal(-line.item.quantity),
                reason: Value('Invoice $invoiceNumber'),
                createdByUserId: _systemUserId,
                createdAt: now,
              ),
            );
        stockQuantitiesByProductId.update(
          line.product.id,
          (quantity) => quantity + line.item.quantity,
          ifAbsent: () => line.item.quantity,
        );
      }

      for (final entry in stockQuantitiesByProductId.entries) {
        final product = prepared.lines
            .firstWhere((line) => line.product.id == entry.key)
            .product;
        await (_database.update(_database.products)
              ..where((product) => product.id.equals(entry.key)))
            .write(
          ProductsCompanion(
            quantityOnHand: Value(_normalizeDecimal(
              double.parse(product.quantityOnHand) - entry.value,
            )),
            updatedAt: Value(now),
          ),
        );
      }

      await _database.into(_database.customerTransactions).insert(
            CustomerTransactionsCompanion.insert(
              id: generateLocalUuid(),
              customerId: prepared.customer.id,
              invoiceId: Value(invoiceId),
              entryType: 'CREDIT_SALE',
              amount: _normalizeDecimal(prepared.totals.grandTotal),
              occurredOn: prepared.invoiceDate,
              notes: Value('Invoice $invoiceNumber'),
              createdByUserId: _systemUserId,
              createdAt: now,
            ),
          );
      if (prepared.paidAmount > 0) {
        await _database.into(_database.customerTransactions).insert(
              CustomerTransactionsCompanion.insert(
                id: generateLocalUuid(),
                customerId: prepared.customer.id,
                invoiceId: Value(invoiceId),
                entryType: 'COLLECTION',
                amount: _normalizeDecimal(prepared.paidAmount),
                occurredOn: prepared.invoiceDate,
                notes: Value('Invoice $invoiceNumber collection'),
                createdByUserId: _systemUserId,
                createdAt: now,
              ),
            );
      }
    });

    return CreateInvoiceResult(
      invoice: await _buildInvoiceDetail(invoiceId),
      warnings: prepared.warnings,
    );
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) async {
    final query = _database.select(_database.invoices);
    if (status != null) {
      query.where((invoice) => invoice.status.equals(status));
    }
    query.orderBy([
      (invoice) => OrderingTerm.desc(invoice.invoiceNumber),
    ]);
    final invoices = await query.get();
    return invoices.map(_toSummary).toList();
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) {
    return _buildInvoiceDetail(invoiceId);
  }

  @override
  Future<InvoiceDetail> cancelInvoice({
    required String invoiceId,
    required String reason,
  }) async {
    final invoice = await (_database.select(_database.invoices)
          ..where((invoice) => invoice.id.equals(invoiceId)))
        .getSingleOrNull();
    if (invoice == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Invoice not found',
        statusCode: 404,
      );
    }
    if (invoice.status == 'CANCELED') {
      throw const ApiError(
        code: 'INVOICE_ALREADY_CANCELED',
        message: 'Invoice is already canceled',
        statusCode: 409,
      );
    }
    await _ensureSystemUser();
    final items = await (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.equals(invoiceId))
          ..orderBy([(item) => OrderingTerm.asc(item.lineNumber)]))
        .get();
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();
    await _database.transaction(() async {
      await (_database.update(_database.invoices)
            ..where((invoice) => invoice.id.equals(invoiceId)))
          .write(
        InvoicesCompanion(
          status: const Value('CANCELED'),
          cancelRequestId: Value(generateLocalUuid()),
          cancelRequestHash: Value(_hash(<String, dynamic>{
            'invoice_id': invoiceId,
            'cancel_reason': reason,
          })),
          canceledByUserId: const Value(_systemUserId),
          cancelReason: Value(reason),
          canceledAt: Value(nowIso),
        ),
      );
      for (final item in items) {
        final product = await (_database.select(_database.products)
              ..where((product) => product.id.equals(item.productId)))
            .getSingle();
        final quantity = double.parse(item.quantity);
        await (_database.update(_database.products)
              ..where((product) => product.id.equals(item.productId)))
            .write(
          ProductsCompanion(
            quantityOnHand: Value(_normalizeDecimal(
              double.parse(product.quantityOnHand) + quantity,
            )),
            updatedAt: Value(nowIso),
          ),
        );
        await _database.into(_database.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: generateLocalUuid(),
                productId: item.productId,
                invoiceId: Value(invoiceId),
                movementType: 'INVOICE_CANCEL_REVERSAL',
                quantityDelta: _normalizeDecimal(quantity),
                reason: Value('Cancel invoice ${invoice.invoiceNumber}'),
                createdByUserId: _systemUserId,
                createdAt: nowIso,
              ),
            );
      }
      await _database.into(_database.customerTransactions).insert(
            CustomerTransactionsCompanion.insert(
              id: generateLocalUuid(),
              customerId: invoice.customerId,
              invoiceId: Value(invoiceId),
              entryType: 'INVOICE_CANCEL_REVERSAL',
              amount: invoice.grandTotal,
              occurredOn: nowIso.substring(0, 10),
              notes: Value('Cancel invoice ${invoice.invoiceNumber}'),
              createdByUserId: _systemUserId,
              createdAt: nowIso,
            ),
          );
      final paidAmount = double.parse(invoice.paidAmount);
      if (paidAmount > 0) {
        await _database.into(_database.customerTransactions).insert(
              CustomerTransactionsCompanion.insert(
                id: generateLocalUuid(),
                customerId: invoice.customerId,
                invoiceId: Value(invoiceId),
                entryType: 'COLLECTION_REVERSAL',
                amount: invoice.paidAmount,
                occurredOn: nowIso.substring(0, 10),
                notes:
                    Value('Cancel invoice ${invoice.invoiceNumber} collection'),
                createdByUserId: _systemUserId,
                createdAt: nowIso,
              ),
            );
      }
    });
    return _buildInvoiceDetail(invoiceId);
  }

  Future<_PreparedInvoice> _prepareInvoice(InvoiceDraft draft) async {
    _validatePaymentMode(draft.paymentState);
    final draftCustomer = draft.customer;
    if (draftCustomer == null) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'customer_id is required',
        statusCode: 400,
      );
    }
    final customer = await (_database.select(_database.customers)
          ..where((customer) => customer.id.equals(draftCustomer.id)))
        .getSingleOrNull();
    if (customer == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Customer not found',
        statusCode: 404,
      );
    }
    if (!customer.isActive) {
      throw const ApiError(
        code: 'CUSTOMER_ARCHIVED',
        message: 'Archived customer cannot be invoiced',
        statusCode: 400,
      );
    }
    final company = await (_database.select(_database.companyProfiles)
          ..where((profile) => profile.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (company == null || company.state.isEmpty || company.stateCode.isEmpty) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'Complete company profile state metadata before invoicing',
        statusCode: 400,
      );
    }
    _validateStateMetadata(
      state: company.state,
      stateCode: company.stateCode,
      message: 'Company profile state and state_code do not match',
    );
    if (_emptyToNull(draft.placeOfSupplyStateCode) == null &&
        customer.state != null &&
        customer.stateCode != null) {
      _validateStateMetadata(
        state: customer.state!,
        stateCode: customer.stateCode!,
        message: 'Customer state and state_code do not match',
      );
    }

    final placeOfSupplyStateCode = _resolvePlaceOfSupplyStateCode(
      customer,
      draft.placeOfSupplyStateCode,
    );
    final placeOfSupplyState = _stateName(placeOfSupplyStateCode);
    final taxRegime = _normalizeStateCode(company.stateCode) ==
            _normalizeStateCode(placeOfSupplyStateCode)
        ? 'INTRA_STATE'
        : 'INTER_STATE';
    final invoiceDatetime = _resolveInvoiceDatetime(draft);
    final invoiceDate = invoiceDatetime.substring(0, 10);
    final lines = <_PreparedLine>[];
    final warnings = <InvoiceWarning>[];
    final consumedQuantities = <String, double>{};
    var subtotal = 0.0;
    var discountTotal = 0.0;
    var taxableTotal = 0.0;
    var gstTotal = 0.0;
    var grandTotal = 0.0;

    for (var index = 0; index < draft.items.length; index += 1) {
      final item = draft.items[index];
      final draftProduct = item.product;
      if (draftProduct == null) {
        throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'product_id is required',
          statusCode: 400,
        );
      }
      final product = await (_database.select(_database.products)
            ..where((product) => product.id.equals(draftProduct.id)))
          .getSingleOrNull();
      if (product == null) {
        throw const ApiError(
          code: 'NOT_FOUND',
          message: 'One or more products were not found',
          statusCode: 404,
        );
      }
      if (!product.isActive) {
        throw const ApiError(
          code: 'PRODUCT_ARCHIVED',
          message: 'Archived product cannot be invoiced',
          statusCode: 400,
        );
      }
      final line = _normalizeLine(
        product: product,
        item: item,
        taxRegime: taxRegime,
        lineNumber: index + 1,
      );
      lines.add(line);
      subtotal += line.taxableAmount + line.discountAmount;
      discountTotal += line.discountAmount;
      taxableTotal += line.taxableAmount;
      gstTotal += line.gstAmount;
      grandTotal += line.lineTotal;
      final consumed = (consumedQuantities[product.id] ?? 0) + item.quantity;
      consumedQuantities[product.id] = consumed;
      final projectedQuantity = double.parse(product.quantityOnHand) - consumed;
      if (projectedQuantity < 0) {
        warnings.add(InvoiceWarning(
          code: 'NEGATIVE_STOCK',
          message: '${product.itemName} will go negative to '
              '${_normalizeDecimal(projectedQuantity)}',
        ));
      }
    }

    final paymentState = _resolvePaymentState(draft);
    final paidAmount = _resolvePaidAmount(
      paymentState,
      draft.paidAmount,
      _roundMoney(grandTotal),
    );
    return _PreparedInvoice(
      customer: customer,
      company: company,
      invoiceDatetime: invoiceDatetime,
      invoiceDate: invoiceDate,
      paymentState: paymentState,
      paidAmount: paidAmount,
      placeOfSupplyState: placeOfSupplyState,
      placeOfSupplyStateCode: placeOfSupplyStateCode,
      taxRegime: taxRegime,
      lines: lines,
      warnings: warnings,
      totals: InvoiceTotals(
        subtotal: _roundMoney(subtotal),
        discountTotal: _roundMoney(discountTotal),
        taxableTotal: _roundMoney(taxableTotal),
        gstTotal: _roundMoney(gstTotal),
        grandTotal: _roundMoney(grandTotal),
      ),
    );
  }

  _PreparedLine _normalizeLine({
    required Product product,
    required InvoiceDraftItem item,
    required String taxRegime,
    required int lineNumber,
  }) {
    final enteredUnitPrice = _roundMoney(
      item.unitPrice ?? double.parse(product.sellingPrice),
    );
    final gstRate = _roundRate(item.gstRate ?? double.parse(product.gstRate));
    final discountPercent = _roundRate(item.discountPercent);
    late final double unitPriceExclTax;
    late final double unitPriceInclTax;
    switch (item.pricingMode) {
      case 'PRE_TAX':
        unitPriceExclTax = enteredUnitPrice;
        unitPriceInclTax = _roundMoney(
          unitPriceExclTax * (1 + (gstRate / 100)),
        );
      case 'TAX_INCLUSIVE':
        unitPriceInclTax = enteredUnitPrice;
        unitPriceExclTax = _roundMoney(
          unitPriceInclTax / (1 + (gstRate / 100)),
        );
      default:
        throw const ApiError(
          code: 'VALIDATION_ERROR',
          message: 'Unsupported pricing mode',
          statusCode: 400,
        );
    }
    final lineSubtotal = _roundMoney(item.quantity * unitPriceExclTax);
    final discountAmount = _roundMoney(lineSubtotal * (discountPercent / 100));
    late final double taxableAmount;
    late final double gstAmount;
    late final double lineTotal;
    if (item.pricingMode == 'TAX_INCLUSIVE') {
      final grossLineTotal = _roundMoney(item.quantity * unitPriceInclTax);
      final grossDiscountAmount =
          _roundMoney(grossLineTotal * (discountPercent / 100));
      lineTotal = _roundMoney(grossLineTotal - grossDiscountAmount);
      taxableAmount = _roundMoney(lineTotal / (1 + (gstRate / 100)));
      gstAmount = _roundMoney(lineTotal - taxableAmount);
    } else {
      taxableAmount = _roundMoney(lineSubtotal - discountAmount);
      gstAmount = _roundMoney(taxableAmount * (gstRate / 100));
      lineTotal = _roundMoney(taxableAmount + gstAmount);
    }
    final rates = _splitGstRate(gstRate, taxRegime);
    final cgstAmount = taxRegime == 'INTER_STATE'
        ? 0.0
        : _roundMoney(taxableAmount * (rates.cgst / 100));
    final sgstAmount =
        taxRegime == 'INTER_STATE' ? 0.0 : _roundMoney(gstAmount - cgstAmount);
    final igstAmount = taxRegime == 'INTER_STATE' ? gstAmount : 0.0;
    return _PreparedLine(
      product: product,
      item: item,
      lineNumber: lineNumber,
      enteredUnitPrice: enteredUnitPrice,
      unitPriceExclTax: unitPriceExclTax,
      unitPriceInclTax: unitPriceInclTax,
      gstRate: gstRate,
      cgstRate: rates.cgst,
      sgstRate: rates.sgst,
      igstRate: rates.igst,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      lineTotal: lineTotal,
    );
  }

  Future<InvoiceDetail> _buildInvoiceDetail(String invoiceId) async {
    final invoice = await (_database.select(_database.invoices)
          ..where((invoice) => invoice.id.equals(invoiceId)))
        .getSingleOrNull();
    if (invoice == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Invoice not found',
        statusCode: 404,
      );
    }
    final items = await (_database.select(_database.invoiceItems)
          ..where((item) => item.invoiceId.equals(invoiceId))
          ..orderBy([(item) => OrderingTerm.asc(item.lineNumber)]))
        .get();
    return InvoiceDetail(
      id: invoice.id,
      customerId: invoice.customerId,
      invoiceNumber: invoice.invoiceNumber.toString(),
      status: invoice.status,
      paymentState: invoice.paymentState,
      paymentMode: invoice.paymentMode,
      paidAmount: double.parse(invoice.paidAmount),
      customerName: invoice.customerName,
      invoiceDate: invoice.invoiceDate,
      invoiceDatetime: invoice.invoiceDatetime,
      grandTotal: double.parse(invoice.grandTotal),
      notes: invoice.notes,
      cancelReason: invoice.cancelReason,
      items: items
          .map(
            (item) => InvoiceDetailItem(
              productName: item.productName,
              productItemNumber: item.productItemNumber,
              productItemName: item.productItemName,
              productCategory: item.productCategory,
              productBuyerId: item.productBuyerId,
              productCompanyName: item.productCompanyName,
              buyingPrice: double.parse(item.buyingPrice),
              sellingPrice: double.parse(item.sellingPrice),
              unit: item.unit,
              quantity: double.parse(item.quantity),
              lineTotal: double.parse(item.lineTotal),
            ),
          )
          .toList(),
    );
  }

  InvoiceSummary _toSummary(Invoice invoice) {
    return InvoiceSummary(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber.toString(),
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceDate: invoice.invoiceDate,
      status: invoice.status,
      paymentState: invoice.paymentState,
      paymentMode: invoice.paymentMode,
      grandTotal: double.parse(invoice.grandTotal),
    );
  }

  InvoiceQuote _toQuote(_PreparedInvoice prepared) {
    return InvoiceQuote(
      placeOfSupplyState: prepared.placeOfSupplyState,
      placeOfSupplyStateCode: prepared.placeOfSupplyStateCode,
      taxRegime: prepared.taxRegime,
      items: prepared.lines
          .map(
            (line) => InvoiceQuoteItem(
              productId: line.product.id,
              productItemNumber: line.product.itemNumber,
              productItemName: line.product.itemName,
              productCategory: line.product.category,
              productBuyerId: line.product.buyerId,
              productCompanyName: line.product.companyName,
              buyingPrice: double.parse(line.product.buyingPrice),
              sellingPrice: double.parse(line.product.sellingPrice),
              unit: line.product.unit,
              quantity: line.item.quantity,
              pricingMode: line.item.pricingMode,
              enteredUnitPrice: line.enteredUnitPrice,
              unitPriceExclTax: line.unitPriceExclTax,
              unitPriceInclTax: line.unitPriceInclTax,
              gstRate: line.gstRate,
              gstAmount: line.gstAmount,
              lineTotal: line.lineTotal,
            ),
          )
          .toList(),
      totals: prepared.totals,
      warnings: prepared.warnings,
    );
  }

  Future<int> _nextInvoiceNumber() async {
    final invoices = await _database.select(_database.invoices).get();
    if (invoices.isEmpty) {
      return 1;
    }
    return invoices
            .map((invoice) => invoice.invoiceNumber)
            .reduce((left, right) => left > right ? left : right) +
        1;
  }

  Future<void> _ensureSystemUser() async {
    final existing = await (_database.select(_database.localUsers)
          ..where((user) => user.id.equals(_systemUserId)))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.into(_database.localUsers).insert(
          LocalUsersCompanion.insert(
            id: _systemUserId,
            username: 'local-system',
            passwordHash: 'not-used',
            displayName: const Value('Local System'),
            salt: 'not-used',
            passwordHashVersion: 1,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  void _validatePaymentMode(String paymentMode) {
    if (paymentMode == 'CREDIT' ||
        paymentMode == 'TOTAL_PAID' ||
        paymentMode == 'PARTIAL_PAID' ||
        paymentMode == 'PAID') {
      return;
    }
    throw const ApiError(
      code: 'VALIDATION_ERROR',
      message: 'payment_state must be CREDIT, TOTAL_PAID, or PARTIAL_PAID',
      statusCode: 400,
    );
  }

  String _resolvePaymentState(InvoiceDraft draft) {
    if (draft.paymentState == 'CREDIT' ||
        draft.paymentState == 'TOTAL_PAID' ||
        draft.paymentState == 'PARTIAL_PAID') {
      return draft.paymentState;
    }
    if (draft.paymentMode == 'PAID') {
      return 'TOTAL_PAID';
    }
    if (draft.paymentMode == 'CREDIT') {
      return 'CREDIT';
    }
    _validatePaymentMode(draft.paymentState);
    return draft.paymentState;
  }

  double _resolvePaidAmount(
    String paymentState,
    double paidAmount,
    double grandTotal,
  ) {
    switch (paymentState) {
      case 'CREDIT':
        if (paidAmount != 0) {
          throw const ApiError(
            code: 'VALIDATION_ERROR',
            message: 'paid_amount must be 0 for CREDIT invoices',
            statusCode: 400,
          );
        }
        return 0;
      case 'TOTAL_PAID':
        if (paidAmount != 0 && _roundMoney(paidAmount) != grandTotal) {
          throw const ApiError(
            code: 'VALIDATION_ERROR',
            message:
                'paid_amount must equal grand_total for TOTAL_PAID invoices',
            statusCode: 400,
          );
        }
        return grandTotal;
      case 'PARTIAL_PAID':
        if (paidAmount <= 0 || paidAmount >= grandTotal) {
          throw const ApiError(
            code: 'VALIDATION_ERROR',
            message:
                'paid_amount must be greater than zero and less than grand_total for PARTIAL_PAID invoices',
            statusCode: 400,
          );
        }
        return _roundMoney(paidAmount);
    }
    _validatePaymentMode(paymentState);
    return paidAmount;
  }

  String _resolveInvoiceDatetime(InvoiceDraft draft) {
    final value = _emptyToNull(draft.invoiceDatetime);
    if (value != null) {
      return value;
    }
    final date = _emptyToNull(draft.invoiceDate);
    if (date != null) {
      return '${date}T00:00:00.000Z';
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  void _validateStateMetadata({
    required String state,
    required String stateCode,
    required String message,
  }) {
    final canonicalState = _stateName(stateCode);
    if (state.trim().toLowerCase() != canonicalState.toLowerCase()) {
      throw ApiError(
        code: 'VALIDATION_ERROR',
        message: message,
        statusCode: 400,
      );
    }
  }

  String _resolvePlaceOfSupplyStateCode(Customer customer, String? provided) {
    if (provided != null && provided.trim().isNotEmpty) {
      return _normalizeStateCode(provided);
    }
    if (customer.stateCode != null && customer.stateCode!.isNotEmpty) {
      return _normalizeStateCode(customer.stateCode!);
    }
    throw const ApiError(
      code: 'VALIDATION_ERROR',
      message: 'place_of_supply_state_code is required',
      statusCode: 400,
    );
  }

  String _invoiceRequestHash(InvoiceDraft draft, String resolvedStateCode) {
    final payload = <String, dynamic>{
      'customer_id': draft.customer?.id,
      'invoice_datetime': _emptyToNull(draft.invoiceDatetime),
      'invoice_date': draft.invoiceDate,
      'payment_state': draft.paymentState,
      'paid_amount': draft.paidAmount.toStringAsFixed(2),
      'place_of_supply_state_code': resolvedStateCode,
      'notes': _emptyToNull(draft.notes),
      'items': draft.items
          .map((item) => <String, dynamic>{
                'product_id': item.product?.id,
                'quantity': item.quantity.toStringAsFixed(3),
                'pricing_mode': item.pricingMode,
                'unit_price': (item.unitPrice ?? 0).toStringAsFixed(2),
                'gst_rate': (item.gstRate ?? 0).toStringAsFixed(2),
                'discount_percent': item.discountPercent.toStringAsFixed(2),
              })
          .toList(),
    };
    return _hash(payload);
  }

  String _hash(Map<String, dynamic> payload) {
    final sorted = Map<String, dynamic>.fromEntries(
      payload.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
    return sha256.convert(utf8.encode(jsonEncode(sorted))).toString();
  }

  void _validateRequestId(String requestId) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuidPattern.hasMatch(requestId)) {
      throw const ApiError(
        code: 'VALIDATION_ERROR',
        message: 'request_id must be a valid UUID',
        statusCode: 400,
      );
    }
  }

  ApiError _idempotencyConflictError() {
    return const ApiError(
      code: 'IDEMPOTENCY_CONFLICT',
      message: 'request_id already used with different payload',
      statusCode: 409,
    );
  }

  String _normalizeStateCode(String stateCode) =>
      stateCode.trim().padLeft(2, '0');

  String _stateName(String stateCode) {
    final states = <String, String>{
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '25': 'Daman and Diu',
      '26': 'Dadra and Nagar Haveli and Daman and Diu',
      '27': 'Maharashtra',
      '28': 'Andhra Pradesh (Old)',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh',
      '38': 'Ladakh',
      '97': 'Other Territory',
      '99': 'Centre Jurisdiction',
    };
    final normalized = _normalizeStateCode(stateCode);
    final state = states[normalized];
    if (state == null) {
      throw ApiError(
        code: 'VALIDATION_ERROR',
        message: 'Unknown state code: $stateCode',
        statusCode: 400,
      );
    }
    return state;
  }

  _GstRates _splitGstRate(double gstRate, String taxRegime) {
    final normalized = _roundRate(gstRate);
    if (taxRegime == 'INTER_STATE') {
      return _GstRates(cgst: 0, sgst: 0, igst: normalized);
    }
    final cgst = _roundRate(normalized / 2);
    return _GstRates(cgst: cgst, sgst: _roundRate(normalized - cgst), igst: 0);
  }

  double _roundMoney(double value) => (value * 100).round() / 100;

  double _roundRate(double value) => (value * 100).round() / 100;

  String _normalizeDecimal(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Decimal value must be finite');
    }
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}

class _PreparedInvoice {
  const _PreparedInvoice({
    required this.customer,
    required this.company,
    required this.invoiceDatetime,
    required this.invoiceDate,
    required this.paymentState,
    required this.paidAmount,
    required this.placeOfSupplyState,
    required this.placeOfSupplyStateCode,
    required this.taxRegime,
    required this.lines,
    required this.warnings,
    required this.totals,
  });

  final Customer customer;
  final CompanyProfile company;
  final String invoiceDatetime;
  final String invoiceDate;
  final String paymentState;
  final double paidAmount;
  final String placeOfSupplyState;
  final String placeOfSupplyStateCode;
  final String taxRegime;
  final List<_PreparedLine> lines;
  final List<InvoiceWarning> warnings;
  final InvoiceTotals totals;
}

class _PreparedLine {
  const _PreparedLine({
    required this.product,
    required this.item,
    required this.lineNumber,
    required this.enteredUnitPrice,
    required this.unitPriceExclTax,
    required this.unitPriceInclTax,
    required this.gstRate,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.lineTotal,
  });

  final Product product;
  final InvoiceDraftItem item;
  final int lineNumber;
  final double enteredUnitPrice;
  final double unitPriceExclTax;
  final double unitPriceInclTax;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double discountPercent;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double lineTotal;
}

class _GstRates {
  const _GstRates({required this.cgst, required this.sgst, required this.igst});

  final double cgst;
  final double sgst;
  final double igst;
}
