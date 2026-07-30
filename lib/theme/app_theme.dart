import 'package:flutter/material.dart';
import 'app_typography.dart';

/// Centralized app colors & theme configuration.
class AppTheme {
  AppTheme._();

  static const Color primaryOrange = Color(0xFFFF4B3A);
  static const Color primaryOrangeAccent = Color(0xFFE54F3F);

  // Light Theme Colors (White / Light Mode)
  static const Color lightBg = Color(0xFFF9F9FB);
  static const Color lightCard = Colors.white;
  static const Color lightSubCard = Color(0xFFF2F2F7);
  static const Color lightText = Color(0xFF111111);
  static const Color lightSubText = Color(0xFF6E6E73);
  static const Color lightBorder = Color(0xFFE5E5EA);

  // Dark Theme Colors (Dark Mode)
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkSubCard = Color(0xFF2C2C2E);
  static const Color darkText = Colors.white;
  static const Color darkSubText = Color(0xFF98989E);
  static const Color darkBorder = Color(0xFF2C2C2E);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      primaryColor: primaryOrange,
      fontFamily: 'Inter',
      textTheme: AppTypography.textTheme.apply(
        bodyColor: lightText,
        displayColor: lightText,
        decorationColor: lightText,
      ),
      primaryTextTheme: AppTypography.textTheme.apply(
        bodyColor: lightText,
        displayColor: lightText,
        decorationColor: lightText,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        surface: lightCard,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFD32F2F),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      primaryColor: primaryOrange,
      fontFamily: 'Inter',
      textTheme: AppTypography.textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
        decorationColor: darkText,
      ),
      primaryTextTheme: AppTypography.textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
        decorationColor: darkText,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        surface: darkCard,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFD32F2F),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Extension on BuildContext for quick, clean access to theme colors
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => isDark ? AppTheme.darkBg : AppTheme.lightBg;
  Color get cardBg => isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get subCardBg => isDark ? AppTheme.darkSubCard : AppTheme.lightSubCard;
  Color get textColor => isDark ? AppTheme.darkText : AppTheme.lightText;
  Color get subTextColor => isDark ? AppTheme.darkSubText : AppTheme.lightSubText;
  Color get borderColor => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
}
