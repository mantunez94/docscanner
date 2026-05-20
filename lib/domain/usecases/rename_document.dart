import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class RenameDocument {
  final DocumentRepository repository;

  RenameDocument(this.repository);

  Future<ScannedDocument> call(String id, String newName) {
    return repository.rename(id, newName);
  }
}
