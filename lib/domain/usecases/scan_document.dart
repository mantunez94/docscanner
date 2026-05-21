import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gal/gal.dart';
import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class ScanDocument {
  final DocumentRepository repository;

  ScanDocument(this.repository);

  Future<ScannedDocument> call(Uint8List processedBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');
    if (!await docDir.exists()) await docDir.create(recursive: true);

    final original = img.decodeImage(processedBytes);
    if (original == null) throw Exception('Failed to decode image');

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final outputPath = '${docDir.path}/$id.jpg';
    final thumbPath = '${docDir.path}/${id}_thumb.jpg';
    final pdfPath = '${docDir.path}/$id.pdf';

    await File(outputPath).writeAsBytes(img.encodeJpg(original, quality: 85));
    final thumb = img.copyResize(original, width: 200);
    await File(thumbPath).writeAsBytes(img.encodeJpg(thumb, quality: 65));

    final pdf = pw.Document();
    final imageBytes = await File(outputPath).readAsBytes();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain)),
      ),
    );
    await File(pdfPath).writeAsBytes(await pdf.save());

    try {
      await Gal.putImage(outputPath, album: 'DocScanner');
    } catch (_) {
    }

    final doc = ScannedDocument(
      id: id,
      pages: [outputPath],
      thumbnailPath: thumbPath,
      createdAt: DateTime.now(),
      pdfPath: pdfPath,
    );

    return repository.save(doc);
  }
}
