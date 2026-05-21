import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScannedDocument', () {
    test('constructor assigns default name from createdAt', () {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/path/page.jpg'],
        thumbnailPath: '/path/thumb.jpg',
        createdAt: DateTime(2026, 5, 21),
      );
      expect(doc.name, 'May 21, 2026');
    });

    test('constructor uses provided name when given', () {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/path/page.jpg'],
        thumbnailPath: '/path/thumb.jpg',
        createdAt: DateTime(2026, 5, 21),
        name: 'My Document',
      );
      expect(doc.name, 'My Document');
    });

    test('filePath returns first page', () {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/first.jpg', '/second.jpg'],
        thumbnailPath: '/thumb.jpg',
        createdAt: DateTime(2026, 5, 21),
      );
      expect(doc.filePath, '/first.jpg');
    });

    test('pageCount returns number of pages', () {
      final single = ScannedDocument(
        id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
      );
      final multi = ScannedDocument(
        id: '2', pages: ['/a.jpg', '/b.jpg', '/c.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
      );
      expect(single.pageCount, 1);
      expect(multi.pageCount, 3);
    });

    test('copyWith overrides only provided fields', () {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/page.jpg'],
        thumbnailPath: '/thumb.jpg',
        createdAt: DateTime(2026, 5, 21),
        name: 'Original',
      );

      final renamed = doc.copyWith(name: 'Renamed');
      expect(renamed.name, 'Renamed');
      expect(renamed.id, '1');
      expect(renamed.pages, ['/page.jpg']);

      final withPages = doc.copyWith(pages: ['/new.jpg']);
      expect(withPages.pages, ['/new.jpg']);
      expect(withPages.id, '1');
      expect(withPages.name, 'Original');
    });

    test('copyWith with no args returns identical copy', () {
      final doc = ScannedDocument(
        id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21), name: 'Test',
      );
      final copy = doc.copyWith();
      expect(copy.id, doc.id);
      expect(copy.name, doc.name);
      expect(copy.pages, doc.pages);
      expect(copy.thumbnailPath, doc.thumbnailPath);
    });
  });
}
