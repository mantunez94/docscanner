import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DocScannerApp()));
}

class DocScannerApp extends ConsumerStatefulWidget {
  const DocScannerApp({super.key});

  @override
  ConsumerState<DocScannerApp> createState() => _DocScannerAppState();
}

class _DocScannerAppState extends ConsumerState<DocScannerApp>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  int _themeVersion = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..value = 1.0;
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appLightThemeDataProvider);
    final darkTheme = ref.watch(appDarkThemeDataProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentTheme = ref.watch(themeProvider);
    final themeKey = currentTheme.hashCode ^ themeMode.hashCode;

    if (_themeVersion != themeKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _themeVersion = themeKey;
          _fadeController
            ..reset()
            ..forward();
        }
      });
    }

    return MaterialApp(
      title: 'DocScanner',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: child!,
            ),
          ),
        );
      },
      home: FutureBuilder<bool>(
        future: shouldShowOnboarding(),
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
