import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/models/customer.dart';
import 'package:internal_billing_khata_mobile/models/invoice_draft.dart';
import 'package:internal_billing_khata_mobile/models/invoice_quote.dart';
import 'package:internal_billing_khata_mobile/models/product.dart';
import 'package:internal_billing_khata_mobile/services/invoice_preview_builder.dart';
import 'package:internal_billing_khata_mobile/services/invoice_settlement.dart';

void main() {
  const company = CompanyProfile(
    id: 'company-1',
    name: 'Acme Traders',
    address: 'Main Road',
    city: 'Pune',
    state: 'Maharashtra',
    stateCode: '27',
    gstin: '27AAAAA0000A1Z5',
    gstFlag: true,
    phone: '9999999999',
    email: 'owner@example.com',
    bankName: 'ABC Bank',
    bankAccount: '1234567890',
    bankIfsc: 'ABC0001234',
    bankBranch: 'Pune',
    jurisdiction: 'Pune',
    isActive: true,
  );

  const customer = Customer(
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

  const product = Product(
    id: 'product-1',
    companyName: 'Camlin',
    category: 'Pens',
    itemName: 'Blue Pen',
    itemNumber: 'PEN-1',
    buyingPrice: 80,
    sellingPrice: 118,
    unit: 'PCS',
    gstRate: 18,
    hsnCode: '960810',
    quantityOnHand: 10,
    lowStockThreshold: 2,
    isActive: true,
  );

  const gstQuote = InvoiceQuote(
    placeOfSupplyState: 'Maharashtra',
    placeOfSupplyStateCode: '27',
    taxRegime: 'INTRA_STATE',
    gstFlag: true,
    items: <InvoiceQuoteItem>[
      InvoiceQuoteItem(
        productId: 'product-1',
        productItemName: 'Blue Pen',
        productItemNumber: 'PEN-1',
        productCategory: 'Pens',
        productHsnCode: '960810',
        unit: 'PCS',
        quantity: 2,
        enteredUnitPrice: 118,
        unitPriceExclTax: 100,
        unitPriceInclTax: 118,
        gstRate: 18,
        cgstRate: 9,
        sgstRate: 9,
        gstAmount: 36,
        cgstAmount: 18,
        sgstAmount: 18,
        taxableAmount: 200,
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

  test('buildPreviewInvoiceDetail maps gst quote into invoice detail', () {
    final draft = InvoiceDraft(
      customer: customer,
      invoiceDate: '2026-04-19',
      paymentMode: settlementModeCredit,
      items: const <InvoiceDraftItem>[
        InvoiceDraftItem(product: product, quantity: 2, unitPrice: 118),
      ],
    );

    final preview = buildPreviewInvoiceDetail(
      draft: draft,
      quote: gstQuote,
      company: company,
    );

    expect(preview.invoiceNumber, previewInvoiceNumber);
    expect(preview.status, 'PREVIEW');
    expect(preview.customerName, 'ABC Stores');
    expect(preview.companyName, 'Acme Traders');
    expect(preview.companyGstin, '27AAAAA0000A1Z5');
    expect(preview.gstFlag, isTrue);
    expect(preview.grandTotal, 236);
    expect(preview.items.single.productHsnCode, '960810');
    expect(preview.items.single.cgstAmount, 18);
  });

  test('buildPreviewInvoiceDetail omits company gstin for non-gst quote', () {
    const nonGstQuote = InvoiceQuote(
      placeOfSupplyState: 'Maharashtra',
      placeOfSupplyStateCode: '27',
      taxRegime: 'INTRA_STATE',
      gstFlag: false,
      items: <InvoiceQuoteItem>[
        InvoiceQuoteItem(
          productId: 'product-1',
          productItemName: 'Blue Pen',
          productItemNumber: 'PEN-1',
          productCategory: 'Pens',
          unit: 'PCS',
          quantity: 1,
          enteredUnitPrice: 100,
          unitPriceExclTax: 100,
          unitPriceInclTax: 100,
          lineTotal: 100,
        ),
      ],
      totals: InvoiceTotals(
        subtotal: 100,
        discountTotal: 0,
        taxableTotal: 100,
        gstTotal: 0,
        grandTotal: 100,
      ),
      warnings: <InvoiceWarning>[],
    );

    final draft = InvoiceDraft(
      customer: customer,
      invoiceDate: '2026-04-19',
      items: const <InvoiceDraftItem>[
        InvoiceDraftItem(product: product, quantity: 1, unitPrice: 100),
      ],
    );

    final preview = buildPreviewInvoiceDetail(
      draft: draft,
      quote: nonGstQuote,
      company: company,
    );

    expect(preview.gstFlag, isFalse);
    expect(preview.companyGstin, isNull);
    expect(preview.gstTotal, 0);
  });
}
