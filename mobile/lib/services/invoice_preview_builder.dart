import '../models/company_profile.dart';
import '../models/invoice_detail.dart';
import '../models/invoice_draft.dart';
import '../models/invoice_quote.dart';

const previewInvoiceNumber = 'PREVIEW';

InvoiceDetail buildPreviewInvoiceDetail({
  required InvoiceDraft draft,
  required InvoiceQuote quote,
  required CompanyProfile company,
}) {
  final customer = draft.customer;
  return InvoiceDetail(
    id: 'preview',
    customerId: customer?.id ?? '',
    invoiceNumber: previewInvoiceNumber,
    status: 'PREVIEW',
    paymentState: draft.paymentState,
    paymentMode: draft.paymentMode,
    paidAmount: draft.paidAmount,
    customerName: customer?.name ?? '',
    customerAddress: customer?.address ?? '',
    customerState: customer?.state,
    customerStateCode: customer?.stateCode,
    customerPhone: customer?.phone,
    customerWhatsappNumber: customer?.whatsappNumber,
    customerGstin: customer?.gstin,
    invoiceDate: draft.invoiceDate,
    subtotal: quote.totals.subtotal,
    discountTotal: quote.totals.discountTotal,
    taxableTotal: quote.totals.taxableTotal,
    gstTotal: quote.totals.gstTotal,
    grandTotal: quote.totals.grandTotal,
    taxRegime: quote.taxRegime,
    placeOfSupplyState: quote.placeOfSupplyState,
    placeOfSupplyStateCode: quote.placeOfSupplyStateCode,
    companyName: company.name,
    companyAddress: company.address,
    companyCity: company.city,
    companyState: company.state,
    companyStateCode: company.stateCode,
    companyGstin: quote.gstFlag ? company.gstin : null,
    gstFlag: quote.gstFlag,
    companyPhone: company.phone,
    companyEmail: company.email,
    companyBankName: company.bankName,
    companyBankAccount: company.bankAccount,
    companyBankIfsc: company.bankIfsc,
    companyBankBranch: company.bankBranch,
    notes: draft.notes,
    cancelReason: null,
    items: quote.items.map(_toPreviewItem).toList(),
  );
}

InvoiceDetailItem _toPreviewItem(InvoiceQuoteItem item) {
  return InvoiceDetailItem(
    productId: item.productId,
    productName: item.productItemName,
    productItemNumber: item.productItemNumber,
    productItemName: item.productItemName,
    productCategory: item.productCategory,
    productBuyerId: item.productBuyerId,
    productCompanyName: item.productCompanyName,
    productHsnCode: item.productHsnCode,
    buyingPrice: item.buyingPrice,
    sellingPrice: item.sellingPrice,
    unit: item.unit,
    quantity: item.quantity,
    lineTotal: item.lineTotal,
    pricingMode: item.pricingMode,
    unitPriceExclTax: item.unitPriceExclTax,
    unitPriceInclTax: item.unitPriceInclTax,
    gstRate: item.gstRate,
    cgstRate: item.cgstRate,
    sgstRate: item.sgstRate,
    igstRate: item.igstRate,
    gstAmount: item.gstAmount,
    cgstAmount: item.cgstAmount,
    sgstAmount: item.sgstAmount,
    igstAmount: item.igstAmount,
    discountPercent: item.discountPercent,
    discountAmount: item.discountAmount,
    taxableAmount: item.taxableAmount,
  );
}
