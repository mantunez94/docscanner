import 'package:intl/intl.dart';

class ScannedDocument {
  final String id;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final int pageCount;
  final String name;

  ScannedDocument({
    required this.id,
    required this.filePath,
    required this.thumbnailPath,
    required this.createdAt,
    this.pageCount = 1,
    String? name,
  }) : name = name ?? DateFormat('MMM d, yyyy').format(createdAt);

  ScannedDocument copyWith({
    String? id,
    String? filePath,
    String? thumbnailPath,
    DateTime? createdAt,
    int? pageCount,
    String? name,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      name: name ?? this.name,
    );
  }
}
