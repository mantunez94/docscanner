import '../entities/scanned_document.dart';

abstract class DocumentRepository {
  Future<List<ScannedDocument>> getAll();
  Future<ScannedDocument> save(ScannedDocument document);
  Future<void> delete(String id);
}
