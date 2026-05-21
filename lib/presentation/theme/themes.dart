import 'package:flutter/material.dart';

enum AppTheme { arcade, kawaii, professional }

const _pixel = 'PressStart2P';
const _body = 'VT323';

ThemeData buildTheme(AppTheme appTheme, Brightness brightness) {
  return switch (appTheme) {
    AppTheme.arcade => _buildArcadeTheme(brightness),
    AppTheme.kawaii => _buildKawaiiTheme(brightness),
    AppTheme.professional => _buildProfessionalTheme(brightness),
  };
}

String themeLabel(AppTheme theme) => switch (theme) {
  AppTheme.arcade => 'Arcade',
  AppTheme.kawaii => 'Kawaii',
  AppTheme.professional => 'Professional',
};

IconData themeIcon(AppTheme theme) => switch (theme) {
  AppTheme.arcade => Icons.videogame_asset_outlined,
  AppTheme.kawaii => Icons.favorite_outline,
  AppTheme.professional => Icons.work_outline,
};

// ─────────────────────────────────────────────────────────────────
//  ARCADE — neon retro gaming
// ─────────────────────────────────────────────────────────────────
ThemeData _buildArcadeTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF00E5FF),
            onPrimary: Color(0xFF0A0A1A),
            secondary: Color(0xFFFF2D95),
            onSecondary: Color(0xFF0A0A1A),
            tertiary: Color(0xFF39FF14),
            onTertiary: Color(0xFF0A0A1A),
            error: Color(0xFFFF1744),
            onError: Color(0xFF0A0A1A),
            surface: Color(0xFF151530),
            onSurface: Color(0xFFE8E8F0),
            surfaceContainerHighest: Color(0xFF1E1E3A),
            outline: Color(0xFF2A2A50),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF1A237E),
            onPrimary: Colors.white,
            secondary: Color(0xFFFF2D95),
            onSecondary: Colors.white,
            tertiary: Color(0xFF00C853),
            onTertiary: Colors.white,
            error: Color(0xFFFF1744),
            onError: Colors.white,
            surface: Color(0xFFFFF8F0),
            onSurface: Color(0xFF1A1A2E),
            surfaceContainerHighest: Color(0xFFF0E8E0),
            outline: Color(0xFFE0D8D0),
          ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFFFFAF5),
      foregroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontFamily: _pixel, fontSize: 14,
        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
        letterSpacing: 2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: isDark ? Colors.black54 : Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFE0D8D0), width: 1.5),
      ),
      color: isDark ? const Color(0xFF1A1A35) : const Color(0xFFFFFAF5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
        foregroundColor: isDark ? const Color(0xFF0A0A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18, letterSpacing: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF1E1E3A) : null,
        foregroundColor: isDark ? const Color(0xFF00E5FF) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFE0D8D0), width: 1.5),
        ),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18, letterSpacing: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFF00E5FF) : null,
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18, letterSpacing: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF1E1E3A) : null,
      contentTextStyle: const TextStyle(fontFamily: _body, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFFE0D8D0), width: 1),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF151530) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF151530) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFE0D8D0), width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: isDark,
      fillColor: isDark ? const Color(0xFF1E1E3A) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFE0D8D0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E), width: 2),
      ),
      labelStyle: TextStyle(fontFamily: _body, fontSize: 16, color: isDark ? Colors.white70 : null),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? const Color(0xFFFF2D95) : null,
      foregroundColor: isDark ? Colors.white : null,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF2A2A50) : const Color(0xFFE0D8D0),
      thickness: 1,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: _pixel, fontSize: 16, letterSpacing: 2,
        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E)),
      titleMedium: TextStyle(fontFamily: _body, fontSize: 22, letterSpacing: 1,
        color: isDark ? Colors.white : null),
      titleSmall: TextStyle(fontFamily: _body, fontSize: 18, letterSpacing: 1,
        color: isDark ? Colors.white70 : null),
      bodyLarge: TextStyle(fontFamily: _body, fontSize: 20,
        color: isDark ? Colors.white : null),
      bodyMedium: TextStyle(fontFamily: _body, fontSize: 18,
        color: isDark ? Colors.white : null),
      bodySmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFF8888AA) : const Color(0xFF888888)),
      labelLarge: TextStyle(fontFamily: _pixel, fontSize: 12, letterSpacing: 1.5,
        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E)),
      labelMedium: TextStyle(fontFamily: _body, fontSize: 18, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : null),
      labelSmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFF8888AA) : null),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
//  KAWAII — pastel cute
// ─────────────────────────────────────────────────────────────────
ThemeData _buildKawaiiTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFFFF9EB5),
            onPrimary: Color(0xFF2D1B36),
            secondary: Color(0xFFC9B1FF),
            onSecondary: Color(0xFF2D1B36),
            tertiary: Color(0xFF81C784),
            onTertiary: Color(0xFF2D1B36),
            error: Color(0xFFEF5350),
            onError: Color(0xFF2D1B36),
            surface: Color(0xFF2D1B36),
            onSurface: Color(0xFFF3E5F5),
            surfaceContainerHighest: Color(0xFF3E224A),
            outline: Color(0xFF5A3D6B),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFFE91E8C),
            onPrimary: Colors.white,
            secondary: Color(0xFF7B1FA2),
            onSecondary: Colors.white,
            tertiary: Color(0xFF66BB6A),
            onTertiary: Colors.white,
            error: Color(0xFFE53935),
            onError: Colors.white,
            surface: Color(0xFFFFF0F5),
            onSurface: Color(0xFF3E2723),
            surfaceContainerHighest: Color(0xFFFCE4EC),
            outline: Color(0xFFF0C0D0),
          ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: isDark ? const Color(0xFF2D1B36) : const Color(0xFFFFF0F5),
      foregroundColor: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontFamily: _body, fontSize: 20,
        color: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C),
        letterSpacing: 1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: isDark ? Colors.black38 : const Color(0xFFFFCDD2).withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF5A3D6B) : const Color(0xFFF0C0D0),
          width: 1.5,
        ),
      ),
      color: isDark ? const Color(0xFF3E224A) : const Color(0xFFFFF8FD),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C),
        foregroundColor: isDark ? const Color(0xFF2D1B36) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontFamily: _body, fontSize: 18),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF3E224A) : const Color(0xFFE91E8C),
      contentTextStyle: const TextStyle(fontFamily: _body, fontSize: 16, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF2D1B36) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF2D1B36) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: isDark,
      fillColor: isDark ? const Color(0xFF3E224A) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(fontFamily: _body, fontSize: 16, color: isDark ? Colors.white70 : null),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? const Color(0xFFC9B1FF) : const Color(0xFFE91E8C),
      foregroundColor: isDark ? const Color(0xFF2D1B36) : Colors.white,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF5A3D6B) : const Color(0xFFF0C0D0),
      thickness: 1,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: _body, fontSize: 20, letterSpacing: 1,
        color: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C)),
      titleMedium: TextStyle(fontFamily: _body, fontSize: 22,
        color: isDark ? Colors.white : null),
      titleSmall: TextStyle(fontFamily: _body, fontSize: 18,
        color: isDark ? Colors.white70 : null),
      bodyLarge: TextStyle(fontFamily: _body, fontSize: 20,
        color: isDark ? Colors.white : null),
      bodyMedium: TextStyle(fontFamily: _body, fontSize: 18,
        color: isDark ? Colors.white : null),
      bodySmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFFB39DDB) : const Color(0xFF888888)),
      labelLarge: TextStyle(fontFamily: _pixel, fontSize: 11, letterSpacing: 1.5,
        color: isDark ? const Color(0xFFFF9EB5) : const Color(0xFFE91E8C)),
      labelMedium: TextStyle(fontFamily: _body, fontSize: 18, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : null),
      labelSmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFFB39DDB) : null),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
//  PROFESSIONAL — clean corporate
// ─────────────────────────────────────────────────────────────────
ThemeData _buildProfessionalTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF4A90D9),
            onPrimary: Colors.white,
            secondary: Color(0xFF6C8EBF),
            onSecondary: Colors.white,
            tertiary: Color(0xFF50C878),
            onTertiary: Colors.white,
            error: Color(0xFFEF5350),
            onError: Colors.white,
            surface: Color(0xFF0D1B2A),
            onSurface: Color(0xFFE8EDF2),
            surfaceContainerHighest: Color(0xFF1B2838),
            outline: Color(0xFF2C3E50),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF1A5276),
            onPrimary: Colors.white,
            secondary: Color(0xFF5D8AA8),
            onSecondary: Colors.white,
            tertiary: Color(0xFF2E7D32),
            onTertiary: Colors.white,
            error: Color(0xFFC62828),
            onError: Colors.white,
            surface: Color(0xFFF5F7FA),
            onSurface: Color(0xFF1B2838),
            surfaceContainerHighest: Color(0xFFEBF0F5),
            outline: Color(0xFFCED4DA),
          ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F7FA),
      foregroundColor: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276),
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: _body, fontSize: 20, fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276),
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: isDark ? const Color(0xFF1B2838) : Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 16, letterSpacing: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(fontFamily: _body, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontFamily: _body, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      contentTextStyle: const TextStyle(fontFamily: _body, fontSize: 15),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1B2838) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFCED4DA),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(fontFamily: _body, fontSize: 16, color: isDark ? Colors.white70 : null),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276),
      foregroundColor: Colors.white,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFCED4DA),
      thickness: 1,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: _body, fontSize: 20, fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276)),
      titleMedium: TextStyle(fontFamily: _body, fontSize: 22,
        color: isDark ? Colors.white : null),
      titleSmall: TextStyle(fontFamily: _body, fontSize: 18,
        color: isDark ? Colors.white70 : null),
      bodyLarge: TextStyle(fontFamily: _body, fontSize: 20,
        color: isDark ? Colors.white : null),
      bodyMedium: TextStyle(fontFamily: _body, fontSize: 18,
        color: isDark ? Colors.white : null),
      bodySmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFF8899AA) : const Color(0xFF6C757D)),
      labelLarge: TextStyle(fontFamily: _body, fontSize: 14, fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A5276)),
      labelMedium: TextStyle(fontFamily: _body, fontSize: 18, fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : null),
      labelSmall: TextStyle(fontFamily: _body, fontSize: 16,
        color: isDark ? const Color(0xFF8899AA) : const Color(0xFF6C757D)),
    ),
  );
}
