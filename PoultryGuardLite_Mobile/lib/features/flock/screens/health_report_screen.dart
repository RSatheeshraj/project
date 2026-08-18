import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/farm_model.dart';
import '../providers/entry_provider.dart';

class HealthReportScreen extends ConsumerStatefulWidget {
  const HealthReportScreen({
    super.key,
    required this.farm,
    required this.batch,
  });

  final FarmModel farm;
  final BatchModel batch;

  @override
  ConsumerState<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends ConsumerState<HealthReportScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Stable pattern: generate ONCE after the first frame, never from build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateReport();
    });
  }

  Future<void> _generateReport() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      UiHelpers.showLoadingDialog(context, 'Generating PDF...', 'Please wait.');

      // Fetch entries once from the stream future
      final entries = await ref.read(
        entriesStreamProvider(
          (farmId: widget.batch.farmId, batchId: widget.batch.id),
        ).future,
      );

      // Sort entries oldest → newest for the report
      entries.sort((a, b) =>
          (a.entryDate ?? DateTime.now())
              .compareTo(b.entryDate ?? DateTime.now()));

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Health Report PDF')),
              body: PdfPreview(
                // The build callback receives the format; it is called by PdfPreview
                // internally and is NOT called from build(), so it is stable.
                build: (format) => _buildPdf(format, entries),
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, build, pageFormat) async {
                      final bytes = await build(pageFormat);
                      final batchId = widget.batch.id
                          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'health_report_$batchId.pdf',
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
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      if (mounted) UiHelpers.showErrorDialog(context, 'Failed to generate report: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<Uint8List> _buildPdf(
    PdfPageFormat format,
    List<EntryModel> entries,
  ) async {
    // Load branding assets (same as existing reports)
    final logoData =
        await rootBundle.load('assets/branding/poultryguard_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final ttfRegularData =
        await rootBundle.load('assets/fonts/TimesNewRoman-Regular.ttf');
    final ttfRegular = pw.Font.ttf(ttfRegularData);
    final ttfBoldData =
        await rootBundle.load('assets/fonts/TimesNewRoman-Bold.ttf');
    final ttfBold = pw.Font.ttf(ttfBoldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    final primaryColor = PdfColor.fromHex('#0f5c2e');
    final now = DateTime.now();
    final df = DateFormat('dd/MM/yyyy');

    // ── Header & Footer builders (same style as other reports) ────────────────

    pw.Widget buildHeader(pw.Context ctx) {
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
                  pw.Text('PoultryGuardLite',
                      style: pw.TextStyle(
                          font: ttfBold, fontSize: 18, color: primaryColor)),
                  pw.Text('Health Report',
                      style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                  pw.Text(
                      'Generated: ${now.day}/${now.month}/${now.year}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Report Version: 1.0',
                      style: const pw.TextStyle(fontSize: 10)),
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

    pw.Widget buildFooter(pw.Context ctx) {
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
                  pw.Text('PoultryGuardLite',
                      style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                  pw.Text(
                      'AI-Powered Poultry Management | Version 1.0',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                      '© ${now.year} PoultryGuardLite. All rights reserved.',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      );
    }

    // ── Summary stats ─────────────────────────────────────────────────────────
    final totalMortality =
        entries.fold(0, (s, e) => s + e.mortalityCount);
    final mortalityRate = widget.batch.totalBirds > 0
        ? (totalMortality / widget.batch.totalBirds * 100).toStringAsFixed(2)
        : '0.00';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: buildHeader,
        footer: buildFooter,
        build: (pw.Context ctx) {
          return [
            // ── Section 1: BATCH OVERVIEW ───────────────────────────────────
            pw.Text('1. BATCH OVERVIEW',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _pdfRow(ttfBold, 'Farm Name', widget.farm.name),
                _pdfRow(ttfBold, 'Batch Name', widget.batch.batchName),
                _pdfRow(ttfBold, 'Bird Type',
                    widget.batch.birdType.isEmpty ? '-' : widget.batch.birdType),
                _pdfRow(ttfBold, 'Breed',
                    widget.batch.breed.isEmpty ? '-' : widget.batch.breed),
                _pdfRow(ttfBold, 'Status',
                    widget.batch.status.isEmpty ? '-' : widget.batch.status),
                _pdfRow(
                  ttfBold,
                  'Arrival Date',
                  widget.batch.arrivalDate != null
                      ? df.format(widget.batch.arrivalDate!)
                      : '-',
                ),
                _pdfRow(ttfBold, 'Age', '${widget.batch.ageInDays} days'),
                _pdfRow(ttfBold, 'Initial Birds',
                    widget.batch.totalBirds.toString()),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Section 2: HEALTH SUMMARY ───────────────────────────────────
            pw.Text('2. HEALTH SUMMARY',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _pdfRow(ttfBold, 'Total Records', '${entries.length}'),
                _pdfRow(ttfBold, 'Total Mortality', '$totalMortality birds'),
                _pdfRow(ttfBold, 'Mortality Rate', '$mortalityRate%'),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Section 3: HEALTH RECORDS ───────────────────────────────────
            pw.Text('3. HEALTH RECORDS',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),

            if (entries.isEmpty)
              pw.Text('No health records available.',
                  style: const pw.TextStyle(fontSize: 11))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle:
                    pw.TextStyle(font: ttfBold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                headers: [
                  'Date',
                  'Week',
                  'Mortality',
                  'Temp (C)',
                  'Humidity (%)',
                  'Vaccination',
                  'Medicine',
                  'Med Cost',
                ],
                data: entries.map((e) => [
                  e.entryDate != null ? df.format(e.entryDate!) : '-',
                  '${e.weekNumber}',
                  '${e.mortalityCount}',
                  e.temperature > 0
                      ? e.temperature.toStringAsFixed(1)
                      : '-',
                  e.humidity > 0
                      ? e.humidity.toStringAsFixed(1)
                      : '-',
                  e.vaccination.isEmpty ? '-' : e.vaccination,
                  e.medicine.isEmpty ? '-' : e.medicine,
                  e.medicineCost > 0
                      ? 'Rs. ${e.medicineCost.toStringAsFixed(2)}'
                      : '-',
                ]).toList(),
              ),
            pw.SizedBox(height: 20),

            // ── Section 4: DETAILED RECORDS WITH NOTES ──────────────────────
            if (entries.any((e) =>
                e.notes.isNotEmpty ||
                e.vaccinationDate != null ||
                e.nextVaccinationDate != null)) ...[
              pw.Text('4. DETAILED HEALTH NOTES',
                  style: pw.TextStyle(
                      font: ttfBold, fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 8),
              ...entries
                  .where((e) =>
                      e.notes.isNotEmpty ||
                      e.vaccinationDate != null ||
                      e.nextVaccinationDate != null)
                  .map((e) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      e.entryDate != null
                          ? 'Week ${e.weekNumber} — ${df.format(e.entryDate!)}'
                          : 'Week ${e.weekNumber}',
                      style: pw.TextStyle(font: ttfBold, fontSize: 11),
                    ),
                    if (e.vaccinationDate != null)
                      pw.Text(
                          '  Vaccination Date: ${df.format(e.vaccinationDate!)}',
                          style: const pw.TextStyle(fontSize: 10)),
                    if (e.nextVaccinationDate != null)
                      pw.Text(
                          '  Next Vaccination: ${df.format(e.nextVaccinationDate!)}',
                          style: const pw.TextStyle(fontSize: 10)),
                    if (e.notes.isNotEmpty)
                      pw.Text('  Notes: ${e.notes}',
                          style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Helper: builds a two-cell table row for key-value display.
  pw.TableRow _pdfRow(pw.Font boldFont, String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(label, style: pw.TextStyle(font: boldFont)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(value),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // This screen immediately triggers generation in initState.
    // The loading spinner here is only briefly visible before pushReplacement.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
