import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:docscanner/domain/usecases/export_to_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DocumentRepository {}

void main() {
  group('ExportToPdf', () {
    late ExportToPdf useCase;
    late MockRepository repository;

    setUp(() {
      repository = MockRepository();
      useCase = ExportToPdf(repository);
    });

    test('collects page paths from documents', () async {
      final docs = [
        ScannedDocument(
          id: '1',
          pages: ['/a.jpg'],
          thumbnailPath: '/t.jpg',
          createdAt: DateTime(2026, 5, 21),
          name: 'Doc 1',
        ),
      ];

      final result = await useCase(docs);

      expect(result, ['/a.jpg']);
    });

    test('collects all page paths from multiple documents', () async {
      final docs = [
        ScannedDocument(
          id: '1',
          pages: ['/a.jpg', '/b.jpg'],
          thumbnailPath: '/t.jpg',
          createdAt: DateTime(2026, 5, 21),
          name: 'Multi',
        ),
      ];

      final result = await useCase(docs);

      expect(result, ['/a.jpg', '/b.jpg']);
    });
  });
}
