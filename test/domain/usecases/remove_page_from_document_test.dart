import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/usecases/remove_page_from_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DocumentRepository {}

void main() {
  late RemovePageFromDocument useCase;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    useCase = RemovePageFromDocument(repository);
  });

  test('calls repository.removePage with correct id and page path', () async {
    final updated = ScannedDocument(
      id: 'doc-1',
      pages: ['/page2.jpg'],
      thumbnailPath: '/t.jpg',
      createdAt: DateTime(2026, 5, 21),
    );
    when(() => repository.removePage('doc-1', '/page1.jpg'))
        .thenAnswer((_) async => updated);

    final result = await useCase('doc-1', '/page1.jpg');

    expect(result.pages, ['/page2.jpg']);
    verify(() => repository.removePage('doc-1', '/page1.jpg')).called(1);
  });
}
