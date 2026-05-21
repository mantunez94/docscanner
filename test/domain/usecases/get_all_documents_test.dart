import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:docscanner/domain/usecases/get_all_documents.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DocumentRepository {}

void main() {
  late GetAllDocuments useCase;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    useCase = GetAllDocuments(repository);
  });

  test('returns documents from repository', () async {
    final docs = [
      ScannedDocument(id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21)),
    ];
    when(() => repository.getAll()).thenAnswer((_) async => docs);

    final result = await useCase();

    expect(result, docs);
    verify(() => repository.getAll()).called(1);
  });

  test('returns empty list when no documents', () async {
    when(() => repository.getAll()).thenAnswer((_) async => []);

    final result = await useCase();

    expect(result, isEmpty);
  });
}
