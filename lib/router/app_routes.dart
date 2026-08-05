/// Centralized route path constants.
///
/// Every URL in the app is defined exactly once here.
/// Use [AppRoutes] everywhere instead of raw string literals.
class AppRoutes {
  AppRoutes._();

  // ── Public (no auth required) ──────────────────────────────────────────────
  static const splash        = '/';
  static const userLogin     = '/user_login';
  static const vendorLogin   = '/vendor_login';
  static const support       = '/support';
  static const terms         = '/terms';

  // ── User-auth protected ────────────────────────────────────────────────────
  static const home          = '/home';
  static const history       = '/history';
  static const historyDetail = '/history/:historyId';
  static const account       = '/account';
  static const groundDetail  = '/grounds/:groundId';
  static const setupProfile  = '/setup_profile';

  // ── Vendor-auth protected ──────────────────────────────────────────────────
  static const registerGround  = '/register-ground';
  static const vendorDashboard = '/vendor_dashboard';

  // ── Helpers ───────────────────────────────────────────────────────────────
  /// Builds a concrete history-detail URL, e.g. `/history/123`.
  static String historyDetailFor(String id) => '/history/$id';

  /// Builds a concrete ground-detail URL, e.g. `/grounds/45`.
  static String groundDetailFor(String id) => '/grounds/$id';
}
