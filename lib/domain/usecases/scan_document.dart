import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class ScanDocument {
  final DocumentRepository repository;

  ScanDocument(this.repository);

  Future<ScannedDocument> call(String imagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${dir.path}/documents');
    if (!await docDir.exists()) await docDir.create(recursive: true);

    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) throw Exception('Failed to decode image');

    final processed = _enhanceDocument(original);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final outputPath = '${docDir.path}/$id.jpg';
    final thumbPath = '${docDir.path}/${id}_thumb.jpg';

    await File(outputPath).writeAsBytes(img.encodeJpg(processed, quality: 90));
    final thumb = img.copyResize(processed, width: 200);
    await File(thumbPath).writeAsBytes(img.encodeJpg(thumb, quality: 70));

    final doc = ScannedDocument(
      id: id,
      filePath: outputPath,
      thumbnailPath: thumbPath,
      createdAt: DateTime.now(),
    );

    return repository.save(doc);
  }

  img.Image _enhanceDocument(img.Image image) {
    var result = img.grayscale(image);
    result = img.adjustColor(result, contrast: 1.3);
    result = img.gaussianBlur(result, radius: 1);
    return result;
  }
}
