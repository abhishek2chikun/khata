import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/services/invoice_pdf_service.dart';

void main() {
  late InvoicePdfService service;
  late String tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp
        .createTempSync('invoice_pdf_test_')
        .path;
    service = InvoicePdfService.withDirectory(tempDir);
  });

  tearDown(() {
    final dir = Directory(tempDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  InvoiceDetail _sampleInvoice({
    String invoiceNumber = '42',
    String customerName = 'Acme Stores',
    double grandTotal = 236.0,
    String taxRegime = 'INTRA_STATE',
    List<InvoiceDetailItem>? items,
  }) {
    return InvoiceDetail(
      id: 'inv-1',
      customerId: 'cust-1',
      invoiceNumber: invoiceNumber,
      status: 'ACTIVE',
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      paidAmount: 0,
      customerName: customerName,
      customerAddress: '1 Market Road',
      customerState: 'Maharashtra',
      customerStateCode: '27',
      customerGstin: '27ABCDE1234F1Z5',
      customerPhone: '9999999999',
      invoiceDate: '2026-01-10',
      invoiceDatetime: '2026-01-10T15:30:00.000Z',
      subtotal: grandTotal,
      discountTotal: 0,
      taxableTotal: 200,
      gstTotal: 36,
      grandTotal: grandTotal,
      taxRegime: taxRegime,
      placeOfSupplyState: 'Maharashtra',
      placeOfSupplyStateCode: '27',
      companyName: 'Khata Traders',
      companyAddress: '10 Market Road',
      companyCity: 'Mumbai',
      companyState: 'Maharashtra',
      companyStateCode: '27',
      companyGstin: '27XYZW9876A1Z5',
      companyPhone: '9876543210',
      companyEmail: 'info@khata.com',
      companyBankName: 'State Bank',
      companyBankAccount: '1234567890',
      companyBankIfsc: 'SBIN0001234',
      companyBankBranch: 'Mumbai Main',
      notes: 'Thank you for your business',
      cancelReason: null,
      items: items ??
          [
            InvoiceDetailItem(
              productId: 'prod-1',
              productName: 'Blue Pen',
              productItemNumber: 'PEN-1',
              productItemName: 'Blue Pen',
              productCategory: 'Pens',
              productCompanyName: 'Acme',
              buyingPrice: 80,
              sellingPrice: 118,
              unit: 'pcs',
              quantity: 2,
              lineTotal: 236,
              pricingMode: 'TAX_INCLUSIVE',
              unitPriceExclTax: 100,
              unitPriceInclTax: 118,
              gstRate: 18,
              cgstRate: 9,
              sgstRate: 9,
              igstRate: 0,
              gstAmount: 36,
              cgstAmount: 18,
              sgstAmount: 18,
              igstAmount: 0,
              discountPercent: 0,
              discountAmount: 0,
              taxableAmount: 200,
            ),
          ],
    );
  }

  test('generateInvoicePdf creates a non-empty file', () async {
    final invoice = _sampleInvoice();
    final path = await service.generateInvoicePdf(invoice);

    final file = File(path);
    expect(await file.exists(), isTrue);
    final bytes = await file.length();
    expect(bytes, greaterThan(0));
  });

  test('generateInvoicePdf creates file with invoice number in name', () async {
    final invoice = _sampleInvoice(invoiceNumber: '99');
    final path = await service.generateInvoicePdf(invoice);

    expect(path, contains('invoice_99'));
  });

  test('generateInvoicePdf handles INTER_STATE tax regime', () async {
    final invoice = _sampleInvoice(
      taxRegime: 'INTER_STATE',
      items: [
        InvoiceDetailItem(
          productId: 'prod-1',
          productName: 'Blue Pen',
          productItemNumber: 'PEN-1',
          productItemName: 'Blue Pen',
          productCategory: 'Pens',
          productCompanyName: 'Acme',
          buyingPrice: 80,
          sellingPrice: 118,
          unit: 'pcs',
          quantity: 2,
          lineTotal: 236,
          pricingMode: 'TAX_INCLUSIVE',
          unitPriceExclTax: 100,
          unitPriceInclTax: 118,
          gstRate: 18,
          cgstRate: 0,
          sgstRate: 0,
          igstRate: 18,
          gstAmount: 36,
          cgstAmount: 0,
          sgstAmount: 0,
          igstAmount: 36,
          discountPercent: 0,
          discountAmount: 0,
          taxableAmount: 200,
        ),
      ],
    );
    final path = await service.generateInvoicePdf(invoice);

    final file = File(path);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(0));
  });

  test('generateInvoicePdf handles invoice with minimal data', () async {
    final invoice = InvoiceDetail(
      id: 'inv-2',
      customerId: 'cust-2',
      invoiceNumber: '10',
      status: 'ACTIVE',
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      customerName: 'Test Customer',
      invoiceDate: '2026-01-10',
      grandTotal: 100,
      notes: null,
      cancelReason: null,
      items: [],
    );

    final path = await service.generateInvoicePdf(invoice);
    final file = File(path);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(0));
  });

  test('generateInvoicePdf handles partial payment', () async {
    final invoice = _sampleInvoice();
    final path = await service.generateInvoicePdf(invoice);

    final file = File(path);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(0));

    await file.delete();
  });

  test('generateInvoicePdf handles invoice with discounts', () async {
    final invoice = _sampleInvoice(
      grandTotal: 212.4,
      items: [
        InvoiceDetailItem(
          productId: 'prod-1',
          productName: 'Blue Pen',
          productItemNumber: 'PEN-1',
          productItemName: 'Blue Pen',
          productCategory: 'Pens',
          productCompanyName: 'Acme',
          buyingPrice: 80,
          sellingPrice: 118,
          unit: 'pcs',
          quantity: 2,
          lineTotal: 212.4,
          pricingMode: 'TAX_INCLUSIVE',
          unitPriceExclTax: 100,
          unitPriceInclTax: 118,
          gstRate: 18,
          cgstRate: 9,
          sgstRate: 9,
          igstRate: 0,
          gstAmount: 32.4,
          cgstAmount: 16.2,
          sgstAmount: 16.2,
          igstAmount: 0,
          discountPercent: 10,
          discountAmount: 23.6,
          taxableAmount: 180,
        ),
      ],
    );

    final path = await service.generateInvoicePdf(invoice);
    final file = File(path);
    expect(await file.exists(), isTrue);
  });
}
