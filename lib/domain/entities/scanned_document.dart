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

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Name cannot be empty';
    if (name.trim().length > 255) return 'Name is too long';
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) return 'Name contains invalid characters';
    return null;
  }

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

  ScannedDocument addPage(String pagePath) =>
    copyWith(pages: [...pages, pagePath]);

  ScannedDocument removePage(String pagePath) {
    final updated = pages.where((p) => p != pagePath).toList();
    return copyWith(pages: updated);
  }

  ScannedDocument replacePage(int index, String newPath) {
    final updated = List<String>.from(pages);
    if (index >= 0 && index < updated.length) {
      updated[index] = newPath;
    }
    return copyWith(pages: updated);
  }

  ScannedDocument reorderPages(List<String> reordered) =>
    copyWith(pages: reordered);

  ScannedDocument updatePdfPath(String path) =>
    copyWith(pdfPath: path);
}
