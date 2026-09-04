import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_theme.dart';

/// Gerencia o tema atual (claro/escuro) e persiste a preferência.
class ThemeNotifier extends ChangeNotifier {
  static const String _key = 'theme_mode';

  /// Command-center: escuro é o padrão (usuário pode trocar e persiste).
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  ThemeData get themeData {
    switch (_mode) {
      case ThemeMode.light:
        return AppTheme.light;
      case ThemeMode.dark:
        return AppTheme.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light;
    }
  }

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    _mode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // Sem preferência salva (ou 'system' legado) => escuro padrão.
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
