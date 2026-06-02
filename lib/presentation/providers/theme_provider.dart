import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/di/providers.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../theme/themes.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier(ref.watch(preferencesRepositoryProvider));
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(preferencesRepositoryProvider));
});

final appDarkThemeDataProvider = Provider<ThemeData>((ref) {
  final theme = ref.watch(themeProvider);
  return buildTheme(theme, Brightness.dark);
});

final appLightThemeDataProvider = Provider<ThemeData>((ref) {
  final theme = ref.watch(themeProvider);
  return buildTheme(theme, Brightness.light);
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  final PreferencesRepository _prefs;

  ThemeNotifier(this._prefs) : super(AppTheme.professional) {
    _load();
  }

  Future<void> _load() async {
    final index = await _prefs.getInt('app_theme') ?? AppTheme.professional.index;
    state = AppTheme.values[index];
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    await _prefs.setInt('app_theme', theme.index);
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesRepository _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final index = await _prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt('theme_mode', mode.index);
  }
}
