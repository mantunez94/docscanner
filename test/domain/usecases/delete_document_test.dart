import 'package:docscanner/domain/usecases/delete_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DocumentRepository {}

void main() {
  late DeleteDocument useCase;
  late MockRepository repository;

  setUp(() {
    repository = MockRepository();
    useCase = DeleteDocument(repository);
  });

  test('calls repository.delete with correct id', () async {
    when(() => repository.delete('doc-1')).thenAnswer((_) async {});

    await useCase('doc-1');

    verify(() => repository.delete('doc-1')).called(1);
  });
}
