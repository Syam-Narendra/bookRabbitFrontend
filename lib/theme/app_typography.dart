import 'package:flutter/material.dart';

/// Centralized typography for Book Rabbit.
///
/// Uses Inter font family.
///
/// Usage:
///   Text('Hello', style: AppTypography.heading)
///   Text('Card', style: AppTypography.cardTitle)
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Inter';

  // ─── Named styles (per spec) ──────────────────────────────────────────

  /// Heading — Inter Bold 36–42px
  static TextStyle get heading => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headingLg => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headingSm => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
      );

  /// Card title — Inter Semibold 22–24px
  static TextStyle get cardTitle => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle get cardTitleLg => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      );

  /// Body — Inter Regular 16–18px
  static TextStyle get body => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyLg => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Button — Inter Semibold 18px
  static TextStyle get button => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSm => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  /// Small label — Inter Medium 13–14px
  static TextStyle get label => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSm => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  /// Caption (12px, regular)
  static TextStyle get caption => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ─── ThemeData TextTheme ──────────────────────────────────────────────
  /// Drop this into ThemeData.textTheme so Material widgets inherit it.
  static TextTheme get textTheme => TextTheme(
        displayLarge: headingLg,
        displayMedium: heading,
        displaySmall: headingSm,
        headlineMedium: cardTitleLg,
        headlineSmall: cardTitle,
        titleLarge: cardTitle,
        titleMedium: const TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: bodyLg,
        bodyMedium: body,
        bodySmall: label,
        labelLarge: button,
        labelMedium: label,
        labelSmall: labelSm,
      );
}
