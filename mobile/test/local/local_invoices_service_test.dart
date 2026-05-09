import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

void main() {
  late db.LocalDatabase database;
  late LocalCompanyProfileService companyService;
  late LocalProductsService productsService;
  late LocalCustomersService customersService;
  late LocalInvoicesService invoicesService;
  late Customer customer;
  late Product product;

  setUp(() async {
    database = db.LocalDatabase.memory();
    companyService = LocalCompanyProfileService(database: database);
    productsService = LocalProductsService(database: database);
    customersService = LocalCustomersService(database: database);
    invoicesService = LocalInvoicesService(database: database);
    await _seedLocalUser(database);
    await companyService.upsertCompanyProfile(_companyInput());
    customer = await customersService.createCustomer(_customerInput());
    product = await productsService.createProduct(_productInput());
  });

  tearDown(() async {
    await database.close();
  });

  test('quote uses line selling price inclusive of GST', () async {
    final quote = await invoicesService.quoteInvoice(_draft(
      customer: customer,
      product: product,
      quantity: 2,
    ));

    expect(quote.placeOfSupplyState, 'Maharashtra');
    expect(quote.placeOfSupplyStateCode, '27');
    expect(quote.taxRegime, 'INTRA_STATE');
    expect(quote.items, hasLength(1));
    expect(quote.items.single.productId, product.id);
    expect(quote.items.single.productItemNumber, 'PEN-1');
    expect(quote.items.single.productItemName, 'Blue Pen');
    expect(quote.items.single.productCategory, 'Pens');
    expect(quote.items.single.productCompanyName, 'Acme');
    expect(quote.items.single.buyingPrice, 80);
    expect(quote.items.single.sellingPrice, 118);
    expect(quote.items.single.quantity, 2);
    expect(quote.items.single.pricingMode, 'TAX_INCLUSIVE');
    expect(quote.items.single.enteredUnitPrice, 118);
    expect(quote.items.single.unitPriceExclTax, 100);
    expect(quote.items.single.unitPriceInclTax, 118);
    expect(quote.items.single.gstRate, 18);
    expect(quote.items.single.lineTotal, 236);
    expect(quote.totals.subtotal, 200);
    expect(quote.totals.discountTotal, 0);
    expect(quote.totals.taxableTotal, 200);
    expect(quote.totals.gstTotal, 36);
    expect(quote.totals.grandTotal, 236);
  });

  test('quote allows edited selling price', () async {
    final quote = await invoicesService.quoteInvoice(_draftWithItems(
      customer: customer,
      items: <InvoiceDraftItem>[
        InvoiceDraftItem(
          product: product,
          quantity: 2,
          unitPrice: 236,
        ),
      ],
    ));

    expect(quote.items.single.enteredUnitPrice, 236);
    expect(quote.items.single.unitPriceExclTax, 200);
    expect(quote.items.single.lineTotal, 472);
    expect(quote.totals.grandTotal, 472);
  });

  test('quote allows edited line GST rate', () async {
    final quote = await invoicesService.quoteInvoice(_draftWithItems(
      customer: customer,
      items: <InvoiceDraftItem>[
        InvoiceDraftItem(
          product: product,
          quantity: 2,
          gstRate: 12,
        ),
      ],
    ));

    expect(quote.items.single.enteredUnitPrice, 118);
    expect(quote.items.single.gstRate, 12);
    expect(quote.items.single.unitPriceExclTax, 105.36);
    expect(quote.items.single.gstAmount, 25.29);
    expect(quote.items.single.lineTotal, 236);
    expect(quote.totals.grandTotal, 236);
  });

  test('quote stores product, buyer, and company snapshots', () async {
    final quote = await invoicesService.quoteInvoice(_draft(
      customer: customer,
      product: product,
      quantity: 1,
    ));

    final line = quote.items.single;
    expect(line.productItemNumber, 'PEN-1');
    expect(line.productItemName, 'Blue Pen');
    expect(line.productCategory, 'Pens');
    expect(line.productBuyerId, isNull);
    expect(line.productCompanyName, 'Acme');
    expect(line.buyingPrice, 80);
    expect(line.sellingPrice, 118);
  });

  test('quote supports optional unit', () async {
    final boxedProduct = await productsService.createProduct(
      _productInput(
          itemNumber: 'PEN-BOX', itemName: 'Blue Pen Box', unit: 'box'),
    );

    final quote = await invoicesService.quoteInvoice(_draft(
      customer: customer,
      product: boxedProduct,
      quantity: 1,
    ));

    expect(quote.items.single.unit, 'box');
  });

  test('quote warns when inclusive sale would make stock negative', () async {
    final quote = await invoicesService.quoteInvoice(_draft(
      customer: customer,
      product: product,
      quantity: 6,
      discountPercent: 10,
    ));

    expect(quote.items.single.lineTotal, 637.2);
    expect(quote.totals.grandTotal, 637.2);
    expect(quote.warnings, hasLength(1));
    expect(quote.warnings.single.code, 'NEGATIVE_STOCK');
  });

  test('CREDIT creates full customer khata debit', () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(1),
    );

    expect(result.warnings, isEmpty);
    expect(result.invoice.id, isNotEmpty);
    expect(result.invoice.invoiceNumber, '1');
    expect(result.invoice.status, 'ACTIVE');
    expect(result.invoice.paymentState, 'CREDIT');
    expect(result.invoice.paymentMode, 'CREDIT');
    expect(result.invoice.paidAmount, 0);
    expect(result.invoice.customerName, 'Acme Stores');
    expect(result.invoice.invoiceDate, '2026-01-10');
    expect(result.invoice.invoiceDatetime, '2026-01-10T15:30:00.000Z');
    expect(result.invoice.grandTotal, 236);
    expect(result.invoice.items.single.productName, 'Blue Pen');
    expect(result.invoice.items.single.productItemNumber, 'PEN-1');
    expect(result.invoice.items.single.productItemName, 'Blue Pen');
    expect(result.invoice.items.single.productCategory, 'Pens');
    expect(result.invoice.items.single.productCompanyName, 'Acme');
    expect(result.invoice.items.single.buyingPrice, 80);
    expect(result.invoice.items.single.sellingPrice, 118);
    expect(result.invoice.items.single.unit, isNull);
    expect(result.invoice.items.single.quantity, 2);
    expect(result.invoice.items.single.lineTotal, 236);

    final storedProduct = await database.select(database.products).getSingle();
    expect(storedProduct.quantityOnHand, '3');

    final movement = await database.select(database.stockMovements).getSingle();
    expect(movement.invoiceId, result.invoice.id);
    expect(movement.movementType, 'INVOICE_SALE');
    expect(movement.quantityDelta, '-2');
    expect(movement.reason, 'Invoice 1');

    final transaction =
        await database.select(database.customerTransactions).getSingle();
    expect(transaction.customerId, customer.id);
    expect(transaction.invoiceId, result.invoice.id);
    expect(transaction.entryType, 'CREDIT_SALE');
    expect(transaction.amount, '236');
    expect(transaction.occurredOn, '2026-01-10');
    expect(transaction.notes, 'Invoice 1');

    final storedInvoice = await database.select(database.invoices).getSingle();
    expect(storedInvoice.requestId, _uuid(1));
    expect(storedInvoice.customerName, 'Acme Stores');
    expect(storedInvoice.companyName, 'Khata Traders');
    expect(storedInvoice.companyStateCode, '27');
    expect(storedInvoice.paymentState, 'CREDIT');
    expect(storedInvoice.paidAmount, '0');
    expect(storedInvoice.invoiceDatetime, '2026-01-10T15:30:00.000Z');

    final storedItem = await database.select(database.invoiceItems).getSingle();
    expect(storedItem.productItemNumber, 'PEN-1');
    expect(storedItem.productItemName, 'Blue Pen');
    expect(storedItem.productCategory, 'Pens');
    expect(storedItem.productBuyerId, isNull);
    expect(storedItem.productCompanyName, 'Acme');
    expect(storedItem.buyingPrice, '80');
    expect(storedItem.sellingPrice, '118');
    expect(storedItem.unit, isNull);
  });

  test('TOTAL_PAID creates full debit and full collection', () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(
        customer: customer,
        product: product,
        quantity: 2,
        paymentState: 'TOTAL_PAID',
      ),
      requestId: _uuid(21),
    );

    expect(result.invoice.paymentState, 'TOTAL_PAID');
    expect(result.invoice.paidAmount, 236);
    final transactions =
        await database.select(database.customerTransactions).get();
    expect(
      transactions
          .map((transaction) => (transaction.entryType, transaction.amount)),
      <(String, String)>[('CREDIT_SALE', '236'), ('COLLECTION', '236')],
    );
  });

  test('PARTIAL_PAID creates full debit and partial collection', () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(
        customer: customer,
        product: product,
        quantity: 2,
        paymentState: 'PARTIAL_PAID',
        paidAmount: 100,
      ),
      requestId: _uuid(22),
    );

    expect(result.invoice.paymentState, 'PARTIAL_PAID');
    expect(result.invoice.paidAmount, 100);
    final transactions =
        await database.select(database.customerTransactions).get();
    expect(
      transactions
          .map((transaction) => (transaction.entryType, transaction.amount)),
      <(String, String)>[('CREDIT_SALE', '236'), ('COLLECTION', '100')],
    );
  });

  test('accumulates stock reduction for duplicate product lines', () async {
    final result = await invoicesService.createInvoice(
      draft: _draftWithItems(
        customer: customer,
        items: <InvoiceDraftItem>[
          InvoiceDraftItem(
            product: product,
            quantity: 1.5,
            unitPrice: 118,
          ),
          InvoiceDraftItem(
            product: product,
            quantity: 2,
            unitPrice: 118,
          ),
        ],
      ),
      requestId: _uuid(12),
    );

    expect(result.invoice.items, hasLength(2));
    expect(result.invoice.items.map((item) => item.quantity), <double>[1.5, 2]);
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '1.5');
    expect(await database.select(database.invoiceItems).get(), hasLength(2));
    expect(await database.select(database.stockMovements).get(), hasLength(2));
  });

  test('cancellation restores combined stock for duplicate product lines',
      () async {
    final result = await invoicesService.createInvoice(
      draft: _draftWithItems(
        customer: customer,
        items: <InvoiceDraftItem>[
          InvoiceDraftItem(
            product: product,
            quantity: 1.5,
            unitPrice: 118,
          ),
          InvoiceDraftItem(
            product: product,
            quantity: 2,
            unitPrice: 118,
          ),
        ],
      ),
      requestId: _uuid(13),
    );

    await invoicesService.cancelInvoice(
      invoiceId: result.invoice.id,
      reason: 'Duplicate-line return',
    );

    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '5');
    expect(await database.select(database.stockMovements).get(), hasLength(4));
  });

  test('returns idempotent create result and rejects request ID conflicts',
      () async {
    final draft = _draft(customer: customer, product: product, quantity: 1);

    final first = await invoicesService.createInvoice(
      draft: draft,
      requestId: _uuid(2),
    );
    final second = await invoicesService.createInvoice(
      draft: draft,
      requestId: _uuid(2),
    );

    expect(second.invoice.id, first.invoice.id);
    expect(await database.select(database.invoices).get(), hasLength(1));
    expect(await database.select(database.stockMovements).get(), hasLength(1));
    await expectLater(
      () => invoicesService.createInvoice(
        draft: _draft(customer: customer, product: product, quantity: 2),
        requestId: _uuid(2),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
  });

  test('idempotent replay uses resolved paid amount and invoice datetime',
      () async {
    final dateOnlyDraft = _draft(
      customer: customer,
      product: product,
      quantity: 2,
      paymentState: 'TOTAL_PAID',
      invoiceDatetime: null,
    );

    final first = await invoicesService.createInvoice(
      draft: dateOnlyDraft,
      requestId: _uuid(23),
    );
    final second = await invoicesService.createInvoice(
      draft: _draft(
        customer: customer,
        product: product,
        quantity: 2,
        paymentState: 'TOTAL_PAID',
        paidAmount: 236,
        invoiceDatetime: '2026-01-10T00:00:00.000Z',
      ),
      requestId: _uuid(23),
    );

    expect(second.invoice.id, first.invoice.id);
    expect(second.invoice.paymentState, 'TOTAL_PAID');
    expect(second.invoice.paidAmount, 236);
    expect(second.invoice.invoiceDatetime, '2026-01-10T00:00:00.000Z');
    expect(await database.select(database.invoices).get(), hasLength(1));
    expect(await database.select(database.customerTransactions).get(),
        hasLength(2));
  });

  test('legacy PAID payment mode resolves to TOTAL_PAID before validation',
      () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(
        customer: customer,
        product: product,
        quantity: 2,
        paymentMode: 'PAID',
      ),
      requestId: _uuid(24),
    );

    expect(result.invoice.paymentState, 'TOTAL_PAID');
    expect(result.invoice.paidAmount, 236);
    final transactions =
        await database.select(database.customerTransactions).get();
    expect(
      transactions
          .map((transaction) => (transaction.entryType, transaction.amount)),
      <(String, String)>[('CREDIT_SALE', '236'), ('COLLECTION', '236')],
    );
  });

  test('lists and fetches invoice detail', () async {
    final first = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(3),
    );
    final second = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(4),
    );
    await invoicesService.cancelInvoice(
        invoiceId: first.invoice.id, reason: 'Void');

    final all = await invoicesService.listInvoices();
    final active = await invoicesService.listInvoices(status: 'ACTIVE');
    final detail = await invoicesService.fetchInvoiceDetail(second.invoice.id);

    expect(all.map((invoice) => invoice.id), <String>[
      second.invoice.id,
      first.invoice.id,
    ]);
    expect(active.map((invoice) => invoice.id), <String>[second.invoice.id]);
    expect(detail.id, second.invoice.id);
    expect(detail.items.single.productName, 'Blue Pen');
  });

  test('cancels invoices with stock and ledger reversal', () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(5),
    );

    final canceled = await invoicesService.cancelInvoice(
      invoiceId: result.invoice.id,
      reason: 'Customer returned goods',
    );

    expect(canceled.id, result.invoice.id);
    expect(canceled.status, 'CANCELED');
    expect(canceled.cancelReason, 'Customer returned goods');
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '5');

    final movements = await database.select(database.stockMovements).get();
    expect(
      movements.map((movement) => movement.movementType),
      <String>['INVOICE_SALE', 'INVOICE_CANCEL_REVERSAL'],
    );
    expect(movements.last.quantityDelta, '2');

    final transactions =
        await database.select(database.customerTransactions).get();
    expect(
      transactions.map((transaction) => transaction.entryType),
      <String>['CREDIT_SALE', 'INVOICE_CANCEL_REVERSAL'],
    );
    expect(transactions.last.amount, '236');
    expect(transactions.last.notes, 'Cancel invoice 1');
  });

  test('repeat cancellation does not duplicate reversal side effects',
      () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(6),
    );
    await invoicesService.cancelInvoice(
      invoiceId: result.invoice.id,
      reason: 'Customer returned goods',
    );

    await expectLater(
      () => invoicesService.cancelInvoice(
        invoiceId: result.invoice.id,
        reason: 'Customer returned goods',
      ),
      throwsA(_apiError(code: 'INVOICE_ALREADY_CANCELED', statusCode: 409)),
    );

    expect(await database.select(database.stockMovements).get(), hasLength(2));
    expect(await database.select(database.customerTransactions).get(),
        hasLength(2));
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '5');
  });

  test('cancel does not duplicate side effects when status changed first',
      () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(25),
    );

    await (database.update(database.invoices)
          ..where((invoice) => invoice.id.equals(result.invoice.id)))
        .write(const db.InvoicesCompanion(status: Value('CANCELED')));

    await expectLater(
      () => invoicesService.cancelInvoice(
        invoiceId: result.invoice.id,
        reason: 'Already canceled elsewhere',
      ),
      throwsA(_apiError(code: 'INVOICE_ALREADY_CANCELED', statusCode: 409)),
    );
    expect(await database.select(database.stockMovements).get(), hasLength(1));
    expect(await database.select(database.customerTransactions).get(),
        hasLength(1));
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '3');
  });

  test('cancel guards reversal inserts inside the transaction', () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(26),
    );
    await database.into(database.stockMovements).insert(
          db.StockMovementsCompanion.insert(
            id: 'existing-cancel-stock',
            productId: product.id,
            invoiceId: Value(result.invoice.id),
            movementType: 'INVOICE_CANCEL_REVERSAL',
            quantityDelta: '2',
            reason: const Value('Cancel invoice 1'),
            createdByUserId: 'local-system-user',
            createdAt: '2026-01-10T16:00:00.000Z',
          ),
        );
    await database.into(database.customerTransactions).insert(
          db.CustomerTransactionsCompanion.insert(
            id: 'existing-cancel-ledger',
            customerId: customer.id,
            invoiceId: Value(result.invoice.id),
            entryType: 'INVOICE_CANCEL_REVERSAL',
            amount: '236',
            occurredOn: '2026-01-10',
            notes: const Value('Cancel invoice 1'),
            createdByUserId: 'local-system-user',
            createdAt: '2026-01-10T16:00:00.000Z',
          ),
        );

    await invoicesService.cancelInvoice(
      invoiceId: result.invoice.id,
      reason: 'Retry after partial local cancel',
    );

    final movements = await database.select(database.stockMovements).get();
    final transactions =
        await database.select(database.customerTransactions).get();
    expect(
      movements
          .where(
              (movement) => movement.movementType == 'INVOICE_CANCEL_REVERSAL')
          .length,
      1,
    );
    expect(
      transactions
          .where((transaction) =>
              transaction.entryType == 'INVOICE_CANCEL_REVERSAL')
          .length,
      1,
    );
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '3');
  });

  test('quote rejects invalid invoice line numeric values', () async {
    Future<void> expectInvalid(InvoiceDraftItem item) async {
      await expectLater(
        () => invoicesService.quoteInvoice(_draftWithItems(
          customer: customer,
          items: <InvoiceDraftItem>[item],
        )),
        throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
      );
    }

    await expectInvalid(InvoiceDraftItem(product: product, quantity: 0));
    await expectInvalid(InvoiceDraftItem(product: product, quantity: -1));
    await expectInvalid(InvoiceDraftItem(product: product, quantity: 1.0001));
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 100000000000),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, unitPrice: 0),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, unitPrice: -1),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, gstRate: -0.01),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, gstRate: 100.01),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, discountPercent: -0.01),
    );
    await expectInvalid(
      InvoiceDraftItem(product: product, quantity: 1, discountPercent: 100.01),
    );

    expect(await database.select(database.invoices).get(), isEmpty);
  });

  test('create rejects invalid invoice line numeric values', () async {
    await expectLater(
      () => invoicesService.createInvoice(
        draft: _draftWithItems(
          customer: customer,
          items: <InvoiceDraftItem>[
            InvoiceDraftItem(product: product, quantity: 1, unitPrice: 0),
          ],
        ),
        requestId: _uuid(27),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );

    expect(await database.select(database.invoices).get(), isEmpty);
    expect(await database.select(database.stockMovements).get(), isEmpty);
    expect(await database.select(database.customerTransactions).get(), isEmpty);
  });

  test('invoice datetime requires timezone and must match invoice date',
      () async {
    await expectLater(
      () => invoicesService.quoteInvoice(_draft(
        customer: customer,
        product: product,
        quantity: 1,
        invoiceDatetime: '2026-01-10T15:30:00.000',
      )),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    await expectLater(
      () => invoicesService.quoteInvoice(_draft(
        customer: customer,
        product: product,
        quantity: 1,
        invoiceDate: '2026-01-11',
        invoiceDatetime: '2026-01-10T15:30:00.000Z',
      )),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
  });

  test('inclusive GST half-cent rounding is deterministic', () async {
    final quote = await invoicesService.quoteInvoice(_draftWithItems(
      customer: customer,
      items: <InvoiceDraftItem>[
        InvoiceDraftItem(product: product, quantity: 1, unitPrice: 1.005),
      ],
    ));

    expect(quote.items.single.enteredUnitPrice, 1.01);
    expect(quote.items.single.lineTotal, 1.01);
    expect(quote.totals.grandTotal, 1.01);
  });

  test('rejects unsupported payment modes', () async {
    await expectLater(
      () => invoicesService.createInvoice(
        draft: _draft(
          customer: customer,
          product: product,
          quantity: 1,
          paymentMode: 'CASH',
        ),
        requestId: _uuid(8),
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    expect(await database.select(database.invoices).get(), isEmpty);
  });

  test('rejects company state and state code mismatch for quote and create',
      () async {
    await companyService.upsertCompanyProfile(
      _companyInput(state: 'Delhi', stateCode: '27'),
    );
    final draft = _draft(customer: customer, product: product, quantity: 1);

    await expectLater(
      () => invoicesService.quoteInvoice(draft),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    await expectLater(
      () => invoicesService.createInvoice(draft: draft, requestId: _uuid(9)),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    expect(await database.select(database.invoices).get(), isEmpty);
  });

  test('rejects customer state and state code mismatch for quote and create',
      () async {
    final mismatchedCustomer = await customersService.createCustomer(
      _customerInput(
        name: 'Mismatch Stores',
        phone: '8888888888',
        state: 'Delhi',
        stateCode: '27',
      ),
    );
    final draft = _draft(
      customer: mismatchedCustomer,
      product: product,
      quantity: 1,
    );

    await expectLater(
      () => invoicesService.quoteInvoice(draft),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    await expectLater(
      () => invoicesService.createInvoice(draft: draft, requestId: _uuid(10)),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    expect(await database.select(database.invoices).get(), isEmpty);
  });

  test('explicit place of supply bypasses mismatched customer metadata',
      () async {
    final mismatchedCustomer = await customersService.createCustomer(
      _customerInput(
        name: 'Override Stores',
        phone: '7777777777',
        state: 'Delhi',
        stateCode: '27',
      ),
    );
    final draft = _draft(
      customer: mismatchedCustomer,
      product: product,
      quantity: 1,
      placeOfSupplyStateCode: '27',
    );

    final quote = await invoicesService.quoteInvoice(draft);
    final result = await invoicesService.createInvoice(
      draft: draft,
      requestId: _uuid(11),
    );

    expect(quote.placeOfSupplyStateCode, '27');
    expect(result.invoice.status, 'ACTIVE');
    expect(await database.select(database.invoices).get(), hasLength(1));
  });

  test('invalid create request ID returns validation error with bad request',
      () async {
    await expectLater(
      () => invoicesService.createInvoice(
        draft: _draft(customer: customer, product: product, quantity: 1),
        requestId: 'not-a-uuid',
      ),
      throwsA(_apiError(code: 'VALIDATION_ERROR', statusCode: 400)),
    );
    expect(await database.select(database.invoices).get(), isEmpty);
  });
}

UpsertCompanyProfileInput _companyInput({
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return UpsertCompanyProfileInput(
    name: 'Khata Traders',
    address: '10 Market Road',
    city: 'Mumbai',
    state: state,
    stateCode: stateCode,
  );
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String phone = '9999999999',
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return CreateCustomerInput(
    name: name,
    address: '1 Market Road',
    phone: phone,
    gstin: '27ABCDE1234F1Z5',
    state: state,
    stateCode: stateCode,
  );
}

CreateProductInput _productInput({
  String companyName = 'Acme',
  String category = 'Pens',
  String itemName = 'Blue Pen',
  String itemNumber = 'PEN-1',
  String? unit,
}) {
  return CreateProductInput(
    companyName: companyName,
    category: category,
    itemName: itemName,
    itemNumber: itemNumber,
    buyingPrice: 80,
    sellingPrice: 118,
    unit: unit,
    gstRate: 18,
    quantityOnHand: 5,
    lowStockThreshold: 2,
  );
}

InvoiceDraft _draft({
  required Customer customer,
  required Product product,
  required double quantity,
  String invoiceDate = '2026-01-10',
  String? invoiceDatetime = '2026-01-10T15:30:00.000Z',
  String paymentState = 'CREDIT',
  double paidAmount = 0,
  String? paymentMode,
  double discountPercent = 0,
  String? placeOfSupplyStateCode,
}) {
  return _draftWithItems(
    customer: customer,
    invoiceDate: invoiceDate,
    invoiceDatetime: invoiceDatetime,
    paymentState: paymentState,
    paidAmount: paidAmount,
    paymentMode: paymentMode,
    placeOfSupplyStateCode: placeOfSupplyStateCode,
    items: <InvoiceDraftItem>[
      InvoiceDraftItem(
        product: product,
        quantity: quantity,
        unitPrice: 118,
        discountPercent: discountPercent,
      ),
    ],
  );
}

InvoiceDraft _draftWithItems({
  required Customer customer,
  required List<InvoiceDraftItem> items,
  String invoiceDate = '2026-01-10',
  String? invoiceDatetime = '2026-01-10T15:30:00.000Z',
  String paymentState = 'CREDIT',
  double paidAmount = 0,
  String? paymentMode,
  String? placeOfSupplyStateCode,
}) {
  return InvoiceDraft(
    customer: customer,
    invoiceDate: invoiceDate,
    invoiceDatetime: invoiceDatetime,
    paymentState: paymentState,
    paidAmount: paidAmount,
    paymentMode: paymentMode,
    placeOfSupplyStateCode: placeOfSupplyStateCode,
    items: items,
  );
}

Matcher _apiError({required String code, required int statusCode}) {
  return isA<ApiError>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.statusCode, 'statusCode', statusCode);
}

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
}

Future<void> _seedLocalUser(db.LocalDatabase database) {
  return database.into(database.localUsers).insert(
        db.LocalUsersCompanion.insert(
          id: 'local-system-user',
          username: 'system',
          passwordHash: 'hash',
          salt: 'salt',
          passwordHashVersion: 1,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
          displayName: const Value('System'),
        ),
      );
}
