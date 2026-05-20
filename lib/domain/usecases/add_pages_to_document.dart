import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
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

    await File(outputPath).writeAsBytes(img.encodeJpg(original, quality: 90));

    return repository.addPages(documentId, [outputPath]);
  }
}
