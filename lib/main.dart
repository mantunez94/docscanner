import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DocScannerApp()));
}

class DocScannerApp extends StatelessWidget {
  const DocScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocScanner',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }

  // ── Arcade color palette ──────────────────────────────────────────
  static const _cyan = Color(0xFF00E5FF);
  static const _magenta = Color(0xFFFF2D95);
  static const _green = Color(0xFF39FF14);
  static const _red = Color(0xFFFF1744);

  // ── Dark theme colors ─────────────────────────────────────────────
  static const _darkBg = Color(0xFF0A0A1A);
  static const _darkSurface = Color(0xFF151530);
  static const _darkSurfaceHigh = Color(0xFF1E1E3A);
  static const _darkCard = Color(0xFF1A1A35);
  static const _darkBorder = Color(0xFF2A2A50);

  // ── Light theme colors ────────────────────────────────────────────
  static const _lightPrimary = Color(0xFF1A237E);
  static const _lightSurface = Color(0xFFFFF8F0);
  static const _lightSurfaceHigh = Color(0xFFF0E8E0);
  static const _lightCard = Color(0xFFFFFAF5);
  static const _lightBorder = Color(0xFFE0D8D0);

  // ── Font families ─────────────────────────────────────────────────
  static const _pixel = 'PressStart2P';
  static const _body = 'VT323';

  // ═════════════════════════════════════════════════════════════════
  //  LIGHT THEME — retro arcade cabinet (light)
  // ═════════════════════════════════════════════════════════════════
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _lightPrimary,
        onPrimary: Colors.white,
        secondary: _magenta,
        onSecondary: Colors.white,
        tertiary: Color(0xFF00C853),
        onTertiary: Colors.white,
        error: _red,
        onError: Colors.white,
        surface: _lightSurface,
        onSurface: Color(0xFF1A1A2E),
        surfaceContainerHighest: _lightSurfaceHigh,
        outline: _lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: _lightCard,
        foregroundColor: _lightPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: _pixel,
          fontSize: 14,
          color: _lightPrimary,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _lightBorder, width: 1.5),
        ),
        color: _lightCard,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _lightPrimary, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _lightBorder, width: 1.5),
          ),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          fontSize: 16,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _lightBorder, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: _body, fontSize: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightBorder,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontFamily: _pixel, fontSize: 16, letterSpacing: 2),
        titleMedium: TextStyle(fontFamily: _body, fontSize: 22, letterSpacing: 1),
        titleSmall: TextStyle(fontFamily: _body, fontSize: 18, letterSpacing: 1),
        bodyLarge: TextStyle(fontFamily: _body, fontSize: 20),
        bodyMedium: TextStyle(fontFamily: _body, fontSize: 18),
        bodySmall: TextStyle(fontFamily: _body, fontSize: 16, color: Color(0xFF888888)),
        labelLarge: TextStyle(fontFamily: _pixel, fontSize: 12, letterSpacing: 1.5),
        labelMedium: TextStyle(fontFamily: _body, fontSize: 18, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontFamily: _body, fontSize: 16),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  DARK THEME — neon arcade / dark retro
  // ═════════════════════════════════════════════════════════════════
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _cyan,
        onPrimary: _darkBg,
        secondary: _magenta,
        onSecondary: _darkBg,
        tertiary: _green,
        onTertiary: _darkBg,
        error: _red,
        onError: _darkBg,
        surface: _darkSurface,
        onSurface: Color(0xFFE8E8F0),
        surfaceContainerHighest: _darkSurfaceHigh,
        outline: _darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: _darkBg,
        foregroundColor: _cyan,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: _pixel,
          fontSize: 14,
          color: _cyan,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _darkBorder, width: 1.5),
        ),
        color: _darkCard,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _darkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _cyan, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkSurfaceHigh,
          foregroundColor: _cyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _darkBorder, width: 1.5),
          ),
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _cyan,
          textStyle: const TextStyle(
            fontFamily: _body,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _darkSurfaceHigh,
        contentTextStyle: const TextStyle(
          fontFamily: _body,
          fontSize: 16,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _cyan, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _darkBorder, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _cyan, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: _body, fontSize: 16, color: Colors.white70),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _magenta,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontFamily: _pixel, fontSize: 16, color: _cyan, letterSpacing: 2),
        titleMedium: TextStyle(fontFamily: _body, fontSize: 22, color: Colors.white, letterSpacing: 1),
        titleSmall: TextStyle(fontFamily: _body, fontSize: 18, color: Colors.white70, letterSpacing: 1),
        bodyLarge: TextStyle(fontFamily: _body, fontSize: 20, color: Colors.white),
        bodyMedium: TextStyle(fontFamily: _body, fontSize: 18, color: Colors.white),
        bodySmall: TextStyle(fontFamily: _body, fontSize: 16, color: Color(0xFF8888AA)),
        labelLarge: TextStyle(fontFamily: _pixel, fontSize: 12, color: _cyan, letterSpacing: 1.5),
        labelMedium: TextStyle(fontFamily: _body, fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontFamily: _body, fontSize: 16, color: Color(0xFF8888AA)),
      ),
    );
  }
}
