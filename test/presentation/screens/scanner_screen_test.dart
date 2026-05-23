import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/presentation/screens/scanner_screen.dart';

Widget createTestApp() {
  return const MaterialApp(
    home: ScannerScreen(),
  );
}

void main() {
  testWidgets('renders scanning UI', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Scan Document'), findsOneWidget);
  });

  testWidgets('shows loading indicator on initial render', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows capture button', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
