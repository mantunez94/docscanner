import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/presentation/widgets/shimmer_grid.dart';

Widget createTestApp() {
  return const MaterialApp(
    home: Scaffold(body: ShimmerGrid()),
  );
}

void main() {
  testWidgets('renders shimmer cards in a grid', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(Card), findsAtLeast(1));
  });

  testWidgets('cards are wrapped in RepaintBoundary', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    final repaintBoundaries = tester.widgetList<RepaintBoundary>(find.byType(RepaintBoundary));
    expect(repaintBoundaries.length, greaterThanOrEqualTo(1));
  });

  testWidgets('animation runs without error', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 750));
    // No crash = animation runs fine
  });

  testWidgets('cards use NeverScrollableScrollPhysics', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('renders 2-column grid layout', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate;
    expect(delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    expect((delegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount, 2);
  });
}
