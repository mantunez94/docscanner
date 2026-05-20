class ScannedDocument {
  final String id;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final int pageCount;

  ScannedDocument({
    required this.id,
    required this.filePath,
    required this.thumbnailPath,
    required this.createdAt,
    this.pageCount = 1,
  });
}
