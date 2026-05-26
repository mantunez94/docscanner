import '../entities/scanned_document.dart';

abstract class DocumentDataSource {
  Future<List<ScannedDocument>> loadAll();
  Future<void> save(ScannedDocument document);
  Future<ScannedDocument> rename(String id, String newName);
  Future<ScannedDocument> addPages(String id, List<String> newPages, [String? pdfPath]);
  Future<ScannedDocument> removePage(String id, String pagePath);
  Future<void> updatePdfPath(String id, String pdfPath);
  Future<ScannedDocument> reorderPages(String id, List<String> reorderedPages);
  Future<void> delete(String id);
}
