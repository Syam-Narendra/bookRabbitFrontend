import 'package:flutter/material.dart';

/// Centralized SnackBar helper for Book Rabbit.
/// Ensures all error, success, and info notifications are centered
/// and width-constrained on Web / Desktop viewports (never stretching left-to-right).
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: isWide ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1E1E24),
        behavior: SnackBarBehavior.floating,
        width: isWide ? (screenWidth > 520 ? 480 : screenWidth - 32) : null,
        margin: !isWide ? const EdgeInsets.all(16) : null,
        duration: duration,
        action: action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFFE53935));
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFF2E7D32));
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, backgroundColor: const Color(0xFFFF7A2F));
  }
}
