// ignore_for_file: avoid_print, unused_import
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  testWidgets('PDF generates with Rupee symbol', (WidgetTester tester) async {
    // Load font from file system directly for the test since rootBundle might be tricky in pure unit tests without initialization
    final ttfRegularData = File('assets/fonts/TimesNewRoman-Regular.ttf').readAsBytesSync();
    final ttfRegular = pw.Font.ttf(ttfRegularData.buffer.asByteData());
    
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text('₹1,100.00', style: pw.TextStyle(font: ttfRegular, fontSize: 40)),
          );
        },
      ),
    );
    
    final bytes = await pdf.save();
    File('test_output.pdf').writeAsBytesSync(bytes);
    
    expect(bytes.isNotEmpty, true);
    print('PDF successfully generated with bytes length: ${bytes.length}');
  });
}
