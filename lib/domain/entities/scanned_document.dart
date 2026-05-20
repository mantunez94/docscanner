import 'package:intl/intl.dart';

class ScannedDocument {
  final String id;
  final List<String> pages;
  final String thumbnailPath;
  final DateTime createdAt;
  final String name;

  String get filePath => pages.first;
  int get pageCount => pages.length;

  ScannedDocument({
    required this.id,
    required this.pages,
    required this.thumbnailPath,
    required this.createdAt,
    String? name,
  }) : name = name ?? DateFormat('MMM d, yyyy').format(createdAt);

  ScannedDocument copyWith({
    String? id,
    List<String>? pages,
    String? thumbnailPath,
    DateTime? createdAt,
    String? name,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      pages: pages ?? this.pages,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
    );
  }
}
