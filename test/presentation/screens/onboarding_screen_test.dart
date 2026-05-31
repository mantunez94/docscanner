import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import 'package:docscanner/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(onComplete: () {}),
        ),
      ),
    );
  }

  testWidgets('renders first onboarding page with title and description', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    expect(find.text('Scan Documents'), findsOneWidget);
    expect(
      find.text(
        'Capture documents with your camera. Auto-crop and enhance them for a clean result.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows Skip button', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('shows Next button on first page', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('shows page indicator dots', (tester) async {
    await pumpOnboarding(tester);
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });

  testWidgets('navigates to second page on Next tap', (tester) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Adjust & Refine'), findsOneWidget);
  });

  testWidgets('shows Get Started on last page', (tester) async {
    await pumpOnboarding(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('calls onComplete when Get Started is tapped', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(onComplete: () => completed = true),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    expect(completed, isTrue);
  });

  testWidgets('calls onComplete when Skip is tapped', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(onComplete: () => completed = true),
        ),
      ),
    );
    await tester.tap(find.text('Skip'));
    expect(completed, isTrue);
  });
}
