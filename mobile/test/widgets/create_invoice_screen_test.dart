import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/seller.dart';
import 'package:internal_billing_khata_mobile/models/seller_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/create_invoice_screen.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/sellers_service.dart';

void main() {
  testWidgets(
      'create invoice screen can build draft request quote and show preview path',
      (tester) async {
    final invoicesService = FakeInvoicesService(
      quoteResponse: _quote,
      createResult: CreateInvoiceResult(
          invoice: _invoiceDetail, warnings: const <InvoiceWarning>[]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService: FakeProductsService(products: <Product>[_product]),
          sellersService: FakeSellersService(sellers: <Seller>[_seller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sellerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('invoiceDateField')), '2026-04-20');
    await tester.enterText(
        find.byKey(const Key('placeOfSupplyStateCodeField')), '27');
    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantityField-0')), '2');

    await tester.ensureVisible(find.byKey(const Key('previewInvoiceButton')));
    await tester.tap(find.byKey(const Key('previewInvoiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Invoice preview'), findsOneWidget);
    expect(find.text('Blue Pen'), findsOneWidget);
    expect(find.text('Subtotal: 200.00'), findsOneWidget);
    expect(find.text('Discount: 0.00'), findsOneWidget);
    expect(find.text('Taxable total: 200.00'), findsOneWidget);
    expect(find.text('GST total: 36.00'), findsOneWidget);
    expect(find.text('Grand total: 236.00'), findsOneWidget);
    expect(find.text('236.00'), findsWidgets);
    expect(invoicesService.quotedDrafts, hasLength(1));
    expect(invoicesService.quotedDrafts.single.seller?.id, 'seller-1');
    expect(invoicesService.quotedDrafts.single.items.single.product?.id,
        'product-1');
  });

  testWidgets(
      'create invoice screen keeps draft intact and shows error on quote failure',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(
            quoteError:
                const ApiError(message: 'Quote failed', statusCode: 400),
          ),
          productsService: FakeProductsService(products: <Product>[_product]),
          sellersService: FakeSellersService(sellers: <Seller>[_seller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sellerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('invoiceDateField')), '2026-04-20');
    await tester.enterText(
        find.byKey(const Key('placeOfSupplyStateCodeField')), '27');
    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantityField-0')), '2');

    await tester.ensureVisible(find.byKey(const Key('previewInvoiceButton')));
    await tester.tap(find.byKey(const Key('previewInvoiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Quote failed'), findsOneWidget);
    expect(find.text('Invoice preview'), findsNothing);
    expect(find.text('2026-04-20'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets(
      'preview submit path keeps draft intact and surfaces commit time warnings on create response',
      (
    tester,
  ) async {
    final invoicesService = FakeInvoicesService(
      quoteResponse: _quote,
      createResult: CreateInvoiceResult(
        invoice: _invoiceDetail,
        warnings: const <InvoiceWarning>[
          InvoiceWarning(
            code: 'NEGATIVE_STOCK',
            message: 'Stock will go negative for Blue Pen',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService: FakeProductsService(products: <Product>[_product]),
          sellersService: FakeSellersService(sellers: <Seller>[_seller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _fillDraft(tester);
    await tester.ensureVisible(find.byKey(const Key('previewInvoiceButton')));
    await tester.tap(find.byKey(const Key('previewInvoiceButton')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('confirmInvoiceButton')));
    await tester.tap(find.byKey(const Key('confirmInvoiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Invoice created'), findsOneWidget);
    expect(find.text('Stock will go negative for Blue Pen'), findsOneWidget);
    expect(invoicesService.createdDrafts, hasLength(1));
  });

  testWidgets(
      'preview submit path shows create failure and preserves draft for retry',
      (tester) async {
    final invoicesService = FakeInvoicesService(
      quoteResponse: _quote,
      createError: const ApiError(message: 'Create failed', statusCode: 500),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService: FakeProductsService(products: <Product>[_product]),
          sellersService: FakeSellersService(sellers: <Seller>[_seller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _fillDraft(tester);
    await tester.ensureVisible(find.byKey(const Key('previewInvoiceButton')));
    await tester.tap(find.byKey(const Key('previewInvoiceButton')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('confirmInvoiceButton')));
    await tester.tap(find.byKey(const Key('confirmInvoiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Create failed'), findsOneWidget);
    expect(find.text('Invoice preview'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('2026-04-20'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('ABC Stores'), findsWidgets);
  });

  testWidgets(
      'seller preselected flow shows seller and skips seller selection changes by default',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          sellersService:
              FakeSellersService(sellers: <Seller>[_seller, _otherSeller]),
          initialSeller: _seller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsWidgets);
    expect(find.byKey(const Key('sellerPickerField')), findsNothing);
  });

  testWidgets(
      'create invoice screen uses active-only products and filters archived sellers',
      (tester) async {
    final productsService =
        FakeProductsService(products: <Product>[_product, _archivedProduct]);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: productsService,
          sellersService:
              FakeSellersService(sellers: <Seller>[_seller, _archivedSeller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(productsService.fetchFilters, hasLength(1));
    expect(productsService.fetchFilters.single?.active, isTrue);

    await tester.tap(find.byKey(const Key('sellerPickerField')));
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsWidgets);
    expect(find.text('Archived Seller'), findsNothing);
  });

  testWidgets(
      'create invoice screen shows load error banner on network failure',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(
            products: const <Product>[],
            error: const SocketException('timed out'),
          ),
          sellersService: FakeSellersService(sellers: <Seller>[_seller]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to reach the server'), findsOneWidget);
  });
}

Future<void> _fillDraft(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('sellerPickerField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ABC Stores').last);
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const Key('invoiceDateField')), '2026-04-20');
  await tester.enterText(
      find.byKey(const Key('placeOfSupplyStateCodeField')), '27');
  await tester.tap(find.byKey(const Key('productPickerField-0')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Blue Pen').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('quantityField-0')), '2');
}

const _seller = Seller(
  id: 'seller-1',
  name: 'ABC Stores',
  address: 'Market Yard',
  phone: '9999999999',
  gstin: '27BBBBB0000B1Z5',
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 0,
);

const _otherSeller = Seller(
  id: 'seller-2',
  name: 'XYZ Mart',
  address: 'City Road',
  phone: null,
  gstin: null,
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 0,
);

const _product = Product(
  id: 'product-1',
  company: 'Acme',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemCode: 'PEN-1',
  defaultSellingPriceExclTax: 100,
  defaultGstRate: 18,
  quantityOnHand: 1,
  lowStockThreshold: 2,
  isActive: true,
);

const _archivedProduct = Product(
  id: 'product-2',
  company: 'Acme',
  category: 'Pens',
  itemName: 'Red Pen',
  itemCode: 'PEN-2',
  defaultSellingPriceExclTax: 80,
  defaultGstRate: 18,
  quantityOnHand: 10,
  lowStockThreshold: 2,
  isActive: false,
);

const _archivedSeller = Seller(
  id: 'seller-3',
  name: 'Archived Seller',
  address: 'Old Road',
  phone: null,
  gstin: null,
  state: 'Maharashtra',
  stateCode: '27',
  isActive: false,
  pendingBalance: 0,
);

const _quote = InvoiceQuote(
  placeOfSupplyState: 'Maharashtra',
  placeOfSupplyStateCode: '27',
  taxRegime: 'INTRA_STATE',
  items: <InvoiceQuoteItem>[
    InvoiceQuoteItem(
      productId: 'product-1',
      quantity: 2,
      unitPriceExclTax: 100,
      lineTotal: 236,
    ),
  ],
  totals: InvoiceTotals(
    subtotal: 200,
    discountTotal: 0,
    taxableTotal: 200,
    gstTotal: 36,
    grandTotal: 236,
  ),
  warnings: <InvoiceWarning>[],
);

final _invoiceDetail = InvoiceDetail(
  id: 'inv-1',
  sellerId: 'seller-1',
  invoiceNumber: '1001',
  status: 'ACTIVE',
  paymentMode: 'CREDIT',
  sellerName: 'ABC Stores',
  invoiceDate: '2026-04-20',
  grandTotal: 236,
  notes: null,
  cancelReason: null,
  items: const <InvoiceDetailItem>[
    InvoiceDetailItem(
      productName: 'Blue Pen',
      quantity: 2,
      lineTotal: 236,
    ),
  ],
);

class FakeInvoicesService implements InvoicesService {
  FakeInvoicesService(
      {this.quoteResponse,
      this.quoteError,
      this.createResult,
      this.createError});

  final InvoiceQuote? quoteResponse;
  final Object? quoteError;
  final CreateInvoiceResult? createResult;
  final Object? createError;
  final List<InvoiceDraft> quotedDrafts = <InvoiceDraft>[];
  final List<InvoiceDraft> createdDrafts = <InvoiceDraft>[];

  @override
  Future<CreateInvoiceResult> createInvoice({
    required InvoiceDraft draft,
    required String requestId,
  }) async {
    createdDrafts.add(draft);
    if (createError != null) {
      throw createError!;
    }
    return createResult!;
  }

  @override
  Future<InvoiceQuote> quoteInvoice(InvoiceDraft draft) async {
    quotedDrafts.add(draft);
    if (quoteError != null) {
      throw quoteError!;
    }
    return quoteResponse!;
  }

  @override
  Future<InvoiceDetail> cancelInvoice(
      {required String invoiceId, required String reason}) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceDetail> fetchInvoiceDetail(String invoiceId) {
    throw UnimplementedError();
  }

  @override
  Future<List<InvoiceSummary>> listInvoices({String? status}) {
    throw UnimplementedError();
  }
}

class FakeProductsService implements ProductsService {
  FakeProductsService({required this.products, this.error});

  final List<Product> products;
  final Object? error;
  final List<ProductFilter?> fetchFilters = <ProductFilter?>[];

  @override
  Future<Product> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> fetchProducts({ProductFilter? filter}) async {
    fetchFilters.add(filter);
    if (error != null) {
      throw error!;
    }
    return products;
  }

  @override
  Future<Product> updateProduct(
      {required String id, required UpdateProductInput input}) {
    throw UnimplementedError();
  }
}

class FakeSellersService implements SellersService {
  FakeSellersService({required this.sellers, this.error});

  final List<Seller> sellers;
  final Object? error;

  @override
  Future<Seller> createSeller(CreateSellerInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<Seller>> fetchSellers({String search = ''}) async {
    if (error != null) {
      throw error!;
    }
    return sellers;
  }

  @override
  Future<SellerLedger> fetchSellerLedger(String sellerId) {
    throw UnimplementedError();
  }
}
