import '../entities/scanned_document.dart';
import '../repositories/document_repository.dart';

class GetAllDocuments {
  final DocumentRepository repository;

  GetAllDocuments(this.repository);

  Future<List<ScannedDocument>> call() => repository.getAll();
}
