import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/domain/entities/scanned_document.dart';
import 'package:docscanner/presentation/widgets/document_card.dart';

ScannedDocument _testDoc({String name = 'Test Doc', int pages = 1}) {
  return ScannedDocument(
    id: 'test-1',
    pages: List.generate(pages, (i) => '/nonexistent/page_$i.jpg'),
    thumbnailPath: '/nonexistent/thumb.jpg',
    createdAt: DateTime(2026, 5, 24),
    name: name,
  );
}

Widget createTestApp(ScannedDocument doc, {bool? selected, VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: DocumentCard(
            document: doc,
            selected: selected,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders document name and page count', (tester) async {
    await tester.pumpWidget(createTestApp(_testDoc()));
    await tester.pump();

    expect(find.text('Test Doc'), findsOneWidget);
    expect(find.text('1 page'), findsOneWidget);
  });

  testWidgets('renders plural page count', (tester) async {
    await tester.pumpWidget(createTestApp(_testDoc(pages: 3, name: 'Multi-page')));
    await tester.pump();

    expect(find.text('3 pages'), findsOneWidget);
  });

  testWidgets('shows selection indicator when selected is provided', (tester) async {
    await tester.pumpWidget(createTestApp(_testDoc(), selected: false));
    await tester.pump();

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('shows selected icon when selected is true', (tester) async {
    await tester.pumpWidget(createTestApp(_testDoc(), selected: true));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      createTestApp(_testDoc(), onTap: () => tapped = true),
    );
    await tester.pump();

    await tester.tap(find.byType(DocumentCard));
    expect(tapped, isTrue);
  });

  testWidgets('hides selection indicator when selected is null', (tester) async {
    await tester.pumpWidget(createTestApp(_testDoc()));
    await tester.pump();

    expect(find.byIcon(Icons.circle_outlined), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
