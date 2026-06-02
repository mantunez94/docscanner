import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/pdf_generator.dart';

class ExportToPdf {
  final PdfGenerator pdfGenerator;

  ExportToPdf(this.pdfGenerator);

  Future<String> call(List<ScannedDocument> documents) async {
    final allPaths = <String>[];
    for (final doc in documents) {
      allPaths.addAll(doc.pages);
    }
    return pdfGenerator.exportPdf(allPaths);
  }
}
