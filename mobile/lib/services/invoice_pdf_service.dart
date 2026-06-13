import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice_detail.dart';

PdfPageFormat invoicePdfPageFormatForItemCount(int itemCount) {
  return itemCount <= 10 ? PdfPageFormat.a5 : PdfPageFormat.a4;
}

String invoicePdfDocumentTitle({required bool gstFlag}) {
  return gstFlag ? 'TAX INVOICE' : 'INVOICE';
}

bool invoicePdfIncludesGstSupplySection({required bool gstFlag}) => gstFlag;

bool invoicePdfShowsCanceledBanner({required String status}) =>
    status == 'CANCELED';

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
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
    final isGst = invoice.gstFlag;
    final pageFormat = invoicePdfPageFormatForItemCount(invoice.items.length);
    final margin = invoice.items.length <= 10 ? 28.0 : 36.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        header: (context) => _buildPageHeader(invoice),
        build: (context) => <pw.Widget>[
          _buildDocumentHeader(invoice, isGst),
          pw.SizedBox(height: 16),
          _buildInvoiceInfo(invoice),
          pw.SizedBox(height: 12),
          _buildPartyInfo(invoice, isGst),
          if (isGst) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            _buildGstSupplyInfo(invoice),
          ],
          pw.SizedBox(height: 16),
          _buildItemTable(invoice, isGst),
          pw.SizedBox(height: 8),
          _buildTotals(invoice, isGst),
          pw.SizedBox(height: 12),
          _buildAmountInWords(invoice),
          pw.SizedBox(height: 12),
          _buildPaymentInfo(invoice),
          if (_hasBankDetails(invoice)) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            _buildBankDetails(invoice),
          ],
          if ((invoice.notes ?? '').isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            _buildNotes(invoice),
          ],
          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    final dir = await _outputDirectory();
    final file = File('$dir/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
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

  pw.Widget _buildHeader(InvoiceDetail invoice) {
    return _buildDocumentHeader(invoice, invoice.gstFlag);
  }

  pw.Widget _buildPartyInfo(InvoiceDetail invoice, bool isGst) {
    return _buildCustomerAndCompanyInfo(invoice, isGst);
  }

  pw.Widget _buildGstSupplyInfo(InvoiceDetail invoice) {
    return _buildPlaceOfSupplyInfo(invoice);
  }

  pw.Widget _buildTotals(InvoiceDetail invoice, bool isGst) {
    return _buildTotalsTable(invoice, isGst);
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
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _infoRow('Status:', invoice.status),
                _infoRow('Payment:', invoice.paymentState),
                if (invoice.paymentMode.isNotEmpty)
                  _infoRow('Mode:', invoice.paymentMode),
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
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.customerName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (invoice.customerAddress.isNotEmpty)
                  pw.Text(invoice.customerAddress, style: pw.TextStyle(fontSize: 9)),
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
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.companyName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (invoice.companyAddress.isNotEmpty)
                  pw.Text(invoice.companyAddress, style: pw.TextStyle(fontSize: 9)),
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
          pw.Expanded(
            child: pw.Text(
              'Tax Regime: ${invoice.taxRegime}',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemTable(InvoiceDetail invoice, bool isGst) {
    if (!isGst) {
      final headers = <String>['#', 'Item', 'Code', 'Qty', 'Rate', 'Disc%', 'Total'];
      final headerWidgets = headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 7),
                ),
              ))
          .toList();
      final rows = <List<pw.Widget>>[];
      for (var i = 0; i < invoice.items.length; i++) {
        final item = invoice.items[i];
        rows.add(<pw.Widget>[
          _cell('${i + 1}', align: pw.Alignment.centerRight),
          _cell(item.productItemName.isNotEmpty
              ? item.productItemName
              : item.productName),
          _cell(item.productItemNumber),
          _cell(item.quantity.toStringAsFixed(2),
              align: pw.Alignment.centerRight),
          _cell(item.unitPriceInclTax.toStringAsFixed(2),
              align: pw.Alignment.centerRight),
          _cell(item.discountPercent.toStringAsFixed(1),
              align: pw.Alignment.centerRight),
          _cell(item.lineTotal.toStringAsFixed(2),
              align: pw.Alignment.centerRight),
        ]);
      }
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: <int, pw.FlexColumnWidth>{
          for (var i = 0; i < headers.length; i++)
            i: const pw.FlexColumnWidth(2),
        },
        children: <pw.TableRow>[
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: headerWidgets,
          ),
          ...rows.map((row) => pw.TableRow(children: row)),
        ],
      );
    }

    final isInterState = invoice.taxRegime == 'INTER_STATE';
    final headers = <String>[
      '#',
      'Item',
      'HSN',
      'Qty',
      'Rate',
      'Disc%',
      'Taxable',
      'GST%',
    ];
    if (!isInterState) {
      headers.addAll(['CGST', 'SGST']);
    } else {
      headers.add('IGST');
    }
    headers.add('Total');

    final headerWidgets = headers
        .map((h) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 7),
              ),
            ))
        .toList();

    final rows = <List<pw.Widget>>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final row = <pw.Widget>[
        _cell('${i + 1}', align: pw.Alignment.centerRight),
        _cell(item.productItemName.isNotEmpty
            ? item.productItemName
            : item.productName),
        _cell(item.productItemNumber),
        _cell(item.quantity.toStringAsFixed(2), align: pw.Alignment.centerRight),
        _cell(item.unitPriceExclTax.toStringAsFixed(2),
            align: pw.Alignment.centerRight),
        _cell(item.discountPercent.toStringAsFixed(1),
            align: pw.Alignment.centerRight),
        _cell(item.taxableAmount.toStringAsFixed(2),
            align: pw.Alignment.centerRight),
        _cell(item.gstRate.toStringAsFixed(1), align: pw.Alignment.centerRight),
      ];
      if (!isInterState) {
        row.add(_cell(item.cgstAmount.toStringAsFixed(2),
            align: pw.Alignment.centerRight));
        row.add(_cell(item.sgstAmount.toStringAsFixed(2),
            align: pw.Alignment.centerRight));
      } else {
        row.add(_cell(item.igstAmount.toStringAsFixed(2),
            align: pw.Alignment.centerRight));
      }
      row.add(_cell(item.lineTotal.toStringAsFixed(2),
          align: pw.Alignment.centerRight));
      rows.add(row);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: _buildColumnWidths(isInterState),
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headerWidgets,
        ),
        ...rows.map((row) => pw.TableRow(children: row)),
      ],
    );
  }

  Map<int, pw.FlexColumnWidth> _buildColumnWidths(bool isInterState) {
    final widths = <int, pw.FlexColumnWidth>{
      0: const pw.FlexColumnWidth(1.2),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(2),
      4: const pw.FlexColumnWidth(2),
      5: const pw.FlexColumnWidth(1.5),
      6: const pw.FlexColumnWidth(2),
      7: const pw.FlexColumnWidth(1.5),
    };
    if (!isInterState) {
      widths[8] = const pw.FlexColumnWidth(2);
      widths[9] = const pw.FlexColumnWidth(2);
      widths[10] = const pw.FlexColumnWidth(2.5);
    } else {
      widths[8] = const pw.FlexColumnWidth(2);
      widths[9] = const pw.FlexColumnWidth(2.5);
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
            if (invoice.discountTotal > 0)
              _totalRow(
                  'Discount:', '-${invoice.discountTotal.toStringAsFixed(2)}'),
            _totalRow('Taxable:', invoice.taxableTotal.toStringAsFixed(2)),
            if (isGst)
              _totalRow('GST:', invoice.gstTotal.toStringAsFixed(2)),
            pw.Divider(),
            _totalRow(
                'Grand Total:', invoice.grandTotal.toStringAsFixed(2),
                bold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildAmountInWords(InvoiceDetail invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Text(
        'Amount in words: ${_numberToWords(invoice.grandTotal)}',
        style: pw.TextStyle(fontSize: 9),
      ),
    );
  }

  pw.Widget _buildPaymentInfo(InvoiceDetail invoice) {
    final children = <pw.Widget>[
      pw.Expanded(
        child: pw.Text(
          'Payment: ${invoice.paymentState}',
          style: pw.TextStyle(fontSize: 9),
        ),
      ),
    ];
    if (invoice.paidAmount > 0) {
      children.add(pw.Expanded(
        child: pw.Text(
          'Amount Paid: ${invoice.paidAmount.toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 9),
        ),
      ));
    }
    if (invoice.paidAmount > 0 && invoice.paidAmount < invoice.grandTotal) {
      children.add(pw.Expanded(
        child: pw.Text(
          'Balance Due: ${(invoice.grandTotal - invoice.paidAmount).toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ));
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(children: children),
    );
  }

  bool _hasBankDetails(InvoiceDetail invoice) {
    return (invoice.companyBankName ?? '').isNotEmpty ||
        (invoice.companyBankAccount ?? '').isNotEmpty;
  }

  pw.Widget _buildBankDetails(InvoiceDetail invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Bank Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          if (invoice.companyBankName != null &&
              invoice.companyBankName!.isNotEmpty)
            _infoRow('Bank:', invoice.companyBankName!),
          if (invoice.companyBankAccount != null &&
              invoice.companyBankAccount!.isNotEmpty)
            _infoRow('Account:', invoice.companyBankAccount!),
          if (invoice.companyBankIfsc != null &&
              invoice.companyBankIfsc!.isNotEmpty)
            _infoRow('IFSC:', invoice.companyBankIfsc!),
          if (invoice.companyBankBranch != null &&
              invoice.companyBankBranch!.isNotEmpty)
            _infoRow('Branch:', invoice.companyBankBranch!),
        ],
      ),
    );
  }

  pw.Widget _buildNotes(InvoiceDetail invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 9)),
        ],
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
      padding: const pw.EdgeInsets.all(4),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 7)),
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
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
      'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
      'sixteen', 'seventeen', 'eighteen', 'nineteen',
    ];
    const tens = <String>[
      '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy',
      'eighty', 'ninety',
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
