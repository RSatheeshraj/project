import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/farm_model.dart';
import '../providers/entry_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/batch_provider.dart';

import '../../../shared/utils/currency_formatter.dart';

class FinalReportScreen extends ConsumerStatefulWidget {
  final FarmModel farm;
  final BatchModel batch; // Triggered from a batch context, but we will aggregate for the farm

  const FinalReportScreen({super.key, required this.farm, required this.batch});

  @override
  ConsumerState<FinalReportScreen> createState() => _FinalReportScreenState();
}

class _FinalReportScreenState extends ConsumerState<FinalReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Farm Report'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text('Generate Final Report for ${widget.farm.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('View / Share PDF'),
              onPressed: _generateAndShowPdf,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShowPdf() async {
    UiHelpers.showLoadingDialog(context, 'Generating Report', 'Aggregating data for final report...');
    try {
      // 1. Fetch all batches for the farm
      final allBatches = await ref.read(batchesByFarmStreamProvider(widget.farm.id).future);

      // Aggregations
      int totalInitialBirds = 0;
      int totalBirdsSold = 0;
      int totalMortality = 0;
      double totalExpenses = 0;
      double totalRevenue = 0;
      double totalWeightSold = 0;
      
      final batchBreakdown = <Map<String, dynamic>>[];
      
      for (final b in allBatches) {
        final entries = await ref.read(entriesStreamProvider((farmId: widget.farm.id, batchId: b.id)).future);
        final sales = await ref.read(salesStreamProvider((farmId: widget.farm.id, batchId: b.id)).future);
        
        int batchMortality = 0;
        double batchExpenses = 0;
        for (final e in entries) {
          batchMortality += e.mortalityCount;
          batchExpenses += (e.feedCost + e.medicineCost + e.labourCost + e.otherExpense);
        }

        int batchBirdsSold = 0;
        double batchWeightSold = 0;
        double batchRevenue = 0;
        for (final s in sales) {
          batchBirdsSold += s.birdsSold;
          batchWeightSold += s.totalWeight;
          batchRevenue += s.totalRevenue;
        }

        int batchRemaining = b.totalBirds - batchBirdsSold - batchMortality;
        
        // Ensure remaining doesn't go below 0 logically, but for data validation it should just reflect calculation
        double batchSaleRate = batchWeightSold > 0 ? (batchRevenue / batchWeightSold) : 0;

        totalInitialBirds += b.totalBirds;
        totalMortality += batchMortality;
        totalExpenses += batchExpenses;
        totalBirdsSold += batchBirdsSold;
        totalWeightSold += batchWeightSold;
        totalRevenue += batchRevenue;

        batchBreakdown.add({
          'batch': b,
          'initial': b.totalBirds,
          'sold': batchBirdsSold,
          'mortality': batchMortality,
          'remaining': batchRemaining,
          'revenue': batchRevenue,
          'saleRateKg': batchSaleRate,
        });
      }

      int totalRemaining = totalInitialBirds - totalBirdsSold - totalMortality;
      double netProfit = totalRevenue - totalExpenses;
      double saleRateKg = totalWeightSold > 0 ? (totalRevenue / totalWeightSold) : 0;
      double saleRateBird = totalBirdsSold > 0 ? (totalRevenue / totalBirdsSold) : 0;

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      // Show PDF Preview
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('PDF Preview')),
              body: PdfPreview(
                build: (format) => _buildPdf(
                  format,
                  allBatches,
                  batchBreakdown,
                  totalInitialBirds,
                  totalBirdsSold,
                  totalMortality,
                  totalRemaining,
                  totalExpenses,
                  totalRevenue,
                  netProfit,
                  totalWeightSold,
                  saleRateKg,
                  saleRateBird,
                ),
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, build, pageFormat) async {
                      final bytes = await build(pageFormat);
                      await Printing.sharePdf(bytes: bytes, filename: 'final_report.pdf');
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
    }
  }

  Future<Uint8List> _buildPdf(
    PdfPageFormat format, 
    List<BatchModel> allBatches,
    List<Map<String, dynamic>> batchBreakdown,
    int totalInitialBirds,
    int totalBirdsSold,
    int totalMortality,
    int totalRemaining,
    double totalExpenses,
    double totalRevenue,
    double netProfit,
    double totalWeightSold,
    double saleRateKg,
    double saleRateBird,
  ) async {
    // Load correct app logo
    final logoData = await rootBundle.load('assets/branding/poultryguard_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Load Times New Roman equivalent font that supports INR (₹)
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

    final primaryColor = PdfColor.fromHex('#0f5c2e'); // Deep green
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
                  pw.Text('Final Farm Report', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: buildHeader,
        footer: buildFooter,
        build: (pw.Context context) {
          final survivalRate = totalInitialBirds > 0 ? ((totalRemaining + totalBirdsSold) / totalInitialBirds * 100) : 0.0;

          return [
            // 1. FARM OVERVIEW
            pw.Text('1. FARM OVERVIEW', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Farm Name', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.farm.name)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Owner', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.farm.ownerName)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Capacity', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${widget.farm.capacity} birds')),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 2. BATCH OVERVIEW (Current Batch passed)
            pw.Text('2. BATCH OVERVIEW', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Batch Name', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batch.batchName)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Breed', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batch.breed)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batch.status)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Arrival Date', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.batch.arrivalDate?.toIso8601String().split('T').first ?? 'N/A')),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. FLOCK PERFORMANCE
            pw.Text('3. FLOCK PERFORMANCE (All Batches)', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Initial Birds', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalInitialBirds')),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Birds Sold', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalBirdsSold')),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Mortality', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalMortality')),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Remaining Birds', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalRemaining')),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Survival Rate', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${survivalRate.toStringAsFixed(2)}%')),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 4. SALES SUMMARY
            pw.Text('4. SALES SUMMARY', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Birds Sold', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$totalBirdsSold', textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Weight Sold', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totalWeightSold.toStringAsFixed(2)} kg', textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Sales Revenue', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatExact(totalRevenue).replaceAll('₹', 'Rs.'), textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sale Rate (Rs./kg)', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(totalWeightSold > 0 ? CurrencyFormatter.formatExact(saleRateKg).replaceAll('₹', 'Rs.') : 'N/A', textAlign: pw.TextAlign.right)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sale Rate (Rs./bird)', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(totalBirdsSold > 0 ? CurrencyFormatter.formatExact(saleRateBird).replaceAll('₹', 'Rs.') : 'N/A', textAlign: pw.TextAlign.right)),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 5. FINANCIAL OVERVIEW
            pw.Text('5. FINANCIAL OVERVIEW', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Expenses', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatExact(totalExpenses).replaceAll('₹', 'Rs.'), textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: PdfColors.red))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Revenue', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatExact(totalRevenue).replaceAll('₹', 'Rs.'), textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: PdfColors.green))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Net Profit', style: pw.TextStyle(font: ttfBold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.formatExact(netProfit).replaceAll('₹', 'Rs.'), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttfBold, color: netProfit >= 0 ? PdfColors.green : PdfColors.red))),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 6. BATCH BREAKDOWN
            if (allBatches.isNotEmpty) ...[
              pw.Text('6. BATCH BREAKDOWN', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(font: ttfBold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headers: ['Batch Name', 'Initial', 'Sold', 'Mortality', 'Remaining', 'Revenue', 'Sale Rate (Rs./kg)'],
                data: batchBreakdown.map((b) => [
                  (b['batch'] as BatchModel).batchName,
                  b['initial'].toString(),
                  b['sold'].toString(),
                  b['mortality'].toString(),
                  b['remaining'].toString(),
                  CurrencyFormatter.formatExact(b['revenue'] as double).replaceAll('₹', 'Rs.'),
                  b['saleRateKg'] > 0 ? CurrencyFormatter.formatExact(b['saleRateKg'] as double).replaceAll('₹', 'Rs.') : 'N/A',
                ]).toList(),
              ),
            ]
          ];
        },
      ),
    );

    return pdf.save();
  }
}

