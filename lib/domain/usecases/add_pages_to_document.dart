import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';

class AddPagesToDocument {
  final DocumentRepository repository;

  AddPagesToDocument(this.repository);

  Future<ScannedDocument> call(String documentId, List<String> newPagePaths) async {
    return repository.addPages(documentId, newPagePaths);
  }
}
