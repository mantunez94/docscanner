import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/usecases/rename_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DocumentRepository {}

void main() {
  late RenameDocument useCase;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    useCase = RenameDocument(repository);
  });

  test('calls repository.rename with correct id and new name', () async {
    final updated = ScannedDocument(
      id: 'doc-1',
      pages: ['/a.jpg'],
      thumbnailPath: '/t.jpg',
      createdAt: DateTime(2026, 5, 21),
      name: 'New Name',
    );
    when(() => repository.rename('doc-1', 'New Name')).thenAnswer((_) async => updated);

    final result = await useCase('doc-1', 'New Name');

    expect(result.name, 'New Name');
    verify(() => repository.rename('doc-1', 'New Name')).called(1);
  });
}
