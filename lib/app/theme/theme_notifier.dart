import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _modeKey = 'themeMode';
  static const _legacyKey = 'isDark';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    if (saved != null) {
      state = ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
      return;
    }
    // Migrate the old light/dark flag.
    final isDark = prefs.getBool(_legacyKey);
    if (isDark != null) state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  /// Flips between light and dark, resolving "system" first.
  Future<void> toggleTheme([Brightness? current]) {
    final isDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => current == Brightness.dark,
    };
    return setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
