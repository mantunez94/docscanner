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

    group('validateName', () {
      test('returns null for valid name', () {
        expect(ScannedDocument.validateName('My Document'), isNull);
      });

      test('returns error for empty name', () {
        expect(ScannedDocument.validateName(''), isNotEmpty);
        expect(ScannedDocument.validateName('   '), isNotEmpty);
        expect(ScannedDocument.validateName(null), isNotEmpty);
      });

      test('returns error for name with invalid characters', () {
        expect(ScannedDocument.validateName('file<1'), isNotEmpty);
        expect(ScannedDocument.validateName('file>1'), isNotEmpty);
        expect(ScannedDocument.validateName('file:1'), isNotEmpty);
        expect(ScannedDocument.validateName('file"1'), isNotEmpty);
      });

      test('returns error for overly long name', () {
        expect(ScannedDocument.validateName('a' * 256), isNotEmpty);
      });
    });

    group('page operations', () {
      test('addPage appends page path', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.addPage('/b.jpg');
        expect(updated.pages, ['/a.jpg', '/b.jpg']);
        expect(doc.pages, ['/a.jpg']);
      });

      test('removePage removes matching path', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg', '/b.jpg', '/c.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.removePage('/b.jpg');
        expect(updated.pages, ['/a.jpg', '/c.jpg']);
      });

      test('removePage does nothing if path not found', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.removePage('/nonexistent.jpg');
        expect(updated.pages, ['/a.jpg']);
      });

      test('replacePage replaces at index', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg', '/b.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.replacePage(0, '/new.jpg');
        expect(updated.pages, ['/new.jpg', '/b.jpg']);
      });

      test('reorderPages replaces page list', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg', '/b.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.reorderPages(['/b.jpg', '/a.jpg']);
        expect(updated.pages, ['/b.jpg', '/a.jpg']);
      });

      test('updatePdfPath sets pdf path', () {
        final doc = ScannedDocument(
          id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21),
        );
        final updated = doc.updatePdfPath('/doc.pdf');
        expect(updated.pdfPath, '/doc.pdf');
      });
    });
  });
}
