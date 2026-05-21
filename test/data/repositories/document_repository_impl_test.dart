import 'package:docscanner/data/datasources/local_datasource.dart';
import 'package:docscanner/data/models/scanned_document_model.dart';
import 'package:docscanner/data/repositories/document_repository_impl.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataSource extends Mock implements LocalDataSource {}

void main() {
  late DocumentRepositoryImpl repository;
  late MockDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(ScannedDocumentModel(
      id: '', filePath: '', pages: [], thumbnailPath: '',
      createdAt: DateTime(2026, 1, 1), name: '',
    ));
  });

  setUp(() {
    dataSource = MockDataSource();
    repository = DocumentRepositoryImpl(dataSource);
  });

  group('getAll', () {
    test('returns entities from datasource', () async {
      final models = [
        ScannedDocumentModel(
          id: '1', filePath: '/a.jpg', pages: ['/a.jpg'],
          thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21), name: 'Test',
        ),
      ];
      when(() => dataSource.loadAll()).thenAnswer((_) async => models);

      final docs = await repository.getAll();

      expect(docs.length, 1);
      expect(docs.first.id, '1');
      expect(docs.first.name, 'Test');
      verify(() => dataSource.loadAll()).called(1);
    });

    test('returns empty list when datasource has no documents', () async {
      when(() => dataSource.loadAll()).thenAnswer((_) async => []);

      final docs = await repository.getAll();

      expect(docs, isEmpty);
    });
  });

  group('save', () {
    test('saves entity via datasource and returns entity', () async {
      final entity = ScannedDocument(
        id: '1', pages: ['/a.jpg'], thumbnailPath: '/t.jpg',
        createdAt: DateTime(2026, 5, 21), name: 'Test',
      );
      when(() => dataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.save(entity);

      expect(result.id, '1');
      verify(() => dataSource.save(any())).called(1);
    });
  });

  group('delete', () {
    test('deletes via datasource with correct id', () async {
      when(() => dataSource.delete('doc-1')).thenAnswer((_) async {});

      await repository.delete('doc-1');

      verify(() => dataSource.delete('doc-1')).called(1);
    });
  });

  group('rename', () {
    test('renames via datasource and returns updated entity', () async {
      final updatedModel = ScannedDocumentModel(
        id: '1', filePath: '/a.jpg', pages: ['/a.jpg'],
        thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21), name: 'Renamed',
      );
      when(() => dataSource.rename('1', 'Renamed')).thenAnswer((_) async => updatedModel);

      final result = await repository.rename('1', 'Renamed');

      expect(result.name, 'Renamed');
      verify(() => dataSource.rename('1', 'Renamed')).called(1);
    });
  });

  group('addPages', () {
    test('adds pages via datasource and returns updated entity', () async {
      final updatedModel = ScannedDocumentModel(
        id: '1', filePath: '/a.jpg', pages: ['/a.jpg', '/b.jpg'],
        thumbnailPath: '/t.jpg', createdAt: DateTime(2026, 5, 21), name: 'Test',
      );
      when(() => dataSource.addPages('1', ['/b.jpg'])).thenAnswer((_) async => updatedModel);

      final result = await repository.addPages('1', ['/b.jpg']);

      expect(result.pageCount, 2);
      verify(() => dataSource.addPages('1', ['/b.jpg'])).called(1);
    });
  });
}
