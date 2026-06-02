import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/repositories/pdf_generator.dart';

class PdfService implements PdfGenerator {
  PdfPageFormat _pageFormatForBytes(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return PdfPageFormat.a4;
    final aspect = decoded.width / decoded.height;
    final baseWidth = PdfPageFormat.a4.width;
    return PdfPageFormat(baseWidth, baseWidth / aspect);
  }

  Future<Uint8List> _buildPdf(List<String> pagePaths) async {
    final pdf = pw.Document();
    for (final pagePath in pagePaths) {
      final imageBytes = await File(pagePath).readAsBytes();
      final pageFormat = _pageFormatForBytes(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.fill),
        ),
      );
    }
    return pdf.save();
  }

  Future<String> generatePdf(String documentId, List<String> pagePaths) async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');
    final path = '${docDir.path}/$documentId.pdf';
    final bytes = await _buildPdf(pagePaths);
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> exportPdf(List<String> allPagePaths) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/exports');
    if (!await pdfDir.exists()) await pdfDir.create(recursive: true);
    final bytes = await _buildPdf(allPagePaths);
    final outputPath = '${pdfDir.path}/documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outputPath).writeAsBytes(bytes);
    return outputPath;
  }
}
