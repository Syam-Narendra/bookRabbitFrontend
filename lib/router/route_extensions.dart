import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// BuildContext extension providing typed navigation helpers.
///
/// Usage:
/// ```dart
/// context.goHome();
/// context.goGroundDetails('45');
/// context.goHistoryDetails('123', booking: bookingMap);
/// ```
extension AppNavigation on BuildContext {
  // ── User auth ──────────────────────────────────────────────────────────────
  void goUserLogin()     => go(AppRoutes.userLogin);
  void goSetupProfile()  => go(AppRoutes.setupProfile);

  // ── Vendor auth ────────────────────────────────────────────────────────────
  void goVendorLogin()     => go(AppRoutes.vendorLogin);
  void goRegisterGround()  => go(AppRoutes.registerGround);
  void goVendorDashboard() => go(AppRoutes.vendorDashboard);

  // ── Main screens ───────────────────────────────────────────────────────────
  void goHome()    => go(AppRoutes.home);
  void goHistory() => go(AppRoutes.history);
  void goAccount() => go(AppRoutes.account);

  // ── Dynamic screens ────────────────────────────────────────────────────────

  /// Navigate to a specific booking detail.
  /// Pass [booking] so the screen doesn't need to re-fetch if data is already
  /// in memory. On browser refresh the screen will fetch it via the API.
  void goHistoryDetails(
    String historyId, {
    Map<String, dynamic>? booking,
  }) =>
      go(AppRoutes.historyDetailFor(historyId), extra: booking);

  /// Navigate to a ground's detail page.
  /// Pass [ground] so the screen uses the in-memory data when available.
  /// On browser refresh the screen re-fetches from the API using [groundId].
  void goGroundDetails(
    String groundId, {
    Map<String, dynamic>? ground,
  }) =>
      go(AppRoutes.groundDetailFor(groundId), extra: ground);

  // ── Static pages ────────────────────────────────────────────────────────────
  void goSupport() => go(AppRoutes.support);
  void goTerms()   => go(AppRoutes.terms);
}
