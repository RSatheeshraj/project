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
import '../models/sales_model.dart';
import '../providers/entry_provider.dart';
import '../providers/sales_provider.dart';

/// A flat timeline event record used only by this report.
class _TlEvent {
  const _TlEvent({
    required this.date,
    required this.eventType,
    required this.details,
  });

  final DateTime date;
  final String eventType;
  final String details;
}

class TimelineReportScreen extends ConsumerStatefulWidget {
  const TimelineReportScreen({
    super.key,
    required this.farm,
    required this.batch,
  });

  final FarmModel farm;
  final BatchModel batch;

  @override
  ConsumerState<TimelineReportScreen> createState() =>
      _TimelineReportScreenState();
}

class _TimelineReportScreenState extends ConsumerState<TimelineReportScreen> {
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

      // Fetch data once
      final entries = await ref.read(
        entriesStreamProvider(
          (farmId: widget.batch.farmId, batchId: widget.batch.id),
        ).future,
      );
      final sales = await ref.read(
        salesStreamProvider(
          (farmId: widget.batch.farmId, batchId: widget.batch.id),
        ).future,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Timeline Report PDF')),
              body: PdfPreview(
                build: (format) => _buildPdf(format, entries, sales),
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, build, pageFormat) async {
                      final bytes = await build(pageFormat);
                      final batchId = widget.batch.id
                          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'timeline_report_$batchId.pdf',
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

  List<_TlEvent> _buildEvents(
    List<EntryModel> entries,
    List<SalesModel> sales,
  ) {
    final events = <_TlEvent>[];

    // 1. Batch Arrival
    if (widget.batch.arrivalDate != null) {
      events.add(_TlEvent(
        date: widget.batch.arrivalDate!,
        eventType: 'Batch Arrival',
        details:
            '${widget.batch.totalBirds} birds | ${widget.batch.breed} | ${widget.batch.birdType}',
      ));
    }

    // 2. Weekly Entries
    for (final e in entries) {
      if (e.entryDate == null) continue;
      final parts = <String>[];
      if (e.mortalityCount > 0) parts.add('Mortality: ${e.mortalityCount}');
      if (e.vaccination.isNotEmpty) parts.add('Vacc: ${e.vaccination}');
      if (e.medicine.isNotEmpty) parts.add('Med: ${e.medicine}');
      if (e.feedConsumedKg > 0) {
        parts.add('Feed: ${e.feedConsumedKg.toStringAsFixed(1)} kg');
      }
      if (e.averageWeightKg > 0) {
        parts.add('Avg Wt: ${e.averageWeightKg.toStringAsFixed(2)} kg');
      }
      if (e.temperature > 0) {
        parts.add('Temp: ${e.temperature.toStringAsFixed(1)} C');
      }
      if (e.notes.isNotEmpty) parts.add('Notes: ${e.notes}');

      events.add(_TlEvent(
        date: e.entryDate!,
        eventType: 'Week ${e.weekNumber} Entry',
        details: parts.isEmpty ? 'Entry recorded' : parts.join(' | '),
      ));
    }

    // 3. Sales
    for (final s in sales) {
      final parts = <String>[
        '${s.birdsSold} birds',
        '${s.totalWeight.toStringAsFixed(1)} kg',
        'Rs. ${s.totalRevenue.toStringAsFixed(2)}',
      ];
      if (s.buyerName.isNotEmpty) parts.add('Buyer: ${s.buyerName}');
      if (s.invoiceNumber.isNotEmpty) parts.add('Inv: ${s.invoiceNumber}');
      if (s.notes.isNotEmpty) parts.add('Notes: ${s.notes}');

      events.add(_TlEvent(
        date: s.date,
        eventType: 'Sale',
        details: parts.join(' | '),
      ));
    }

    // 4. Expected Market Date
    if (widget.batch.expectedMarketDate != null) {
      events.add(_TlEvent(
        date: widget.batch.expectedMarketDate!,
        eventType: 'Expected Market Date',
        details: 'Target sale date for batch',
      ));
    }

    // Sort oldest → newest (no duplicates since each comes from a different source)
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  Future<Uint8List> _buildPdf(
    PdfPageFormat format,
    List<EntryModel> entries,
    List<SalesModel> sales,
  ) async {
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
                  pw.Text('Batch Timeline Report',
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

    final events = _buildEvents(entries, sales);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: buildHeader,
        footer: buildFooter,
        build: (pw.Context ctx) {
          return [
            // ── Section 1: BATCH OVERVIEW ─────────────────────────────────
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
                _pdfRow(
                  ttfBold,
                  'Expected Market Date',
                  widget.batch.expectedMarketDate != null
                      ? df.format(widget.batch.expectedMarketDate!)
                      : '-',
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Section 2: CHRONOLOGICAL TIMELINE ────────────────────────
            pw.Text('2. BATCH TIMELINE REPORT',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),

            if (events.isEmpty)
              pw.Text('No timeline events found.',
                  style: const pw.TextStyle(fontSize: 11))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(font: ttfBold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FixedColumnWidth(100),
                  2: const pw.FlexColumnWidth(),
                },
                headers: ['Date', 'Event', 'Details'],
                data: events
                    .map((e) => [
                          df.format(e.date),
                          e.eventType,
                          e.details,
                        ])
                    .toList(),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
