import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gal/gal.dart';

class FileService {
  Future<String> get _documentsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');
    if (!await docDir.exists()) await docDir.create(recursive: true);
    return docDir.path;
  }

  Future<String> savePageImage(String id, Uint8List bytes) async {
    final dir = await _documentsDir;
    final path = '$dir/$id.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> savePageImageWithSuffix(String documentId, Uint8List bytes) async {
    final dir = await _documentsDir;
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$dir/${documentId}_$pageId.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String> saveThumbnail(String id, Uint8List bytes) async {
    final dir = await _documentsDir;
    final path = '$dir/${id}_thumb.jpg';
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode thumbnail');
    final thumb = img.copyResize(original, width: 200);
    await File(path).writeAsBytes(img.encodeJpg(thumb, quality: 65));
    return path;
  }

  PdfPageFormat _pageFormatForBytes(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return PdfPageFormat.a4;
    final aspect = decoded.width / decoded.height;
    final baseWidth = PdfPageFormat.a4.width;
    return PdfPageFormat(baseWidth, baseWidth / aspect);
  }

  Future<String> generatePdf(String documentId, List<String> pagePaths) async {
    final dir = await _documentsDir;
    final path = '$dir/$documentId.pdf';
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
    await File(path).writeAsBytes(await pdf.save());
    return path;
  }

  Future<String> exportPdf(List<String> allPagePaths) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${dir.path}/exports');
    if (!await pdfDir.exists()) await pdfDir.create(recursive: true);
    final pdf = pw.Document();
    for (final pagePath in allPagePaths) {
      final imageBytes = await File(pagePath).readAsBytes();
      final pageFormat = _pageFormatForBytes(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.fill),
        ),
      );
    }
    final outputPath = '${pdfDir.path}/documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outputPath).writeAsBytes(await pdf.save());
    return outputPath;
  }

  Future<void> saveToGallery(String path) async {
    try {
      await Gal.putImage(path, album: 'DocScanner');
    } catch (_) {
    }
  }
}
