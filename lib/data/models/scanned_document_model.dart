import '../../domain/entities/scanned_document.dart';

class ScannedDocumentModel {
  final String id;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final int pageCount;

  ScannedDocumentModel({
    required this.id,
    required this.filePath,
    required this.thumbnailPath,
    required this.createdAt,
    this.pageCount = 1,
  });

  factory ScannedDocumentModel.fromEntity(ScannedDocument entity) {
    return ScannedDocumentModel(
      id: entity.id,
      filePath: entity.filePath,
      thumbnailPath: entity.thumbnailPath,
      createdAt: entity.createdAt,
      pageCount: entity.pageCount,
    );
  }

  ScannedDocument toEntity() {
    return ScannedDocument(
      id: id,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      createdAt: createdAt,
      pageCount: pageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
    };
  }

  factory ScannedDocumentModel.fromJson(Map<String, dynamic> json) {
    return ScannedDocumentModel(
      id: json['id'],
      filePath: json['filePath'],
      thumbnailPath: json['thumbnailPath'],
      createdAt: DateTime.parse(json['createdAt']),
      pageCount: json['pageCount'] ?? 1,
    );
  }
}
