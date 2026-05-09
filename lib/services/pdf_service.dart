import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/prediction_result.dart';

class PdfService {
  /// Generates a PDF report and returns the saved file path.
  static Future<String> generateReport({
    required PredictionResult result,
    required XFile imageFile,
  }) async {
    final pdf = pw.Document();

    final Uint8List imageBytes = await imageFile.readAsBytes();
    final pdfImage = pw.MemoryImage(imageBytes);

    final bool isDyslexic = result.label == 'Dyslexic';
    final PdfColor resultColor =
        isDyslexic ? PdfColors.red700 : PdfColors.green700;
    final PdfColor resultBg =
        isDyslexic ? PdfColors.red50 : PdfColors.green50;
    final String generatedAt = _formatDate(DateTime.now());

    final suggestions = isDyslexic
        ? [
            'Consider consulting a specialist',
            'Try structured literacy programs',
            'Use assistive writing tools',
          ]
        : [
            'Keep practicing your handwriting',
            'Maintain consistent letter size',
            'Good job on clear letter formation!',
          ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(generatedAt),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ── Result banner ──────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: resultBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: resultColor, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Analysis Result',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  result.label,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Confidence: ${result.getConfidencePercentage()}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.blueGrey600,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  isDyslexic
                      ? 'The handwriting patterns indicate a higher likelihood of dyslexia.'
                      : 'The handwriting patterns indicate a low likelihood of dyslexia.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.blueGrey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Uploaded image ─────────────────────────────────────
          _sectionTitle('Uploaded Handwriting Image'),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(pdfImage, height: 180, fit: pw.BoxFit.contain),
            ),
          ),

          pw.SizedBox(height: 20),

          // ── What does this mean ────────────────────────────────
          _sectionTitle('What Does This Mean?'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.lightBlue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'This analysis is based on handwriting patterns processed by a CRNN deep learning model.',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColors.blueGrey700),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'This is not a medical diagnosis. For concerns, please consult a qualified professional.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.blueGrey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Suggestions ────────────────────────────────────────
          _sectionTitle('Suggestions'),
          pw.SizedBox(height: 8),
          ...suggestions.map(
            (s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ',
                      style: pw.TextStyle(
                          fontSize: 12, color: PdfColors.green700)),
                  pw.Expanded(
                    child: pw.Text(
                      s,
                      style: pw.TextStyle(
                          fontSize: 11, color: PdfColors.blueGrey700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final dir = await _getSaveDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/dyslexia_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildHeader(String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dyslexia Detection Report',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.Text(
            date,
            style:
                pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey200)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Dyslexia Detection App',
            style:
                pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style:
                pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static Future<Directory> _getSaveDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;
    }
    return getApplicationDocumentsDirectory();
  }
}
