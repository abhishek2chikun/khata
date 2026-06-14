import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart' as db;
import 'package:internal_billing_khata_mobile/local/local_invoices_service.dart';
import 'package:internal_billing_khata_mobile/local/local_products_service.dart';
import 'package:internal_billing_khata_mobile/local/local_customers_service.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';
import 'package:internal_billing_khata_mobile/services/products_service.dart';
import 'package:internal_billing_khata_mobile/services/customers_service.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';

void main() {
  late db.LocalDatabase database;
  late LocalCompanyProfileService companyService;
  late LocalProductsService productsService;
  late LocalCustomersService customersService;
  late LocalInvoicesService invoicesService;

  setUp(() async {
    database = db.LocalDatabase.memory();
    companyService = LocalCompanyProfileService(database: database);
    productsService = LocalProductsService(database: database);
    customersService = LocalCustomersService(database: database);
    invoicesService = LocalInvoicesService(database: database);
    await _seedLocalUser(database);
    await companyService.upsertCompanyProfile(_companyInput());
  });

  tearDown(() async {
    await database.close();
  });

  test('InvoiceDetail maps company snapshot fields from DB', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(1),
    );
    final invoice = result.invoice;

    expect(invoice.companyName, 'Khata Traders');
    expect(invoice.companyAddress, '10 Market Road');
    expect(invoice.companyCity, 'Mumbai');
    expect(invoice.companyState, 'Maharashtra');
    expect(invoice.companyStateCode, '27');
    expect(invoice.companyGstin, '27ABCDE1234F1Z5');
    expect(invoice.gstFlag, isTrue);
    expect(invoice.companyPhone, '9876543210');
    expect(invoice.companyEmail, 'info@khata.com');
    expect(invoice.companyBankName, 'State Bank');
    expect(invoice.companyBankAccount, '1234567890');
    expect(invoice.companyBankIfsc, 'SBIN0001234');
    expect(invoice.companyBankBranch, 'Mumbai Main');
  });

  test('InvoiceDetail maps customer snapshot fields from DB', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(2),
    );
    final invoice = result.invoice;

    expect(invoice.customerName, 'Acme Stores');
    expect(invoice.customerAddress, '1 Market Road');
    expect(invoice.customerState, 'Maharashtra');
    expect(invoice.customerStateCode, '27');
    expect(invoice.customerPhone, '9999999999');
    expect(invoice.customerGstin, '27ABCDE1234F1Z5');
  });

  test('InvoiceDetail maps customerWhatsappNumber from DB', () async {
    final customer = await customersService.createCustomer(_customerInput(
      whatsappNumber: '919876543210',
    ));
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(7),
    );
    final invoice = result.invoice;

    expect(invoice.customerWhatsappNumber, '919876543210');
  });

  test('InvoiceDetail maps tax and totals fields from DB', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(3),
    );
    final invoice = result.invoice;

    expect(invoice.taxRegime, 'INTRA_STATE');
    expect(invoice.placeOfSupplyState, 'Maharashtra');
    expect(invoice.placeOfSupplyStateCode, '27');
    expect(invoice.subtotal, 200);
    expect(invoice.discountTotal, 0);
    expect(invoice.taxableTotal, 200);
    expect(invoice.gstTotal, 36);
    expect(invoice.grandTotal, 236);
  });

  test('InvoiceDetail maps payment fields from DB', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(
        customer: customer,
        product: product,
        quantity: 2,
        paymentState: 'PARTIAL_PAID',
        paidAmount: 100,
      ),
      requestId: _uuid(4),
    );
    final invoice = result.invoice;

    expect(invoice.paymentState, 'PARTIAL_PAID');
    expect(invoice.paidAmount, 100);
  });

  test('InvoiceDetailItem maps pricing and tax fields from DB', () async {
    final customer = await customersService.createCustomer(_customerInput());
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 2),
      requestId: _uuid(5),
    );
    final item = result.invoice.items.single;

    expect(item.pricingMode, 'TAX_INCLUSIVE');
    expect(item.unitPriceExclTax, 100);
    expect(item.unitPriceInclTax, 118);
    expect(item.gstRate, 18);
    expect(item.cgstRate, 9);
    expect(item.sgstRate, 9);
    expect(item.igstRate, 0);
    expect(item.gstAmount, 36);
    expect(item.cgstAmount, 18);
    expect(item.sgstAmount, 18);
    expect(item.igstAmount, 0);
    expect(item.discountPercent, 0);
    expect(item.discountAmount, 0);
    expect(item.taxableAmount, 200);
    expect(item.lineTotal, 236);
  });

  test('InvoiceDetail maps INTER_STATE regime correctly', () async {
    final customer = await customersService.createCustomer(
      _customerInput(
        state: 'Karnataka',
        stateCode: '29',
        phone: '8888888888',
      ),
    );
    final product = await productsService.createProduct(_productInput());
    final result = await invoicesService.createInvoice(
      draft: _draft(customer: customer, product: product, quantity: 1),
      requestId: _uuid(6),
    );
    final invoice = result.invoice;
    final item = invoice.items.single;

    expect(invoice.taxRegime, 'INTER_STATE');
    expect(invoice.placeOfSupplyState, 'Karnataka');
    expect(invoice.placeOfSupplyStateCode, '29');
    expect(item.igstRate, 18);
    expect(item.igstAmount, 18);
    expect(item.cgstRate, 0);
    expect(item.cgstAmount, 0);
    expect(item.sgstRate, 0);
    expect(item.sgstAmount, 0);
  });

  test('InvoiceDetail.fromJson maps new fields from JSON', () {
    final json = <String, dynamic>{
      'id': 'inv-1',
      'customer_id': 'cust-1',
      'invoice_number': '42',
      'status': 'ACTIVE',
      'payment_state': 'CREDIT',
      'payment_mode': 'CREDIT',
      'paid_amount': '0',
      'customer_name': 'Test Customer',
      'customer_address': '123 Street',
      'customer_state': 'Maharashtra',
      'customer_state_code': '27',
      'customer_phone': '9999999999',
      'customer_gstin': '27ABCDE1234F1Z5',
      'invoice_date': '2026-01-10',
      'invoice_datetime': '2026-01-10T15:30:00.000Z',
      'subtotal': '200',
      'discount_total': '0',
      'taxable_total': '200',
      'gst_total': '36',
      'grand_total': '236',
      'tax_regime': 'INTRA_STATE',
      'place_of_supply_state': 'Maharashtra',
      'place_of_supply_state_code': '27',
      'company_name': 'Test Company',
      'company_address': '456 Road',
      'company_city': 'Mumbai',
      'company_state': 'Maharashtra',
      'company_state_code': '27',
      'company_gstin': '27XYZW9876A1Z5',
      'company_phone': '9876543210',
      'company_email': 'test@test.com',
      'company_bank_name': 'Test Bank',
      'company_bank_account': '12345',
      'company_bank_ifsc': 'TEST0001234',
      'company_bank_branch': 'Test Branch',
      'items': <dynamic>[],
    };

    final invoice = InvoiceDetail.fromJson(json);

    expect(invoice.customerAddress, '123 Street');
    expect(invoice.customerState, 'Maharashtra');
    expect(invoice.customerStateCode, '27');
    expect(invoice.customerPhone, '9999999999');
    expect(invoice.customerGstin, '27ABCDE1234F1Z5');
    expect(invoice.subtotal, 200);
    expect(invoice.discountTotal, 0);
    expect(invoice.taxableTotal, 200);
    expect(invoice.gstTotal, 36);
    expect(invoice.taxRegime, 'INTRA_STATE');
    expect(invoice.placeOfSupplyState, 'Maharashtra');
    expect(invoice.placeOfSupplyStateCode, '27');
    expect(invoice.companyName, 'Test Company');
    expect(invoice.companyAddress, '456 Road');
    expect(invoice.companyCity, 'Mumbai');
    expect(invoice.companyState, 'Maharashtra');
    expect(invoice.companyStateCode, '27');
    expect(invoice.companyGstin, '27XYZW9876A1Z5');
    expect(invoice.companyPhone, '9876543210');
    expect(invoice.companyEmail, 'test@test.com');
    expect(invoice.companyBankName, 'Test Bank');
    expect(invoice.companyBankAccount, '12345');
    expect(invoice.companyBankIfsc, 'TEST0001234');
    expect(invoice.companyBankBranch, 'Test Branch');
  });

  test('InvoiceDetailItem.fromJson maps new fields from JSON', () {
    final json = <String, dynamic>{
      'product_id': 'prod-1',
      'product_name': 'Blue Pen',
      'product_item_number': 'PEN-1',
      'product_item_name': 'Blue Pen',
      'product_category': 'Pens',
      'product_company_name': 'Acme',
      'buying_price': '80',
      'selling_price': '118',
      'quantity': '2',
      'line_total': '236',
      'pricing_mode': 'TAX_INCLUSIVE',
      'unit_price_excl_tax': '100',
      'unit_price_incl_tax': '118',
      'gst_rate': '18',
      'cgst_rate': '9',
      'sgst_rate': '9',
      'igst_rate': '0',
      'gst_amount': '36',
      'cgst_amount': '18',
      'sgst_amount': '18',
      'igst_amount': '0',
      'discount_percent': '0',
      'discount_amount': '0',
      'taxable_amount': '200',
    };

    final item = InvoiceDetailItem.fromJson(json);

    expect(item.pricingMode, 'TAX_INCLUSIVE');
    expect(item.unitPriceExclTax, 100);
    expect(item.unitPriceInclTax, 118);
    expect(item.gstRate, 18);
    expect(item.cgstRate, 9);
    expect(item.sgstRate, 9);
    expect(item.igstRate, 0);
    expect(item.gstAmount, 36);
    expect(item.cgstAmount, 18);
    expect(item.sgstAmount, 18);
    expect(item.igstAmount, 0);
    expect(item.discountPercent, 0);
    expect(item.discountAmount, 0);
    expect(item.taxableAmount, 200);
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
    gstin: '27ABCDE1234F1Z5',
    gstFlag: true,
    phone: '9876543210',
    email: 'info@khata.com',
    bankName: 'State Bank',
    bankAccount: '1234567890',
    bankIfsc: 'SBIN0001234',
    bankBranch: 'Mumbai Main',
  );
}

CreateCustomerInput _customerInput({
  String name = 'Acme Stores',
  String phone = '9999999999',
  String state = 'Maharashtra',
  String stateCode = '27',
  String? whatsappNumber,
}) {
  return CreateCustomerInput(
    name: name,
    address: '1 Market Road',
    phone: phone,
    gstin: '27ABCDE1234F1Z5',
    state: state,
    stateCode: stateCode,
    whatsappNumber: whatsappNumber,
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
    hsnCode: '960810',
    quantityOnHand: 5,
    lowStockThreshold: 2,
  );
}

InvoiceDraft _draft({
  required Customer customer,
  required Product product,
  required double quantity,
  String invoiceDate = '2026-01-10',
  String paymentState = 'CREDIT',
  double paidAmount = 0,
  String? paymentMode,
}) {
  return InvoiceDraft(
    customer: customer,
    invoiceDate: invoiceDate,
    paymentState: paymentState,
    paidAmount: paidAmount,
    paymentMode: paymentMode,
    items: <InvoiceDraftItem>[
      InvoiceDraftItem(
        product: product,
        quantity: quantity,
        unitPrice: 118,
      ),
    ],
  );
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
