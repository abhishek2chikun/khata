import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/invoice_summary.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/customer_ledger.dart';
import 'package:internal_billing_khata_mobile/screens/create_invoice_screen.dart';
import 'package:internal_billing_khata_mobile/services/invoices_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';

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
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

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
    expect(invoicesService.quotedDrafts.single.customer?.id, 'customer-1');
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
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

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
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
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
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
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

    expect(find.text('2'), findsOneWidget);
    expect(find.text('ABC Stores'), findsWidgets);
  });

  testWidgets(
      'customer preselected flow shows customer and skips customer selection changes by default',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService: FakeCustomersService(
              customers: <Customer>[_customer, _otherCustomer]),
          initialCustomer: _customer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsWidgets);
    expect(find.byKey(const Key('customerPickerField')), findsNothing);
  });

  testWidgets(
      'create invoice screen uses active-only products and filters archived customers',
      (tester) async {
    final productsService =
        FakeProductsService(products: <Product>[_product, _archivedProduct]);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: productsService,
          customersService: FakeCustomersService(
              customers: <Customer>[_customer, _archivedCustomer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(productsService.fetchFilters, hasLength(1));
    expect(productsService.fetchFilters.single?.active, isTrue);

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();

    expect(find.text('ABC Stores'), findsWidgets);
    expect(find.text('Archived Customer'), findsNothing);
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
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to reach the server'), findsOneWidget);
  });

  testWidgets('quick-add customer popup creates new customer and selects it',
      (tester) async {
    final customersService =
        FakeCustomersService(customers: <Customer>[_customer]);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService: customersService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('customerNameField')), 'New Customer');
    await tester.enterText(
        find.byKey(const Key('customerAddressField')), 'New Address');

    await tester.tap(find.byKey(const Key('saveCustomerButton')));
    await tester.pumpAndSettle();

    expect(customersService.createdInputs, hasLength(1));
    expect(customersService.createdInputs.single.name, 'New Customer');
    expect(customersService.createdInputs.single.address, 'New Address');
    expect(find.text('New Customer'), findsWidgets);
  });

  testWidgets('quick-add product popup creates product with buyingPrice 0',
      (tester) async {
    final productsService = FakeProductsService(products: <Product>[_product]);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: productsService,
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('addProductButton')));
    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('productItemNameField')), 'New Product');
    await tester.enterText(
        find.byKey(const Key('productItemNumberField')), 'NP-1');
    await tester.enterText(
        find.byKey(const Key('productCompanyNameField')), 'NewCo');
    await tester.enterText(
        find.byKey(const Key('productCategoryField')), 'General');
    await tester.enterText(
        find.byKey(const Key('productSellingPriceField')), '50');
    await tester.enterText(
        find.byKey(const Key('productGstRateField')), '18');

    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    expect(productsService.createdInputs, hasLength(1));
    expect(productsService.createdInputs.single.buyingPrice, 0);
    expect(productsService.createdInputs.single.sellingPrice, 50);
  });

  testWidgets('quick-add product popup creates new product and selects it',
      (tester) async {
    final productsService = FakeProductsService(products: <Product>[_product]);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: productsService,
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('addProductButton')));
    await tester.tap(find.byKey(const Key('addProductButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Product'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('productItemNameField')), 'New Product');
    await tester.enterText(
        find.byKey(const Key('productItemNumberField')), 'NP-1');
    await tester.enterText(
        find.byKey(const Key('productCompanyNameField')), 'NewCo');
    await tester.enterText(
        find.byKey(const Key('productCategoryField')), 'General');
    await tester.enterText(
        find.byKey(const Key('productSellingPriceField')), '50');
    await tester.enterText(
        find.byKey(const Key('productGstRateField')), '18');

    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    expect(productsService.createdInputs, hasLength(1));
    expect(productsService.createdInputs.single.itemName, 'New Product');
    expect(productsService.createdInputs.single.itemNumber, 'NP-1');
  });

  testWidgets('editable selling price per line updates unit price field',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();

    final unitPriceField = find.byKey(const Key('unitPriceField-0'));
    expect(unitPriceField, findsOneWidget);

    await tester.enterText(unitPriceField, '150');
    await tester.pump();

    expect(find.text('150'), findsOneWidget);
  });

  testWidgets('editable GST per line updates gst rate field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();

    final gstRateField = find.byKey(const Key('gstRateField-0'));
    expect(gstRateField, findsOneWidget);

    await tester.enterText(gstRateField, '12');
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('apply GST to all lines control updates all items',
      (tester) async {
    final invoicesService = FakeInvoicesService(
      quoteResponse: _quoteWithTwoItems,
      createResult: CreateInvoiceResult(
          invoice: _invoiceDetail, warnings: const <InvoiceWarning>[]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService:
              FakeProductsService(products: <Product>[_product, _product2]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('addItemButton')));
    await tester.tap(find.byKey(const Key('addItemButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red Pen').last);
    await tester.pumpAndSettle();

    final applyGstField = find.byKey(const Key('applyGstToAllField'));
    expect(applyGstField, findsOneWidget);

    await tester.enterText(applyGstField, '5');
    await tester.pump();

    final gstField0 = find.byKey(const Key('gstRateField-0'));
    final gstField1 = find.byKey(const Key('gstRateField-1'));

    expect(tester.widget<TextField>(gstField0).controller?.text, '5.00');
    expect(tester.widget<TextField>(gstField1).controller?.text, '5.00');
  });

  testWidgets('clearing apply GST to all field clears line GST values',
      (tester) async {
    final invoicesService = FakeInvoicesService(
      quoteResponse: _quoteWithTwoItems,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService:
              FakeProductsService(products: <Product>[_product, _product2]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customerPickerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Stores').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pen').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('addItemButton')));
    await tester.tap(find.byKey(const Key('addItemButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('productPickerField-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red Pen').last);
    await tester.pumpAndSettle();

    final applyGstField = find.byKey(const Key('applyGstToAllField'));
    await tester.enterText(applyGstField, '18');
    await tester.pump();

    var gstField0 = find.byKey(const Key('gstRateField-0'));
    expect(tester.widget<TextField>(gstField0).controller?.text, '18.00');

    await tester.enterText(applyGstField, '');
    await tester.pump();

    gstField0 = find.byKey(const Key('gstRateField-0'));
    final gstField1 = find.byKey(const Key('gstRateField-1'));
    expect(tester.widget<TextField>(gstField0).controller?.text, isEmpty);
    expect(tester.widget<TextField>(gstField1).controller?.text, isEmpty);
  });

  testWidgets(
      'payment state selection shows Credit Total Paid Partial Paid options',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paymentStateDropdown = find.byKey(const Key('paymentStateField'));
    expect(paymentStateDropdown, findsOneWidget);

    await tester.tap(paymentStateDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Credit'), findsWidgets);
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text('Partial Paid'), findsOneWidget);
  });

  testWidgets(
      'partial paid amount field appears only when Partial Paid is selected',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paidAmountField')), findsNothing);

    await tester.tap(find.byKey(const Key('paymentStateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partial Paid').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paidAmountField')), findsOneWidget);
  });

  testWidgets('invoice date is initialized from datetime defaulting to now',
      (tester) async {
    final invoicesService = FakeInvoicesService(quoteResponse: _quote);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: invoicesService,
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dateTimeField = find.byKey(const Key('invoiceDatetimeField'));
    expect(dateTimeField, findsOneWidget);

    final textController =
        tester.widget<TextField>(dateTimeField).controller;
    expect(textController?.text, isNotEmpty);

    final datePart = textController!.text.split(' ').first;
    expect(datePart, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

    await _fillDraft(tester);
    await tester.ensureVisible(find.byKey(const Key('previewInvoiceButton')));
    await tester.tap(find.byKey(const Key('previewInvoiceButton')));
    await tester.pumpAndSettle();

    expect(invoicesService.quotedDrafts, hasLength(1));
    expect(invoicesService.quotedDrafts.single.invoiceDate, datePart);
  });

  testWidgets('add item button adds new product line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService:
              FakeProductsService(products: <Product>[_product, _product2]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('productPickerField-0')), findsOneWidget);
    expect(find.byKey(const Key('productPickerField-1')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('addItemButton')));
    await tester.tap(find.byKey(const Key('addItemButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('productPickerField-1')), findsOneWidget);
    expect(find.byKey(const Key('quantityField-1')), findsOneWidget);
  });

  testWidgets('remove item button removes product line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService:
              FakeProductsService(products: <Product>[_product, _product2]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('addItemButton')));
    await tester.tap(find.byKey(const Key('addItemButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('productPickerField-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeItemButton-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('productPickerField-1')), findsNothing);
    expect(find.byKey(const Key('productPickerField-0')), findsOneWidget);
  });

  testWidgets('no overflow in narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: CreateInvoiceScreen(
          invoicesService: FakeInvoicesService(quoteResponse: _quote),
          productsService: FakeProductsService(products: <Product>[_product]),
          customersService:
              FakeCustomersService(customers: <Customer>[_customer]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

Future<void> _fillDraft(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('customerPickerField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ABC Stores').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('productPickerField-0')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Blue Pen').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('quantityField-0')), '2');
}

const _customer = Customer(
  id: 'customer-1',
  name: 'ABC Stores',
  address: 'Market Yard',
  phone: '9999999999',
  gstin: '27BBBBB0000B1Z5',
  state: 'Maharashtra',
  stateCode: '27',
  isActive: true,
  pendingBalance: 0,
);

const _otherCustomer = Customer(
  id: 'customer-2',
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
  companyName: 'Acme',
  category: 'Pens',
  itemName: 'Blue Pen',
  itemNumber: 'PEN-1',
  buyingPrice: 100,
  sellingPrice: 100,
  gstRate: 18,
  quantityOnHand: 1,
  lowStockThreshold: 2,
  isActive: true,
);

const _product2 = Product(
  id: 'product-2',
  companyName: 'Acme',
  category: 'Pens',
  itemName: 'Red Pen',
  itemNumber: 'PEN-2',
  buyingPrice: 80,
  sellingPrice: 80,
  gstRate: 18,
  quantityOnHand: 10,
  lowStockThreshold: 2,
  isActive: true,
);

const _archivedProduct = Product(
  id: 'product-3',
  companyName: 'Acme',
  category: 'Pens',
  itemName: 'Red Pen',
  itemNumber: 'PEN-2',
  buyingPrice: 80,
  sellingPrice: 80,
  gstRate: 18,
  quantityOnHand: 10,
  lowStockThreshold: 2,
  isActive: false,
);

const _archivedCustomer = Customer(
  id: 'customer-3',
  name: 'Archived Customer',
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
      productItemName: 'Blue Pen',
      productItemNumber: 'PEN-1',
      productCategory: 'Pens',
      unit: 'PCS',
      quantity: 2,
      sellingPrice: 100,
      enteredUnitPrice: 100,
      unitPriceExclTax: 100,
      unitPriceInclTax: 118,
      gstRate: 18,
      gstAmount: 36,
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

const _quoteWithTwoItems = InvoiceQuote(
  placeOfSupplyState: 'Maharashtra',
  placeOfSupplyStateCode: '27',
  taxRegime: 'INTRA_STATE',
  items: <InvoiceQuoteItem>[
    InvoiceQuoteItem(
      productId: 'product-1',
      productItemName: 'Blue Pen',
      productItemNumber: 'PEN-1',
      productCategory: 'Pens',
      unit: 'PCS',
      quantity: 2,
      sellingPrice: 100,
      enteredUnitPrice: 100,
      unitPriceExclTax: 100,
      unitPriceInclTax: 118,
      gstRate: 18,
      gstAmount: 36,
      lineTotal: 236,
    ),
    InvoiceQuoteItem(
      productId: 'product-2',
      productItemName: 'Red Pen',
      productItemNumber: 'PEN-2',
      productCategory: 'Pens',
      unit: 'PCS',
      quantity: 1,
      sellingPrice: 80,
      enteredUnitPrice: 80,
      unitPriceExclTax: 80,
      unitPriceInclTax: 94.4,
      gstRate: 18,
      gstAmount: 14.4,
      lineTotal: 94.4,
    ),
  ],
  totals: InvoiceTotals(
    subtotal: 280,
    discountTotal: 0,
    taxableTotal: 280,
    gstTotal: 50.4,
    grandTotal: 330.4,
  ),
  warnings: <InvoiceWarning>[],
);

final _invoiceDetail = InvoiceDetail(
  id: 'inv-1',
  customerId: 'customer-1',
  invoiceNumber: '1001',
  status: 'ACTIVE',
  paymentState: 'CREDIT',
  paymentMode: 'CREDIT',
  customerName: 'ABC Stores',
  invoiceDate: '2026-04-20',
  grandTotal: 236,
  notes: null,
  cancelReason: null,
  items: const <InvoiceDetailItem>[
    InvoiceDetailItem(
      productId: 'product-1',
      productName: 'Blue Pen',
      productItemName: 'Blue Pen',
      productItemNumber: 'PEN-1',
      productCategory: 'Pens',
      unit: 'PCS',
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
  final List<CreateProductInput> createdInputs = <CreateProductInput>[];

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    createdInputs.add(input);
    return Product(
      id: 'product-${products.length + createdInputs.length}',
      companyName: input.companyName,
      category: input.category,
      itemName: input.itemName,
      itemNumber: input.itemNumber,
      buyingPrice: input.buyingPrice,
      sellingPrice: input.sellingPrice,
      unit: input.unit,
      gstRate: input.gstRate,
      quantityOnHand: input.quantityOnHand,
      lowStockThreshold: input.lowStockThreshold,
      isActive: true,
    );
  }

  @override
  Future<Product> archiveProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> reactivateProduct({required String id}) {
    throw UnimplementedError();
  }

  @override
  Future<Product> adjustStock({
    required String id,
    required AdjustStockInput input,
  }) {
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

class FakeCustomersService implements CustomersService {
  FakeCustomersService({required this.customers, this.error});

  final List<Customer> customers;
  final Object? error;
  final List<CreateCustomerInput> createdInputs = <CreateCustomerInput>[];

  @override
  Future<Customer> createCustomer(CreateCustomerInput input) async {
    createdInputs.add(input);
    return Customer(
      id: 'customer-${customers.length + createdInputs.length}',
      name: input.name,
      address: input.address,
      phone: input.phone,
      gstin: input.gstin,
      state: input.state,
      stateCode: input.stateCode,
      isActive: true,
      pendingBalance: 0,
    );
  }

  @override
  Future<List<Customer>> fetchCustomers({String search = ''}) async {
    if (error != null) {
      throw error!;
    }
    return customers;
  }

  @override
  Future<CustomerLedger> fetchCustomerLedger(String customerId,
      {String? onDate}) {
    throw UnimplementedError();
  }
}
