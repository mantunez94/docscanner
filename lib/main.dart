import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'data/di/providers.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const ProviderScope(child: DocScannerApp()));
}

class DocScannerApp extends ConsumerWidget {
  const DocScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appLightThemeDataProvider);
    final darkTheme = ref.watch(appDarkThemeDataProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(themeProvider);

    final themeKey = '${currentTheme.name}_${themeMode.name}';

    return MaterialApp(
      key: ValueKey(themeKey),
      title: 'DocScanner',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return locale;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        return Semantics(
          label: 'DocScanner app',
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child!,
          ),
        );
      },
      home: FutureBuilder<bool>(
        future: shouldShowOnboarding(ref.read(preferencesRepositoryProvider)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 64,
                      color: Theme.of(context).colorScheme.primary),
                    SizedBox(height: 16),
                    Text('DocScanner',
                      style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }
          if (snapshot.data == true) {
            return OnboardingScreen(
              onComplete: () => _replaceWithHome(context),
            );
          }
          return const HomeScreen();
        },
      ),
    );
  }

  void _replaceWithHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
