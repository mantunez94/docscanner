import '../../domain/entities/scanned_document.dart';

class ScannedDocumentModel {
  final String id;
  final String filePath;
  final List<String> pages;
  final String thumbnailPath;
  final DateTime createdAt;
  final String name;

  int get pageCount => pages.length;

  ScannedDocumentModel({
    required this.id,
    required this.filePath,
    required this.pages,
    required this.thumbnailPath,
    required this.createdAt,
    required this.name,
  });

  factory ScannedDocumentModel.fromEntity(ScannedDocument entity) {
    return ScannedDocumentModel(
      id: entity.id,
      filePath: entity.filePath,
      pages: entity.pages,
      thumbnailPath: entity.thumbnailPath,
      createdAt: entity.createdAt,
      name: entity.name,
    );
  }

  ScannedDocument toEntity() {
    return ScannedDocument(
      id: id,
      pages: pages,
      thumbnailPath: thumbnailPath,
      createdAt: createdAt,
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'pages': pages,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
      'name': name,
    };
  }

  factory ScannedDocumentModel.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List?)?.cast<String>() ?? [json['filePath'] as String];
    return ScannedDocumentModel(
      id: json['id'],
      filePath: pages.first,
      pages: pages,
      thumbnailPath: json['thumbnailPath'],
      createdAt: DateTime.parse(json['createdAt']),
      name: json['name'] ?? '',
    );
  }
}
