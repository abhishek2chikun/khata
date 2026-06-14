import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice_detail.dart';
import 'decimal_validators.dart';
import 'invoice_settlement.dart';

PdfPageFormat invoicePdfPageFormatForItemCount(int itemCount) {
  return itemCount <= 15 ? PdfPageFormat.a5 : PdfPageFormat.a4;
}

String invoicePdfDocumentTitle({required bool gstFlag}) {
  return gstFlag ? 'TAX INVOICE' : 'INVOICE';
}

bool invoicePdfIncludesGstSupplySection({required bool gstFlag}) => gstFlag;

bool invoicePdfShowsCanceledBanner({required String status}) =>
    status == 'CANCELED';

bool invoicePdfShowsTaxableTotal({required bool gstFlag}) => gstFlag;

bool invoicePdfShowsHistoricalDiscount(double discountTotal) =>
    discountTotal > 0;

String invoicePdfFormatQuantity(double quantity) =>
    formatInvoiceQuantity(quantity);

String invoicePdfFormatUnitPrice(double price) => canonicalUnitPriceString(price);

List<String> invoicePdfTableHeaders({
  required bool gstFlag,
  required bool isInterState,
}) {
  if (!gstFlag) {
    return <String>['#', 'Item', 'Code', 'Qty', 'Rate', 'Total'];
  }
  final headers = <String>[
    '#',
    'Item',
    'HSN',
    'Qty',
    'Rate',
    'Taxable',
    'GST%',
  ];
  if (isInterState) {
    headers.add('IGST');
  } else {
    headers.addAll(<String>['CGST', 'SGST']);
  }
  headers.add('Total');
  return headers;
}

class InvoicePdfService {
  InvoicePdfService._(this._outputDirectory);

  final Future<String> Function() _outputDirectory;

  factory InvoicePdfService.production() {
    return InvoicePdfService._(
      () => getTemporaryDirectory().then((dir) => dir.path),
    );
  }

  factory InvoicePdfService.withDirectory(String directoryPath) {
    return InvoicePdfService._(
      () async => directoryPath,
    );
  }

  Future<String> generateInvoicePdf(InvoiceDetail invoice) async {
    var pageFormat = invoicePdfPageFormatForItemCount(invoice.items.length);
    var pdf = _buildPdf(invoice, pageFormat);
    if (pageFormat == PdfPageFormat.a5 &&
        pdf.document.pdfPageList.pages.length > 1) {
      pageFormat = PdfPageFormat.a4;
      pdf = _buildPdf(invoice, pageFormat);
    }

    final dir = await _outputDirectory();
    final file = File('$dir/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Document _buildPdf(InvoiceDetail invoice, PdfPageFormat pageFormat) {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
    final isGst = invoice.gstFlag;
    final isA5 = pageFormat == PdfPageFormat.a5;
    final margin = isA5 ? 18.0 : 24.0;
    final smallGap = isA5 ? 4.0 : 4.0;
    final sectionGap = isA5 ? 6.0 : 6.0;
    final majorGap = isA5 ? 8.0 : 8.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        header: (context) => _buildPageHeader(invoice),
        build: (context) => isA5
            ? _buildCompactA5Content(invoice, isGst)
            : <pw.Widget>[
                _buildDocumentHeader(invoice, isGst),
                pw.SizedBox(height: majorGap),
                _buildInvoiceInfo(invoice),
                pw.SizedBox(height: sectionGap),
                _buildPartyInfo(invoice, isGst),
                if (isGst) ...<pw.Widget>[
                  pw.SizedBox(height: sectionGap),
                  _buildGstSupplyInfo(invoice),
                ],
                pw.SizedBox(height: majorGap),
                _buildItemTable(invoice, isGst),
                pw.SizedBox(height: smallGap),
                _buildTotals(invoice, isGst),
                pw.SizedBox(height: sectionGap),
                _buildCompactSettlement(invoice, fontSize: 8),
                pw.SizedBox(height: 8),
                _buildSignatureSpace(invoice, compact: false),
                pw.SizedBox(height: 8),
                _buildFooter(),
              ],
      ),
    );
    return pdf;
  }

  List<pw.Widget> _buildCompactA5Content(InvoiceDetail invoice, bool isGst) {
    return <pw.Widget>[
      _buildCompactHeader(invoice, isGst),
      pw.SizedBox(height: 4),
      _buildCompactInvoiceAndPartyInfo(invoice, isGst),
      if (isGst) ...<pw.Widget>[
        pw.SizedBox(height: 3),
        _buildCompactSupplyInfo(invoice),
      ],
      pw.SizedBox(height: 4),
      _buildCompactItemTable(invoice, isGst),
      pw.SizedBox(height: 4),
      _buildCompactTotals(invoice, isGst),
      pw.SizedBox(height: 4),
      _buildCompactSettlement(invoice),
      pw.SizedBox(height: 5),
      _buildSignatureSpace(invoice, compact: true),
      pw.SizedBox(height: 3),
      _buildFooter(),
    ];
  }

  pw.Widget _buildCompactHeader(InvoiceDetail invoice, bool isGst) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          invoicePdfDocumentTitle(gstFlag: isGst),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(invoice.companyName,
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              _joinNonEmpty(<String?>[
                invoice.companyAddress,
                invoice.companyCity,
                invoice.companyState,
              ]),
              style: pw.TextStyle(fontSize: 6.5),
            ),
            if (isGst && (invoice.companyGstin ?? '').isNotEmpty)
              pw.Text('GSTIN: ${invoice.companyGstin}',
                  style: pw.TextStyle(fontSize: 6.5)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCompactInvoiceAndPartyInfo(
      InvoiceDetail invoice, bool isGst) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _compactText('Invoice #${invoice.invoiceNumber}', bold: true),
                _compactText('Date: ${invoice.invoiceDate}'),
                _compactText(
                  'Payment: ${invoiceSettlementLabel(
                    paymentMode: invoice.paymentMode,
                    paymentState: invoice.paymentState,
                  )}',
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _compactText('Bill To: ${invoice.customerName}', bold: true),
                if (invoice.customerAddress.isNotEmpty)
                  _compactText(invoice.customerAddress),
                if ((invoice.customerState ?? '').isNotEmpty)
                  _compactText(
                      '${invoice.customerState} (${invoice.customerStateCode ?? ''})'),
                if (isGst && (invoice.customerGstin ?? '').isNotEmpty)
                  _compactText('GSTIN: ${invoice.customerGstin}'),
                if ((invoice.customerPhone ?? '').isNotEmpty)
                  _compactText('Phone: ${invoice.customerPhone}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactSupplyInfo(InvoiceDetail invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: _compactText(
        'Place of Supply: ${invoice.placeOfSupplyState} (${invoice.placeOfSupplyStateCode})',
      ),
    );
  }

  pw.Widget _buildCompactItemTable(InvoiceDetail invoice, bool isGst) {
    final isInterState = invoice.taxRegime == 'INTER_STATE';
    final headers = invoicePdfTableHeaders(
      gstFlag: isGst,
      isInterState: isInterState,
    );
    final rows = <List<String>>[];
    for (var index = 0; index < invoice.items.length; index += 1) {
      final item = invoice.items[index];
      final itemName = item.productItemName.isNotEmpty
          ? item.productItemName
          : item.productName;
      rows.add(isGst
          ? <String>[
              '${index + 1}',
              itemName,
              item.productHsnCode ?? '',
              invoicePdfFormatQuantity(item.quantity),
              invoicePdfFormatUnitPrice(item.unitPriceExclTax),
              item.taxableAmount.toStringAsFixed(2),
              item.gstRate.toStringAsFixed(1),
              if (isInterState)
                item.igstAmount.toStringAsFixed(2)
              else ...<String>[
                item.cgstAmount.toStringAsFixed(2),
                item.sgstAmount.toStringAsFixed(2),
              ],
              item.lineTotal.toStringAsFixed(2),
            ]
          : <String>[
              '${index + 1}',
              itemName,
              item.productItemNumber,
              invoicePdfFormatQuantity(item.quantity),
              invoicePdfFormatUnitPrice(item.unitPriceInclTax),
              item.lineTotal.toStringAsFixed(2),
            ]);
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 6),
      headerPadding: const pw.EdgeInsets.all(1.5),
      cellPadding: const pw.EdgeInsets.all(1.5),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: <int, pw.Alignment>{
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
      },
      columnWidths: _compactColumnWidths(
        isGst: isGst,
        isInterState: isInterState,
      ),
    );
  }

  pw.Widget _buildCompactTotals(InvoiceDetail invoice, bool isGst) {
    final parts = <String>[
      'Subtotal: ${invoice.subtotal.toStringAsFixed(2)}',
      if (invoicePdfShowsHistoricalDiscount(invoice.discountTotal))
        'Discount: ${invoice.discountTotal.toStringAsFixed(2)}',
      if (isGst) 'Taxable: ${invoice.taxableTotal.toStringAsFixed(2)}',
      if (isGst) 'GST: ${invoice.gstTotal.toStringAsFixed(2)}',
      'Grand Total: ${invoice.grandTotal.toStringAsFixed(2)}',
    ];
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Text(
        parts.join('   |   '),
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(fontSize: 6.2, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildCompactSettlement(
    InvoiceDetail invoice, {
    double fontSize = 6.5,
  }) {
    final bankParts = <String>[
      if ((invoice.companyBankName ?? '').isNotEmpty) invoice.companyBankName!,
      if ((invoice.companyBankAccount ?? '').isNotEmpty)
        'A/c ${invoice.companyBankAccount}',
      if ((invoice.companyBankIfsc ?? '').isNotEmpty)
        'IFSC ${invoice.companyBankIfsc}',
    ];
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _compactText(
            'Amount in words: ${_numberToWords(invoice.grandTotal)}',
            fontSize: fontSize,
          ),
          _compactText(
            'Payment: ${invoiceSettlementLabel(
              paymentMode: invoice.paymentMode,
              paymentState: invoice.paymentState,
            )}${invoice.paidAmount > 0 ? ' | Paid: ${invoice.paidAmount.toStringAsFixed(2)} | Balance: ${(invoice.grandTotal - invoice.paidAmount).toStringAsFixed(2)}' : ''}',
            fontSize: fontSize,
          ),
          if (bankParts.isNotEmpty)
            _compactText('Bank: ${bankParts.join(' | ')}', fontSize: fontSize),
          if ((invoice.notes ?? '').isNotEmpty)
            _compactText('Notes: ${invoice.notes}', fontSize: fontSize),
        ],
      ),
    );
  }

  pw.Widget _compactText(
    String value, {
    bool bold = false,
    double fontSize = 6.5,
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  pw.Widget _buildPageHeader(InvoiceDetail invoice) {
    if (!invoicePdfShowsCanceledBanner(status: invoice.status)) {
      return pw.SizedBox();
    }
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red, width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          'CANCELED',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildDocumentHeader(InvoiceDetail invoice, bool isGst) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.Text(
          invoicePdfDocumentTitle(gstFlag: isGst),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          invoice.companyName,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (invoice.companyAddress.isNotEmpty)
          pw.Text(invoice.companyAddress, style: pw.TextStyle(fontSize: 10)),
        if (invoice.companyCity.isNotEmpty || invoice.companyState.isNotEmpty)
          pw.Text(
            _joinNonEmpty([invoice.companyCity, invoice.companyState]),
            style: pw.TextStyle(fontSize: 10),
          ),
        if (isGst &&
            invoice.companyGstin != null &&
            invoice.companyGstin!.isNotEmpty)
          pw.Text('GSTIN: ${invoice.companyGstin}',
              style: pw.TextStyle(fontSize: 10)),
        if (invoice.companyPhone != null && invoice.companyPhone!.isNotEmpty)
          pw.Text('Phone: ${invoice.companyPhone}',
              style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildPartyInfo(InvoiceDetail invoice, bool isGst) {
    return _buildCustomerAndCompanyInfo(invoice, isGst);
  }

  pw.Widget _buildGstSupplyInfo(InvoiceDetail invoice) {
    return _buildPlaceOfSupplyInfo(invoice);
  }

  pw.Widget _buildTotals(InvoiceDetail invoice, bool isGst) {
    return pw.Inseparable(child: _buildTotalsTable(invoice, isGst));
  }

  pw.Widget _buildInvoiceInfo(InvoiceDetail invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _infoRow('Invoice No:', '#${invoice.invoiceNumber}'),
                _infoRow('Date:', invoice.invoiceDate),
                _infoRow(
                  'Payment:',
                  invoiceSettlementLabel(
                    paymentMode: invoice.paymentMode,
                    paymentState: invoice.paymentState,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                if (invoice.paidAmount > 0)
                  _infoRow(
                    'Received:',
                    invoice.paidAmount.toStringAsFixed(2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerAndCompanyInfo(InvoiceDetail invoice, bool isGst) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text('Bill To',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.customerName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (invoice.customerAddress.isNotEmpty)
                  pw.Text(invoice.customerAddress,
                      style: pw.TextStyle(fontSize: 9)),
                if (invoice.customerState != null &&
                    invoice.customerState!.isNotEmpty)
                  pw.Text(
                    '${invoice.customerState}${invoice.customerStateCode != null ? ' (${invoice.customerStateCode})' : ''}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                if (isGst &&
                    invoice.customerGstin != null &&
                    invoice.customerGstin!.isNotEmpty)
                  pw.Text('GSTIN: ${invoice.customerGstin}',
                      style: pw.TextStyle(fontSize: 9)),
                if (invoice.customerPhone != null &&
                    invoice.customerPhone!.isNotEmpty)
                  pw.Text('Phone: ${invoice.customerPhone}',
                      style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text('Seller',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.companyName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (invoice.companyAddress.isNotEmpty)
                  pw.Text(invoice.companyAddress,
                      style: pw.TextStyle(fontSize: 9)),
                if (invoice.companyCity.isNotEmpty ||
                    invoice.companyState.isNotEmpty)
                  pw.Text(
                    _joinNonEmpty([invoice.companyCity, invoice.companyState]),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                if (isGst &&
                    invoice.companyGstin != null &&
                    invoice.companyGstin!.isNotEmpty)
                  pw.Text('GSTIN: ${invoice.companyGstin}',
                      style: pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPlaceOfSupplyInfo(InvoiceDetail invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              'Place of Supply: ${invoice.placeOfSupplyState} (${invoice.placeOfSupplyStateCode})',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemTable(InvoiceDetail invoice, bool isGst) {
    final isInterState = invoice.taxRegime == 'INTER_STATE';
    final headers = invoicePdfTableHeaders(
      gstFlag: isGst,
      isInterState: isInterState,
    );
    final headerWidgets = headers
        .map(
          (header) => pw.Padding(
            padding: const pw.EdgeInsets.all(2.5),
            child: pw.Text(
              header,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
            ),
          ),
        )
        .toList();
    final rows = <List<pw.Widget>>[];
    for (var index = 0; index < invoice.items.length; index += 1) {
      final item = invoice.items[index];
      final itemName = item.productItemName.isNotEmpty
          ? item.productItemName
          : item.productName;
      if (!isGst) {
        rows.add(<pw.Widget>[
          _serialCell('${index + 1}'),
          _cell(itemName),
          _cell(item.productItemNumber),
          _cell(
            invoicePdfFormatQuantity(item.quantity),
            align: pw.Alignment.centerRight,
          ),
          _cell(
            invoicePdfFormatUnitPrice(item.unitPriceInclTax),
            align: pw.Alignment.centerRight,
          ),
          _cell(
            item.lineTotal.toStringAsFixed(2),
            align: pw.Alignment.centerRight,
          ),
        ]);
        continue;
      }
      final row = <pw.Widget>[
        _serialCell('${index + 1}'),
        _cell(itemName),
        _cell(item.productHsnCode ?? ''),
        _cell(
          invoicePdfFormatQuantity(item.quantity),
          align: pw.Alignment.centerRight,
        ),
        _cell(
          invoicePdfFormatUnitPrice(item.unitPriceExclTax),
          align: pw.Alignment.centerRight,
        ),
        _cell(
          item.taxableAmount.toStringAsFixed(2),
          align: pw.Alignment.centerRight,
        ),
        _cell(
          item.gstRate.toStringAsFixed(1),
          align: pw.Alignment.centerRight,
        ),
      ];
      if (!isInterState) {
        row.add(_cell(
          item.cgstAmount.toStringAsFixed(2),
          align: pw.Alignment.centerRight,
        ));
        row.add(_cell(
          item.sgstAmount.toStringAsFixed(2),
          align: pw.Alignment.centerRight,
        ));
      } else {
        row.add(_cell(
          item.igstAmount.toStringAsFixed(2),
          align: pw.Alignment.centerRight,
        ));
      }
      row.add(_cell(
        item.lineTotal.toStringAsFixed(2),
        align: pw.Alignment.centerRight,
      ));
      rows.add(row);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: isGst
          ? _buildColumnWidths(isInterState)
          : _buildNonGstColumnWidths(),
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headerWidgets,
        ),
        ...rows.map((row) => pw.TableRow(children: row)),
      ],
    );
  }

  Map<int, pw.TableColumnWidth> _compactColumnWidths({
    required bool isGst,
    required bool isInterState,
  }) {
    if (!isGst) {
      return <int, pw.TableColumnWidth>{
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(2),
      };
    }
    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(18),
      1: const pw.FlexColumnWidth(3.5),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(2),
      5: const pw.FlexColumnWidth(2),
      6: const pw.FlexColumnWidth(1.5),
    };
    if (!isInterState) {
      widths[7] = const pw.FlexColumnWidth(1.8);
      widths[8] = const pw.FlexColumnWidth(1.8);
      widths[9] = const pw.FlexColumnWidth(2.2);
    } else {
      widths[7] = const pw.FlexColumnWidth(2);
      widths[8] = const pw.FlexColumnWidth(2.2);
    }
    return widths;
  }

  Map<int, pw.FlexColumnWidth> _buildNonGstColumnWidths() {
    return <int, pw.FlexColumnWidth>{
      0: const pw.FlexColumnWidth(1.8),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(2.2),
      5: const pw.FlexColumnWidth(2.2),
    };
  }

  Map<int, pw.FlexColumnWidth> _buildColumnWidths(bool isInterState) {
    final widths = <int, pw.FlexColumnWidth>{
      0: const pw.FlexColumnWidth(1.8),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(2.2),
      5: const pw.FlexColumnWidth(2),
      6: const pw.FlexColumnWidth(1.5),
    };
    if (!isInterState) {
      widths[7] = const pw.FlexColumnWidth(2);
      widths[8] = const pw.FlexColumnWidth(2);
      widths[9] = const pw.FlexColumnWidth(2.5);
    } else {
      widths[7] = const pw.FlexColumnWidth(2);
      widths[8] = const pw.FlexColumnWidth(2.5);
    }
    return widths;
  }

  pw.Widget _buildTotalsTable(InvoiceDetail invoice, bool isGst) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          children: <pw.Widget>[
            _totalRow('Subtotal:', invoice.subtotal.toStringAsFixed(2)),
            if (invoicePdfShowsHistoricalDiscount(invoice.discountTotal))
              _totalRow(
                'Discount:',
                '-${invoice.discountTotal.toStringAsFixed(2)}',
              ),
            if (invoicePdfShowsTaxableTotal(gstFlag: isGst))
              _totalRow('Taxable:', invoice.taxableTotal.toStringAsFixed(2)),
            if (isGst) _totalRow('GST:', invoice.gstTotal.toStringAsFixed(2)),
            pw.Divider(),
            _totalRow('Grand Total:', invoice.grandTotal.toStringAsFixed(2),
                bold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSignatureSpace(InvoiceDetail invoice,
      {required bool compact}) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 180,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: <pw.Widget>[
            pw.Text(
              'For ${invoice.companyName}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: compact ? 18 : 32),
            pw.Container(height: 1, color: PdfColors.grey500),
            pw.SizedBox(height: 4),
            pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Computer generated invoice',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, {pw.Alignment? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 7)),
      ),
    );
  }

  pw.Widget _serialCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.SizedBox(
        width: 18,
        child: pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            text,
            maxLines: 1,
            style: pw.TextStyle(fontSize: 7),
          ),
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 9,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  String _joinNonEmpty(List<String?> parts, {String separator = ', '}) {
    return parts.where((p) => p != null && p.isNotEmpty).join(separator);
  }

  String _numberToWords(double amount) {
    final rupees = amount.truncate();
    final paise = ((amount - rupees) * 100).round();
    final rupeeWords = _convert(rupees);
    if (paise == 0) {
      return '$rupeeWords rupees only';
    }
    return '$rupeeWords rupees and ${_convert(paise)} paise only';
  }

  String _convert(int number) {
    if (number == 0) return 'zero';
    if (number < 0) return 'minus ${_convert(-number)}';

    const below20 = <String>[
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    const tens = <String>[
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    var words = '';
    var n = number;

    if (n >= 10000000) {
      words += '${_convert(n ~/ 10000000)} crore ';
      n %= 10000000;
    }
    if (n >= 100000) {
      words += '${_convert(n ~/ 100000)} lakh ';
      n %= 100000;
    }
    if (n >= 1000) {
      words += '${_convert(n ~/ 1000)} thousand ';
      n %= 1000;
    }
    if (n >= 100) {
      words += '${below20[n ~/ 100]} hundred ';
      n %= 100;
    }
    if (n >= 20) {
      words += '${tens[n ~/ 10]} ${below20[n % 10]}';
    } else if (n > 0) {
      words += below20[n];
    }

    return words.trim();
  }
}
