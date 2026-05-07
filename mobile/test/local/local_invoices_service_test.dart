import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/local/local_sellers_service.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  late db.LocalDatabase database;
  late LocalCompanyProfileService companyService;
  late LocalProductsService productsService;
  late LocalSellersService sellersService;
  late LocalInvoicesService invoicesService;
  late Seller seller;
  late Product product;

  setUp(() async {
    database = db.LocalDatabase.memory();
    companyService = LocalCompanyProfileService(database: database);
    productsService = LocalProductsService(database: database);
    sellersService = LocalSellersService(database: database);
    invoicesService = LocalInvoicesService(database: database);
    await _seedLocalUser(database);
    await companyService.upsertCompanyProfile(_companyInput());
    seller = await sellersService.createSeller(_sellerInput());
    product = await productsService.createProduct(_productInput());
  });

  tearDown(() async {
    await database.close();
  });

  test('quotes invoices with backend-aligned tax totals and stock warnings',
      () async {
    final quote = await invoicesService.quoteInvoice(_draft(
      seller: seller,
      product: product,
      quantity: 6,
      discountPercent: 10,
    ));

    expect(quote.placeOfSupplyState, 'Maharashtra');
    expect(quote.placeOfSupplyStateCode, '27');
    expect(quote.taxRegime, 'INTRA_STATE');
    expect(quote.items, hasLength(1));
    expect(quote.items.single.productId, product.id);
    expect(quote.items.single.quantity, 6);
    expect(quote.items.single.unitPriceExclTax, 100);
    expect(quote.items.single.lineTotal, 637.2);
    expect(quote.totals.subtotal, 600);
    expect(quote.totals.discountTotal, 60);
    expect(quote.totals.taxableTotal, 540);
    expect(quote.totals.gstTotal, 97.2);
    expect(quote.totals.grandTotal, 637.2);
    expect(quote.warnings.single.code, 'NEGATIVE_STOCK');
  });

  test('creates invoices with snapshots, stock reduction, and ledger debit',
      () async {
    final result = await invoicesService.createInvoice(
      draft: _draft(seller: seller, product: product, quantity: 2),
      requestId: _uuid(1),
    );

    expect(result.warnings, isEmpty);
    expect(result.invoice.id, isNotEmpty);
    expect(result.invoice.invoiceNumber, '1');
    expect(result.invoice.status, 'ACTIVE');
    expect(result.invoice.paymentMode, 'CREDIT');
    expect(result.invoice.sellerName, 'Acme Stores');
    expect(result.invoice.invoiceDate, '2026-01-10');
    expect(result.invoice.grandTotal, 236);
    expect(result.invoice.items.single.productName, 'Blue Pen');
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
        await database.select(database.sellerTransactions).getSingle();
    expect(transaction.sellerId, seller.id);
    expect(transaction.invoiceId, result.invoice.id);
    expect(transaction.entryType, 'CREDIT_SALE');
    expect(transaction.amount, '236');
    expect(transaction.occurredOn, '2026-01-10');
    expect(transaction.notes, 'Invoice 1');

    final storedInvoice = await database.select(database.invoices).getSingle();
    expect(storedInvoice.requestId, _uuid(1));
    expect(storedInvoice.sellerName, 'Acme Stores');
    expect(storedInvoice.companyName, 'Khata Traders');
    expect(storedInvoice.companyStateCode, '27');
  });

  test('returns idempotent create result and rejects request ID conflicts',
      () async {
    final draft = _draft(seller: seller, product: product, quantity: 1);

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
        draft: _draft(seller: seller, product: product, quantity: 2),
        requestId: _uuid(2),
      ),
      throwsA(_apiError(code: 'IDEMPOTENCY_CONFLICT', statusCode: 409)),
    );
  });

  test('lists and fetches invoice detail', () async {
    final first = await invoicesService.createInvoice(
      draft: _draft(seller: seller, product: product, quantity: 1),
      requestId: _uuid(3),
    );
    final second = await invoicesService.createInvoice(
      draft: _draft(seller: seller, product: product, quantity: 1),
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
      draft: _draft(seller: seller, product: product, quantity: 2),
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
        await database.select(database.sellerTransactions).get();
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
      draft: _draft(seller: seller, product: product, quantity: 2),
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
    expect(
        await database.select(database.sellerTransactions).get(), hasLength(2));
    expect(
        (await database.select(database.products).getSingle()).quantityOnHand,
        '5');
  });

  test('does not write ledger rows for paid invoices', () async {
    await invoicesService.createInvoice(
      draft: _draft(
        seller: seller,
        product: product,
        quantity: 1,
        paymentMode: 'PAID',
      ),
      requestId: _uuid(7),
    );

    expect(await database.select(database.sellerTransactions).get(), isEmpty);
  });

  test('rejects unsupported payment modes', () async {
    await expectLater(
      () => invoicesService.createInvoice(
        draft: _draft(
          seller: seller,
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
    final draft = _draft(seller: seller, product: product, quantity: 1);

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

  test('rejects seller state and state code mismatch for quote and create',
      () async {
    final mismatchedSeller = await sellersService.createSeller(
      _sellerInput(
        name: 'Mismatch Stores',
        phone: '8888888888',
        state: 'Delhi',
        stateCode: '27',
      ),
    );
    final draft = _draft(
      seller: mismatchedSeller,
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

  test('explicit place of supply bypasses mismatched seller metadata',
      () async {
    final mismatchedSeller = await sellersService.createSeller(
      _sellerInput(
        name: 'Override Stores',
        phone: '7777777777',
        state: 'Delhi',
        stateCode: '27',
      ),
    );
    final draft = _draft(
      seller: mismatchedSeller,
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
        draft: _draft(seller: seller, product: product, quantity: 1),
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

CreateSellerInput _sellerInput({
  String name = 'Acme Stores',
  String phone = '9999999999',
  String state = 'Maharashtra',
  String stateCode = '27',
}) {
  return CreateSellerInput(
    name: name,
    address: '1 Market Road',
    phone: phone,
    gstin: '27ABCDE1234F1Z5',
    state: state,
    stateCode: stateCode,
  );
}

CreateProductInput _productInput() {
  return const CreateProductInput(
    company: 'Acme',
    category: 'Pens',
    itemName: 'Blue Pen',
    itemCode: 'PEN-1',
    defaultSellingPriceExclTax: 100,
    defaultGstRate: 18,
    quantityOnHand: 5,
    lowStockThreshold: 2,
  );
}

InvoiceDraft _draft({
  required Seller seller,
  required Product product,
  required double quantity,
  String paymentMode = 'CREDIT',
  double discountPercent = 0,
  String? placeOfSupplyStateCode,
}) {
  return InvoiceDraft(
    seller: seller,
    invoiceDate: '2026-01-10',
    paymentMode: paymentMode,
    placeOfSupplyStateCode: placeOfSupplyStateCode,
    items: <InvoiceDraftItem>[
      InvoiceDraftItem(
        product: product,
        quantity: quantity,
        pricingMode: 'PRE_TAX',
        unitPrice: 100,
        gstRate: 18,
        discountPercent: discountPercent,
      ),
    ],
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
