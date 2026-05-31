import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docscanner/data/di/providers.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:docscanner/presentation/screens/home_screen.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

Widget createTestApp({
  required DocumentRepository repository,
  List<ScannedDocument> documents = const [],
}) {
  when(() => repository.getAll()).thenAnswer((_) async => documents);

  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  late MockDocumentRepository repository;

  setUp(() {
    repository = MockDocumentRepository();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home_screen_empty_state golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestApp(repository: repository));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_screen_empty_state.png'),
    );
  });

  testWidgets('home_screen_with_documents golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final testDoc = ScannedDocument(
      id: '1',
      pages: ['/test/page1.jpg'],
      thumbnailPath: '/test/thumb1.jpg',
      createdAt: DateTime(2026, 5, 1),
      name: 'Test Document',
    );

    await tester.pumpWidget(
      createTestApp(repository: repository, documents: [testDoc]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_screen_with_documents.png'),
    );
  });
}
