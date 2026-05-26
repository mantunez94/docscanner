abstract class PdfGenerator {
  Future<String> generatePdf(String documentId, List<String> pagePaths);
  Future<String> exportPdf(List<String> allPagePaths);
}
