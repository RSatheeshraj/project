import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/farm_model.dart';
import '../models/entry_model.dart';
import '../providers/entry_provider.dart';

class EntriesReportScreen extends ConsumerStatefulWidget {
  const EntriesReportScreen({
    super.key,
    required this.farm,
    required this.batch,
  });

  final FarmModel farm;
  final BatchModel batch;

  @override
  ConsumerState<EntriesReportScreen> createState() => _EntriesReportScreenState();
}

class _EntriesReportScreenState extends ConsumerState<EntriesReportScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateReport();
    });
  }

  Future<void> _generateReport() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      UiHelpers.showLoadingDialog(context, 'Generating PDF...', 'Please wait.');

      // Await the first emission from the stream
      final entries = await ref.read(
        entriesStreamProvider((farmId: widget.batch.farmId, batchId: widget.batch.id)).future,
      );

      if (entries.isEmpty) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
          await UiHelpers.showInfoDialog(context, 'No Data', 'No entries available to generate a report.');
        }
        if (mounted) Navigator.pop(context);
        return;
      }

      // Sort entries by date ascending
      entries.sort((a, b) => (a.entryDate ?? DateTime.now()).compareTo(b.entryDate ?? DateTime.now()));

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      // Show PDF Preview
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Entries Report PDF')),
              body: PdfPreview(
                build: (format) => _buildPdf(format, entries),
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, build, pageFormat) async {
                      final bytes = await build(pageFormat);
                      await Printing.sharePdf(
                        bytes: bytes, 
                        filename: 'entries_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      if (mounted) UiHelpers.showErrorDialog(context, 'Failed to generate report: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format, List<EntryModel> entries) async {
    final logoData = await rootBundle.load('assets/branding/poultryguard_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

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
                  pw.Text('Entries Log Report', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                  pw.Text('Generated: ${now.day}/${now.month}/${now.year}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Report Version: 1.0', style: const pw.TextStyle(fontSize: 10)),
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
                  pw.Text('AI-Powered Poultry Management | Version 1.0', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('© ${now.year} PoultryGuardLite. All rights reserved.', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      );
    }

    final df = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: buildHeader,
        footer: buildFooter,
        build: (pw.Context context) {
          return [
            pw.Text('1. BATCH OVERVIEW', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Farm Name', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.farm.name)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Batch Name', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batch.batchName)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Initial Birds', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${widget.batch.totalBirds}')),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text('2. ENTRIES LOG', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(font: ttfBold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headers: ['Date', 'Week', 'Mortality', 'Feed (kg)', 'Water (L)', 'Body Wt (kg)'],
              data: entries.map((e) => [
                e.entryDate != null ? df.format(e.entryDate!) : 'N/A',
                e.weekNumber.toString(),
                e.mortalityCount.toString(),
                e.feedConsumedKg.toStringAsFixed(2),
                e.waterConsumedLitres.toStringAsFixed(2),
                e.averageWeightKg.toStringAsFixed(2),
              ]).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
