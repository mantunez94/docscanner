import 'package:docscanner/data/models/scanned_document_model.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseDate = DateTime(2026, 5, 21, 10, 30, 0);

  group('ScannedDocumentModel', () {
    test('fromEntity creates model from entity', () {
      final entity = ScannedDocument(
        id: '1',
        pages: ['/path/page.jpg', '/path/page2.jpg'],
        thumbnailPath: '/path/thumb.jpg',
        createdAt: baseDate,
        name: 'Test',
      );

      final model = ScannedDocumentModel.fromEntity(entity);
      expect(model.id, '1');
      expect(model.pages, ['/path/page.jpg', '/path/page2.jpg']);
      expect(model.thumbnailPath, '/path/thumb.jpg');
      expect(model.createdAt, baseDate);
      expect(model.name, 'Test');
    });

    test('toEntity creates entity from model', () {
      final model = ScannedDocumentModel(
        id: '1',
        filePath: '/path/page.jpg',
        pages: ['/path/page.jpg', '/path/page2.jpg'],
        thumbnailPath: '/path/thumb.jpg',
        createdAt: baseDate,
        name: 'Test',
      );

      final entity = model.toEntity();
      expect(entity.id, '1');
      expect(entity.pages, ['/path/page.jpg', '/path/page2.jpg']);
      expect(entity.thumbnailPath, '/path/thumb.jpg');
      expect(entity.createdAt, baseDate);
      expect(entity.name, 'Test');
    });

    test('toJson produces expected map', () {
      final model = ScannedDocumentModel(
        id: '1',
        filePath: '/path/page.jpg',
        pages: ['/path/page.jpg', '/path/page2.jpg'],
        thumbnailPath: '/path/thumb.jpg',
        createdAt: baseDate,
        name: 'Test',
      );

      final json = model.toJson();
      expect(json['id'], '1');
      expect(json['pages'], ['/path/page.jpg', '/path/page2.jpg']);
      expect(json['thumbnailPath'], '/path/thumb.jpg');
      expect(json['createdAt'], '2026-05-21T10:30:00.000');
      expect(json['name'], 'Test');
    });

    test('fromJson restores model from map', () {
      final json = {
        'id': '1',
        'pages': ['/path/page.jpg', '/path/page2.jpg'],
        'thumbnailPath': '/path/thumb.jpg',
        'createdAt': '2026-05-21T10:30:00.000',
        'name': 'Test',
      };

      final model = ScannedDocumentModel.fromJson(json);
      expect(model.id, '1');
      expect(model.pages, ['/path/page.jpg', '/path/page2.jpg']);
      expect(model.thumbnailPath, '/path/thumb.jpg');
      expect(model.createdAt, baseDate);
      expect(model.name, 'Test');
    });

    test('fromJson handles legacy format without pages field', () {
      final json = {
        'id': '1',
        'filePath': '/path/legacy.jpg',
        'thumbnailPath': '/path/thumb.jpg',
        'createdAt': '2026-05-21T10:30:00.000',
        'name': 'Legacy',
      };

      final model = ScannedDocumentModel.fromJson(json);
      expect(model.id, '1');
      expect(model.pages, ['/path/legacy.jpg']);
      expect(model.thumbnailPath, '/path/thumb.jpg');
      expect(model.name, 'Legacy');
    });

    test('roundtrip toJson/fromJson preserves data', () {
      final original = ScannedDocumentModel(
        id: '2',
        filePath: '/a.jpg',
        pages: ['/a.jpg', '/b.jpg'],
        thumbnailPath: '/t.jpg',
        createdAt: baseDate,
        name: 'Roundtrip',
      );

      final json = original.toJson();
      final restored = ScannedDocumentModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.pages, original.pages);
      expect(restored.thumbnailPath, original.thumbnailPath);
      expect(restored.createdAt, original.createdAt);
      expect(restored.name, original.name);
    });

    test('pageCount matches pages length', () {
      final model = ScannedDocumentModel(
        id: '1',
        filePath: '/a.jpg',
        pages: ['/a.jpg', '/b.jpg', '/c.jpg'],
        thumbnailPath: '/t.jpg',
        createdAt: baseDate,
        name: 'Test',
      );
      expect(model.pageCount, 3);
    });
  });
}
