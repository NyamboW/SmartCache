import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options for the app
enum AppThemeMode {
  system('Follow System', Icons.brightness_auto),
  light('Light', Icons.light_mode),
  dark('Dark', Icons.dark_mode);

  final String label;
  final IconData icon;

  const AppThemeMode(this.label, this.icon);

  /// Convert to Flutter's ThemeMode
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Parse from string (for storage)
  static AppThemeMode fromString(String value) {
    switch (value) {
      case 'system':
        return AppThemeMode.system;
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  /// Convert to string (for storage)
  String toStorageString() {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }
}

/// Provider for managing app theme with persistent storage
class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme_mode';

  AppThemeMode _themeMode;
  final SharedPreferences _prefs;

  /// Private constructor - use ThemeProvider.initialize() instead
  ThemeProvider._(this._prefs, this._themeMode);

  /// Factory method to create ThemeProvider with loaded preferences
  static Future<ThemeProvider> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);

      final themeMode = savedTheme != null
          ? AppThemeMode.fromString(savedTheme)
          : AppThemeMode.system;

      return ThemeProvider._(prefs, themeMode);
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Fallback to system theme if loading fails
      final prefs = await SharedPreferences.getInstance();
      return ThemeProvider._(prefs, AppThemeMode.system);
    }
  }

  /// Current theme mode
  AppThemeMode get themeMode => _themeMode;

  /// Flutter's ThemeMode for MaterialApp
  ThemeMode get flutterThemeMode => _themeMode.themeMode;

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      await _prefs.setString(_themePreferenceKey, mode.toStorageString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Reset to system theme
  Future<void> resetToSystem() async {
    await setThemeMode(AppThemeMode.system);
  }

  /// Check if current mode matches the given mode
  bool isCurrentMode(AppThemeMode mode) => _themeMode == mode;
}
