import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/repositories/pdf_generator.dart';
import 'package:docscanner/domain/usecases/export_to_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPdfGenerator extends Mock implements PdfGenerator {}

void main() {
  group('ExportToPdf', () {
    late ExportToPdf useCase;
    late MockPdfGenerator pdfGenerator;

    setUp(() {
      pdfGenerator = MockPdfGenerator();
      useCase = ExportToPdf(pdfGenerator);
    });

    test('calls pdfGenerator.exportPdf with collected paths', () async {
      final docs = [
        ScannedDocument(
          id: '1',
          pages: ['/a.jpg', '/b.jpg'],
          thumbnailPath: '/t.jpg',
          createdAt: DateTime(2026, 5, 21),
          name: 'Doc 1',
        ),
      ];

      when(() => pdfGenerator.exportPdf(['/a.jpg', '/b.jpg']))
          .thenAnswer((_) async => '/output.pdf');

      final result = await useCase(docs);

      expect(result, '/output.pdf');
      verify(() => pdfGenerator.exportPdf(['/a.jpg', '/b.jpg'])).called(1);
    });

    test('collects page paths from multiple documents', () async {
      final docs = [
        ScannedDocument(
          id: '1',
          pages: ['/a.jpg'],
          thumbnailPath: '/t.jpg',
          createdAt: DateTime(2026, 5, 21),
          name: 'Doc 1',
        ),
        ScannedDocument(
          id: '2',
          pages: ['/b.jpg', '/c.jpg'],
          thumbnailPath: '/t2.jpg',
          createdAt: DateTime(2026, 5, 21),
          name: 'Doc 2',
        ),
      ];

      when(() => pdfGenerator.exportPdf(['/a.jpg', '/b.jpg', '/c.jpg']))
          .thenAnswer((_) async => '/output.pdf');

      final result = await useCase(docs);

      expect(result, '/output.pdf');
    });
  });
}
