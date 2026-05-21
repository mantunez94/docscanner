import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';

class ScanDocument {
  final DocumentRepository repository;

  ScanDocument(this.repository);

  Future<ScannedDocument> call({
    required String id,
    required String filePath,
    required String thumbnailPath,
    String? pdfPath,
  }) async {
    final doc = ScannedDocument(
      id: id,
      pages: [filePath],
      thumbnailPath: thumbnailPath,
      createdAt: DateTime.now(),
      pdfPath: pdfPath,
    );
    return repository.save(doc);
  }
}
