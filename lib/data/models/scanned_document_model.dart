import '../../domain/entities/scanned_document.dart';

class ScannedDocumentModel {
  final String id;
  final String filePath;
  final List<String> pages;
  final String thumbnailPath;
  final DateTime createdAt;
  final String name;
  final String? pdfPath;

  int get pageCount => pages.length;

  ScannedDocumentModel({
    required this.id,
    required this.filePath,
    required this.pages,
    required this.thumbnailPath,
    required this.createdAt,
    required this.name,
    this.pdfPath,
  });

  factory ScannedDocumentModel.fromEntity(ScannedDocument entity) {
    return ScannedDocumentModel(
      id: entity.id,
      filePath: entity.filePath,
      pages: entity.pages,
      thumbnailPath: entity.thumbnailPath,
      createdAt: entity.createdAt,
      name: entity.name,
      pdfPath: entity.pdfPath,
    );
  }

  ScannedDocument toEntity() {
    return ScannedDocument(
      id: id,
      pages: pages,
      thumbnailPath: thumbnailPath,
      createdAt: createdAt,
      name: name,
      pdfPath: pdfPath,
    );
  }

  ScannedDocumentModel copyWith({
    String? id,
    String? filePath,
    List<String>? pages,
    String? thumbnailPath,
    DateTime? createdAt,
    String? name,
    String? pdfPath,
  }) {
    return ScannedDocumentModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      pages: pages ?? this.pages,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      pdfPath: pdfPath ?? this.pdfPath,
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
      if (pdfPath != null) 'pdfPath': pdfPath,
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
      pdfPath: json['pdfPath'] as String?,
    );
  }
}
