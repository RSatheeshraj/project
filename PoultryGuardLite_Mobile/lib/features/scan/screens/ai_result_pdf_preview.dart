import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ai_scan_result_model.dart';
import 'package:http/http.dart' as http;

class AiResultPdfPreviewScreen extends StatefulWidget {
  final AiScanResultModel result;
  final File? imageFile;
  final String? imageUrl;
  final String farmName;
  final String batchName;

  const AiResultPdfPreviewScreen({
    super.key,
    required this.result,
    this.imageFile,
    this.imageUrl,
    this.farmName = 'Unknown Farm',
    this.batchName = 'Unknown Batch',
  });

  @override
  State<AiResultPdfPreviewScreen> createState() => _AiResultPdfPreviewScreenState();
}

class _AiResultPdfPreviewScreenState extends State<AiResultPdfPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Report PDF')),
      body: PdfPreview(
        build: (format) => _buildPdf(format),
      ),
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    // Load logo
    final logoData = await rootBundle.load('assets/branding/poultryguard_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Load actual disease image
    pw.ImageProvider? scanImageProvider;
    try {
      if (widget.imageFile != null) {
        scanImageProvider = pw.MemoryImage(widget.imageFile!.readAsBytesSync());
      } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        final response = await http.get(Uri.parse(widget.imageUrl!));
        if (response.statusCode == 200) {
          scanImageProvider = pw.MemoryImage(response.bodyBytes);
        }
      }
    } catch (e) {
      // Graceful fallback if image cannot be loaded
    }

    // Load Times New Roman equivalent font
    final ttfRegularData = await rootBundle.load('assets/fonts/TimesNewRoman-Regular.ttf');
    final ttfRegular = pw.Font.ttf(ttfRegularData);
    final ttfBoldData = await rootBundle.load('assets/fonts/TimesNewRoman-Bold.ttf');
    final ttfBold = pw.Font.ttf(ttfBoldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
      ),
    );

    final primaryColor = PdfColor.fromHex('#0f5c2e');
    final now = DateTime.now();

    pw.Widget buildHeader(pw.Context context) {
      return pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('PoultryGuardLite', style: pw.TextStyle(font: ttfBold, fontSize: 18, color: primaryColor)),
                  pw.Text('AI Scan Report', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                  pw.Text('Generated: ${now.day}/${now.month}/${now.year}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 10),
        ],
      );
    }

    pw.Widget buildFooter(pw.Context context) {
      return pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PoultryGuardLite', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                  pw.Text('AI-Powered Poultry Management', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      );
    }

    PdfColor severityColor(String severity) {
      switch (severity.toLowerCase()) {
        case 'low': return PdfColors.green;
        case 'medium': return PdfColors.orange;
        case 'high':
        case 'critical': return PdfColors.red;
        default: return PdfColors.grey;
      }
    }

    pw.Widget buildSection({required String title, required String content}) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 12, color: primaryColor)),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 12),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: buildHeader,
        footer: buildFooter,
        build: (pw.Context context) {
          return [
            pw.Text('SCAN DETAILS', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Farm', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.farmName)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Batch', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batchName)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Disease', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.result.diseaseName, style: pw.TextStyle(font: ttfBold, color: PdfColors.red))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Confidence', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${widget.result.confidence}%')),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Severity', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.result.severity, style: pw.TextStyle(color: severityColor(widget.result.severity), font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Isolation Required', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.result.isolationRequired ? 'YES' : 'NO', style: pw.TextStyle(font: ttfBold, color: widget.result.isolationRequired ? PdfColors.red : PdfColors.green))),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),
            
            // Scan Image
            if (scanImageProvider != null) ...[
              pw.Center(
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Container(
                    height: 200,
                    child: pw.Image(scanImageProvider, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            buildSection(title: 'POSSIBLE CAUSE', content: widget.result.possibleCause),
            buildSection(title: 'IMMEDIATE ACTION', content: widget.result.immediateAction),
            buildSection(title: 'TREATMENT PLAN', content: widget.result.treatment),
            buildSection(title: 'PREVENTION', content: widget.result.prevention),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
