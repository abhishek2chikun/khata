import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/invoice_detail.dart';
import 'package:internal_billing_khata_mobile/services/invoice_pdf_service.dart';
import 'package:pdf/pdf.dart';

(String, double, double) _readPdfMeta(File file) {
  final bytes = file.readAsBytesSync();
  final text = latin1.decode(bytes, allowInvalid: true);
  final mediaMatch = RegExp(
    r'/MediaBox\s*\[\s*[\d.]+\s+[\d.]+\s+([\d.]+)\s+([\d.]+)\s*\]',
  ).firstMatch(text);
  final width = mediaMatch == null ? 0.0 : double.parse(mediaMatch.group(1)!);
  final height = mediaMatch == null ? 0.0 : double.parse(mediaMatch.group(2)!);
  return (text, width, height);
}

int _readPdfPageCount(File file) {
  final text = latin1.decode(file.readAsBytesSync(), allowInvalid: true);
  final count = RegExp(r'/Count\s+(\d+)').firstMatch(text);
  return count == null ? 0 : int.parse(count.group(1)!);
}

InvoiceDetailItem _lineItem({int index = 1, String? itemName}) {
  return InvoiceDetailItem(
    productId: 'prod-$index',
    productName: itemName ?? 'Item $index',
    productItemNumber: 'SKU-$index',
    productItemName: itemName ?? 'Item $index',
    productCategory: 'General',
    productCompanyName: 'Acme',
    buyingPrice: 80,
    sellingPrice: 118,
    unit: 'pcs',
    quantity: 1,
    lineTotal: 118,
    pricingMode: 'TAX_INCLUSIVE',
    unitPriceExclTax: 100,
    unitPriceInclTax: 118,
    gstRate: 18,
    cgstRate: 9,
    sgstRate: 9,
    igstRate: 0,
    gstAmount: 18,
    cgstAmount: 9,
    sgstAmount: 9,
    igstAmount: 0,
    discountPercent: 0,
    discountAmount: 0,
    taxableAmount: 100,
  );
}

void main() {
  late InvoicePdfService service;
  late String tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('invoice_pdf_test_').path;
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
    bool gstFlag = true,
    String status = 'ACTIVE',
    String customerAddress = '1 Market Road',
    String companyAddress = '10 Market Road',
    String? notes = 'Thank you for your business',
    List<InvoiceDetailItem>? items,
  }) {
    return InvoiceDetail(
      id: 'inv-1',
      customerId: 'cust-1',
      invoiceNumber: invoiceNumber,
      status: status,
      paymentState: 'CREDIT',
      paymentMode: 'CREDIT',
      paidAmount: 0,
      gstFlag: gstFlag,
      customerName: customerName,
      customerAddress: customerAddress,
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
      companyAddress: companyAddress,
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
      notes: notes,
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

  test('uses A5 when the complete GST invoice fits on one half page', () async {
    final invoice = _sampleInvoice(
      items:
          List<InvoiceDetailItem>.generate(1, (i) => _lineItem(index: i + 1)),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(420, 5));
    expect(height, closeTo(595, 5));
  });

  test('uses A5 when the complete non-GST invoice fits on one half page',
      () async {
    final invoice = _sampleInvoice(
      gstFlag: false,
      items:
          List<InvoiceDetailItem>.generate(1, (i) => _lineItem(index: i + 1)),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(420, 5));
    expect(height, closeTo(595, 5));
  });

  test('uses A5 for a standard 15-row GST invoice',
      () async {
    final invoice = _sampleInvoice(
      items:
          List<InvoiceDetailItem>.generate(15, (i) => _lineItem(index: i + 1)),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(420, 5));
    expect(height, closeTo(595, 5));
  });

  test('uses A5 for a standard 15-row non-GST invoice',
      () async {
    final invoice = _sampleInvoice(
      gstFlag: false,
      items:
          List<InvoiceDetailItem>.generate(15, (i) => _lineItem(index: i + 1)),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(420, 5));
    expect(height, closeTo(595, 5));
  });

  test('falls back to A4 when verbose content does not fit one A5 page',
      () async {
    final longText = List<String>.filled(
      20,
      'extra descriptive product and delivery information',
    ).join(' ');
    final invoice = _sampleInvoice(
      customerAddress: longText,
      companyAddress: longText,
      notes: longText,
      items: List<InvoiceDetailItem>.generate(
        15,
        (i) => _lineItem(index: i + 1, itemName: '$longText ${i + 1}'),
      ),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(595, 5));
    expect(height, closeTo(842, 5));
  });

  test('uses A4 directly for more than 15 line items', () async {
    final invoice = _sampleInvoice(
      items:
          List<InvoiceDetailItem>.generate(16, (i) => _lineItem(index: i + 1)),
    );
    final path = await service.generateInvoicePdf(invoice);
    final (_, width, height) = _readPdfMeta(File(path));

    expect(width, closeTo(595, 5));
    expect(height, closeTo(842, 5));
    expect(_readPdfPageCount(File(path)), 1);
  });

  test('gst invoice includes tax invoice title and gst columns', () {
    expect(invoicePdfDocumentTitle(gstFlag: true), 'TAX INVOICE');
    expect(invoicePdfIncludesGstSupplySection(gstFlag: true), isTrue);
    expect(
      invoicePdfTableHeaders(gstFlag: true, isInterState: false),
      contains('HSN'),
    );
  });

  test('non-gst invoice omits gst-specific content', () {
    expect(invoicePdfDocumentTitle(gstFlag: false), 'INVOICE');
    expect(invoicePdfIncludesGstSupplySection(gstFlag: false), isFalse);
    expect(invoicePdfShowsTaxableTotal(gstFlag: false), isFalse);
    expect(invoicePdfShowsTaxableTotal(gstFlag: true), isTrue);
    final headers = invoicePdfTableHeaders(gstFlag: false, isInterState: false);
    expect(headers, isNot(contains('HSN')));
    expect(headers, isNot(contains('GST%')));
  });

  test('pdf helpers format integer quantity and three-decimal price', () {
    expect(invoicePdfFormatQuantity(2), '2');
    expect(invoicePdfFormatQuantity(2.5), '2.5');
    expect(invoicePdfFormatUnitPrice(12.3), '12.300');
  });

  test('historical discount summary remains when discount_total is positive', () {
    expect(invoicePdfShowsHistoricalDiscount(10), isTrue);
    expect(invoicePdfShowsHistoricalDiscount(0), isFalse);
  });

  test('gst pdf table uses hsn snapshot in headers and row formatting', () {
    final headers =
        invoicePdfTableHeaders(gstFlag: true, isInterState: false);
    expect(headers, contains('HSN'));
    expect(headers, isNot(contains('Disc')));

    expect(
      invoicePdfFormatUnitPrice(100),
      '100.000',
    );
    expect(invoicePdfFormatQuantity(10), '10');
    expect(invoicePdfFormatQuantity(11), '11');
  });

  test('non-gst pdf table omits hsn and gst columns', () {
    final headers =
        invoicePdfTableHeaders(gstFlag: false, isInterState: false);
    expect(headers, isNot(contains('HSN')));
    expect(headers, isNot(contains('GST%')));
    expect(headers, contains('Code'));
  });

  test('legacy discounted invoice keeps compact discount summary', () async {
    expect(invoicePdfShowsHistoricalDiscount(23.6), isTrue);
    final base = _sampleInvoice(
      grandTotal: 212.4,
      items: [
        InvoiceDetailItem(
          productId: 'prod-1',
          productName: 'Blue Pen',
          productItemNumber: 'PEN-1',
          productItemName: 'Blue Pen',
          productHsnCode: '960810',
          unit: 'pcs',
          quantity: 2,
          unitPriceExclTax: 100,
          unitPriceInclTax: 118,
          gstRate: 18,
          discountPercent: 10,
          discountAmount: 23.6,
          taxableAmount: 180,
          cgstAmount: 16.2,
          sgstAmount: 16.2,
          gstAmount: 32.4,
          lineTotal: 212.4,
        ),
      ],
    );
    final invoice = InvoiceDetail(
      id: base.id,
      customerId: base.customerId,
      invoiceNumber: base.invoiceNumber,
      status: base.status,
      paymentState: base.paymentState,
      paymentMode: base.paymentMode,
      customerName: base.customerName,
      invoiceDate: base.invoiceDate,
      grandTotal: 212.4,
      discountTotal: 23.6,
      taxableTotal: 180,
      gstTotal: 32.4,
      subtotal: 200,
      notes: base.notes,
      cancelReason: base.cancelReason,
      items: base.items,
    );
    final path = await service.generateInvoicePdf(invoice);
    final file = File(path);
    expect(await file.exists(), isTrue);
  });

  test('canceled invoice shows canceled marker', () {
    expect(invoicePdfShowsCanceledBanner(status: 'CANCELED'), isTrue);
    expect(invoicePdfShowsCanceledBanner(status: 'ACTIVE'), isFalse);
  });

  test('page format helper caps A5 candidates at 15 rows', () {
    expect(
      invoicePdfPageFormatForItemCount(15),
      PdfPageFormat.a5,
    );
    expect(
      invoicePdfPageFormatForItemCount(16),
      PdfPageFormat.a4,
    );
  });
}
