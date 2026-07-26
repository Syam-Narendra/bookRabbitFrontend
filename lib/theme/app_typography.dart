import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography for Book Rabbit.
///
/// Uses Plus Jakarta Sans (Google Fonts) — the closest open-source match to
/// SF Pro Display/Text in weight, spacing, and proportions.
///
/// Usage:
///   Text('Hello', style: AppTypography.heading)
///   Text('Card', style: AppTypography.cardTitle)
class AppTypography {
  AppTypography._();

  // ─── Named styles (per spec) ──────────────────────────────────────────

  /// Heading — SF Pro Display Bold 36–42px
  static TextStyle get heading => GoogleFonts.plusJakartaSans(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headingLg => GoogleFonts.plusJakartaSans(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get headingSm => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.15,
      );

  /// Card title — SF Pro Display Semibold 22–24px
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle get cardTitleLg => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      );

  /// Body — SF Pro Text Regular 16–18px
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Button — SF Pro Display Semibold 18px
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSm => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  /// Small label — SF Pro Text Medium 13–14px
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  /// Caption (12px, regular)
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ─── ThemeData TextTheme ──────────────────────────────────────────────
  /// Drop this into ThemeData.textTheme so Material widgets inherit it.
  static TextTheme get textTheme => GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: headingLg,
        displayMedium: heading,
        displaySmall: headingSm,
        headlineMedium: cardTitleLg,
        headlineSmall: cardTitle,
        titleLarge: cardTitle,
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: bodyLg,
        bodyMedium: body,
        bodySmall: label,
        labelLarge: button,
        labelMedium: label,
        labelSmall: labelSm,
      );
}
