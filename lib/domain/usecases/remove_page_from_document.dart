import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class RemovePageFromDocument {
  final DocumentRepository repository;

  RemovePageFromDocument(this.repository);

  Future<ScannedDocument> call(String documentId, String pagePath) async {
    return repository.removePage(documentId, pagePath);
  }
}
