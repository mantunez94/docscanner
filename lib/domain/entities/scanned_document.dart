class ScannedDocument {
  final String id;
  final List<String> pages;
  final String thumbnailPath;
  final DateTime createdAt;
  final String name;
  final String? pdfPath;

  String get filePath => pages.first;
  int get pageCount => pages.length;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

  ScannedDocument({
    required this.id,
    required this.pages,
    required this.thumbnailPath,
    required this.createdAt,
    String? name,
    this.pdfPath,
  }) : name = name ?? _formatDate(createdAt);

  ScannedDocument copyWith({
    String? id,
    List<String>? pages,
    String? thumbnailPath,
    DateTime? createdAt,
    String? name,
    String? pdfPath,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      pages: pages ?? this.pages,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }
}
