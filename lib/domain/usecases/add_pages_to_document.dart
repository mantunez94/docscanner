import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gal/gal.dart';
import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class AddPagesToDocument {
  final DocumentRepository repository;

  AddPagesToDocument(this.repository);

  Future<ScannedDocument> call(String documentId, Uint8List processedBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');

    final original = img.decodeImage(processedBytes);
    if (original == null) throw Exception('Failed to decode image');

    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    final outputPath = '${docDir.path}/${documentId}_$pageId.jpg';

    await File(outputPath).writeAsBytes(img.encodeJpg(original, quality: 85));

    final updated = await repository.addPages(documentId, [outputPath]);

    final pdf = pw.Document();
    for (final pagePath in updated.pages) {
      final imageBytes = await File(pagePath).readAsBytes();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain)),
        ),
      );
    }
    final pdfPath = '${docDir.path}/$documentId.pdf';
    await File(pdfPath).writeAsBytes(await pdf.save());

    try {
      await Gal.putImage(outputPath, album: 'DocScanner');
    } catch (_) {
    }

    await repository.updatePdfPath(documentId, pdfPath);
    return updated.copyWith(pdfPath: pdfPath);
  }
}
