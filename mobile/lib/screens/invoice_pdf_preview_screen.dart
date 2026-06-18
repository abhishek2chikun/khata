import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/invoice_detail.dart';
import '../services/invoice_pdf_service.dart';

class InvoicePdfPreviewScreen extends StatelessWidget {
  const InvoicePdfPreviewScreen({
    super.key,
    required this.invoice,
    this.pdfService,
  });

  final InvoiceDetail invoice;
  final InvoicePdfService? pdfService;

  @override
  Widget build(BuildContext context) {
    final service = pdfService ?? InvoicePdfService.production();
    return Scaffold(
      appBar: AppBar(title: const Text('PDF preview')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        build: (_) async {
          final bytes = await service.generateInvoicePdfBytes(invoice);
          return Uint8List.fromList(bytes);
        },
      ),
    );
  }
}
