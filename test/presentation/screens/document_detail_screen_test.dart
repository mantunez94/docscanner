import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docscanner/data/di/providers.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/domain/repositories/document_repository.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import 'package:docscanner/presentation/screens/document_detail_screen.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

Widget createTestApp({
  required DocumentRepository repository,
  required ScannedDocument document,
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DocumentDetailScreen(document: document),
    ),
  );
}

void main() {
  late _MockDocumentRepository repository;

  setUp(() {
    repository = _MockDocumentRepository();
    SharedPreferences.setMockInitialValues({});
  });

  group('DocumentDetailScreen - empty pages', () {
    testWidgets('shows empty state when no pages', (tester) async {
      final doc = ScannedDocument(
        id: '1',
        pages: [],
        thumbnailPath: '/test/thumb.jpg',
        createdAt: DateTime(2026, 5, 1),
        name: 'Empty Doc',
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, document: doc),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Doc'), findsOneWidget);
      expect(find.text('No pages'), findsOneWidget);
      expect(find.text('This document has no pages'), findsOneWidget);
    });

    testWidgets('shows add page button when no pages', (tester) async {
      final doc = ScannedDocument(
        id: '1',
        pages: [],
        thumbnailPath: '/test/thumb.jpg',
        createdAt: DateTime(2026, 5, 1),
        name: 'Empty Doc',
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, document: doc),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    });
  });

  group('DocumentDetailScreen - with pages', () {
    testWidgets('shows document name in AppBar', (tester) async {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/test/page1.jpg', '/test/page2.jpg'],
        thumbnailPath: '/test/thumb.jpg',
        createdAt: DateTime(2026, 5, 1),
        name: 'My Document',
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, document: doc),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Document'), findsOneWidget);
    });

    testWidgets('shows page labels', (tester) async {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/test/page1.jpg', '/test/page2.jpg'],
        thumbnailPath: '/test/thumb.jpg',
        createdAt: DateTime(2026, 5, 1),
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, document: doc),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('shows select button when multiple pages', (tester) async {
      final doc = ScannedDocument(
        id: '1',
        pages: ['/test/page1.jpg', '/test/page2.jpg'],
        thumbnailPath: '/test/thumb.jpg',
        createdAt: DateTime(2026, 5, 1),
      );

      await tester.pumpWidget(
        createTestApp(repository: repository, document: doc),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
    });
  });
}
