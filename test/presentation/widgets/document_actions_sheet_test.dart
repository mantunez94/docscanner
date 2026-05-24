import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/presentation/widgets/document_actions_sheet.dart';

ScannedDocument _testDoc({int pageCount = 3}) {
  return ScannedDocument(
    id: 'test-1',
    pages: List.generate(pageCount, (i) => '/path/page_$i.jpg'),
    thumbnailPath: '/path/thumb.jpg',
    createdAt: DateTime(2026, 5, 24),
    name: 'My Document',
  );
}

Future<void> openSheet(WidgetTester tester, ScannedDocument doc, {
  VoidCallback? onViewPages,
  VoidCallback? onReorderPages,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showDocumentActionsSheet(
              ctx,
              doc,
              onRename: () {},
              onAddPage: () {},
              onShare: () {},
              onDelete: () {},
              onViewPages: onViewPages,
              onReorderPages: onReorderPages,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows document name in header', (tester) async {
    await openSheet(tester, _testDoc());
    expect(find.text('My Document'), findsOneWidget);
  });

  testWidgets('shows basic action tiles', (tester) async {
    await openSheet(tester, _testDoc());
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Add page'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('shows page count in view pages tile', (tester) async {
    await openSheet(tester, _testDoc(pageCount: 5), onViewPages: () {});
    expect(find.text('View pages (5)'), findsOneWidget);
  });

  testWidgets('hides reorder tile when single page', (tester) async {
    await openSheet(tester, _testDoc(pageCount: 1), onReorderPages: () {});
    expect(find.text('Reorder pages'), findsNothing);
  });

  testWidgets('shows reorder tile when multiple pages', (tester) async {
    await openSheet(tester, _testDoc(pageCount: 3), onReorderPages: () {});
    expect(find.text('Reorder pages'), findsOneWidget);
  });

  testWidgets('delete tile uses error color', (tester) async {
    await openSheet(tester, _testDoc());
    final deleteTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Delete'));
    expect(deleteTile.leading, isA<Icon>());
    final icon = deleteTile.leading as Icon;
    expect(icon.color?.r, greaterThan(0));
  });

  testWidgets('sheet closes when rename is tapped', (tester) async {
    await openSheet(tester, _testDoc());
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(find.text('My Document'), findsNothing);
  });

  testWidgets('calls add page callback', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDocumentActionsSheet(
                ctx,
                _testDoc(),
                onRename: () {},
                onAddPage: () => called = true,
                onShare: () {},
                onDelete: () {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add page'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });

  testWidgets('closes sheet when tapping outside actions', (tester) async {
    await openSheet(tester, _testDoc());
    // Tap the scrim (outside the sheet)
    await tester.tapAt(const Offset(0, 0));
    await tester.pumpAndSettle();
    expect(find.text('My Document'), findsNothing);
  });
}
