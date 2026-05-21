import '../../domain/entities/scanned_document.dart';
import '../../domain/repositories/document_repository.dart';

class ExportToPdf {
  final DocumentRepository repository;

  ExportToPdf(this.repository);

  Future<List<String>> call(List<ScannedDocument> documents) async {
    final allPaths = <String>[];
    for (final doc in documents) {
      allPaths.addAll(doc.pages);
    }
    return allPaths;
  }
}
