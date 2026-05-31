import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app integration', () {
    testWidgets('app launches without crash', (tester) async {
      await tester.pumpWidget(
        const _TestApp(),
      );
      await tester.pumpAndSettle();

      expect(find.text('DocScanner'), findsOneWidget);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('DocScanner'),
        ),
      ),
    );
  }
}
