import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../entities/scanned_document.dart';

class ExportToPdf {
  Future<File> call(List<ScannedDocument> documents) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/exports');
    if (!await pdfDir.exists()) await pdfDir.create(recursive: true);

    final pdf = pw.Document();

    for (final doc in documents) {
      for (final pagePath in doc.pages) {
        final imageBytes = await File(pagePath).readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      }
    }

    final outputPath = '${pdfDir.path}/documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
