import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing global ThemeMode state across the app.
class ThemeService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_theme_mode';

  /// Default to Light Mode as requested
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// Load persisted theme setting if available
  static Future<void> init() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (saved == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else {
        themeModeNotifier.value = ThemeMode.light; // Default to light mode
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Toggle or set dark mode state
  static Future<void> toggleTheme(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      await _storage.write(key: _key, value: isDark ? 'dark' : 'light');
    } catch (_) {}
  }
}
