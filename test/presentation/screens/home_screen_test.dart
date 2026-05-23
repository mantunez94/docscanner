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

  group('HomeScreen - empty state', () {
    testWidgets('shows empty state when no documents exist', (tester) async {
      await tester.pumpWidget(createTestApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('No documents yet'), findsOneWidget);
      expect(find.text('Scan Document'), findsOneWidget);
    });

    testWidgets('shows Scan button in empty state', (tester) async {
      await tester.pumpWidget(createTestApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Scan'), findsOneWidget);
    });
  });

  group('HomeScreen - with documents', () {
    final testDoc = ScannedDocument(
      id: '1',
      pages: ['/test/page1.jpg'],
      thumbnailPath: '/test/thumb1.jpg',
      createdAt: DateTime(2026, 5, 1),
      name: 'Test Document',
    );

    testWidgets('shows document cards', (tester) async {
      await tester.pumpWidget(
        createTestApp(repository: repository, documents: [testDoc]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Document'), findsOneWidget);
      expect(find.text('1 page'), findsOneWidget);
    });

    testWidgets('shows search field when documents exist', (tester) async {
      await tester.pumpWidget(
        createTestApp(repository: repository, documents: [testDoc]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows select button when documents exist', (tester) async {
      await tester.pumpWidget(
        createTestApp(repository: repository, documents: [testDoc]),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('filters documents by search query', (tester) async {
      final doc2 = ScannedDocument(
        id: '2',
        pages: ['/test/page2.jpg'],
        thumbnailPath: '/test/thumb2.jpg',
        createdAt: DateTime(2026, 5, 2),
        name: 'Another Document',
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, documents: [testDoc, doc2]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      expect(find.text('Test Document'), findsOneWidget);
      expect(find.text('Another Document'), findsNothing);
    });
  });
}
