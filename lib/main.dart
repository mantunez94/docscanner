import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DocScannerApp()));
}

class DocScannerApp extends ConsumerWidget {
  const DocScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appLightThemeDataProvider);
    final darkTheme = ref.watch(appDarkThemeDataProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DocScanner',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.of(context).textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.3,
          ),
        ),
        child: child!,
      ),
      home: FutureBuilder<bool>(
        future: shouldShowOnboarding(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 64,
                      color: Color(0xFF1A5276)),
                    SizedBox(height: 16),
                    Text('DocScanner',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
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
