import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}
