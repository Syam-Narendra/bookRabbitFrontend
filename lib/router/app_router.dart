import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layouts/main_layout.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/setup_profile_screen.dart';
import '../screens/ground_details_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/support_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../screens/vendor_login_screen.dart';
import '../screens/vendor_register_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/tabs/discover_tab.dart';
import '../screens/tabs/history_tab.dart';
import '../screens/tabs/account_tab.dart';
import '../services/api_client.dart';
import '../services/vendor_auth_service.dart';
import 'app_routes.dart';

/// The primary application router configured with [StatefulShellRoute.indexedStack].
///
/// Features:
/// 1. Fixed persistent layout ([MainLayout]) with BottomNavigationBar / NavigationRail.
/// 2. Independent navigation stacks for each tab (Home, History, Account).
/// 3. Preserved widget state, scroll position, and tab history.
/// 4. Dynamic URL routes (/grounds/:groundId, /history/:historyId) embedded in tab branches.
/// 5. Standalone full-screen routes (Splash, Login, Vendor, Support, Terms) outside the shell.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,

  // ── Global Auth Redirect Guard ───────────────────────────────────────────
  redirect: (BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // Check customer bearer token
    final bool hasUserToken =
        ApiClient.token != null && ApiClient.token!.isNotEmpty;

    // Check vendor owner session
    final bool isVendorLoggedIn = VendorAuthService.currentOwner != null;

    // Vendor protected routes (only vendorDashboard requires an active session)
    const vendorProtected = {
      AppRoutes.vendorDashboard,
    };
    if (vendorProtected.contains(location) && !isVendorLoggedIn) {
      return AppRoutes.vendorLogin;
    }

    // User protected routes
    const userProtected = {
      AppRoutes.home,
      AppRoutes.history,
      AppRoutes.account,
      AppRoutes.setupProfile,
    };
    final isProtectedDynamic = location.startsWith('/history') ||
        location.startsWith('/grounds');

    if ((userProtected.contains(location) || isProtectedDynamic) &&
        !hasUserToken) {
      return AppRoutes.userLogin;
    }

    // Redirect authenticated users away from login routes
    final isUserLoginLocation =
        location == AppRoutes.userLogin || location == '/login';
    if (isUserLoginLocation && hasUserToken) {
      return AppRoutes.home;
    }

    final isVendorLoginLocation =
        location == AppRoutes.vendorLogin || location == '/vendor_login';
    if (isVendorLoginLocation && isVendorLoggedIn) {
      return AppRoutes.vendorDashboard;
    }

    return null; // Allowed
  },

  // ── 404 Error Page ────────────────────────────────────────────────────────
  errorBuilder: (context, state) => const NotFoundScreen(),

  // ── Route Table ──────────────────────────────────────────────────────────
  routes: [
    // ── Standalone / Public / Auth Routes (Outside the Shell) ───────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.userLogin,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.setupProfile,
      builder: (context, state) => const SetupProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.vendorLogin,
      builder: (context, state) => const VendorLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerGround,
      builder: (context, state) => const VendorRegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.vendorDashboard,
      builder: (context, state) => const VendorDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.support,
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: AppRoutes.terms,
      builder: (context, state) => const TermsConditionsScreen(),
    ),

    // ── Stateful Shell Route (Houses Home, History, Account Tabs) ────────────
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // ── Branch 0: Home / Discover Branch ────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const DiscoverTab(),
            ),
            GoRoute(
              path: AppRoutes.groundDetail,
              builder: (context, state) {
                final groundId = state.pathParameters['groundId']!;
                final ground = state.extra as Map<String, dynamic>?;
                return GroundDetailsScreen(
                  groundId: groundId,
                  ground: ground ?? const {},
                );
              },
            ),
          ],
        ),

        // ── Branch 1: History Branch ─────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, state) => const HistoryTab(),
            ),
            GoRoute(
              path: AppRoutes.historyDetail,
              builder: (context, state) {
                final historyId = state.pathParameters['historyId']!;
                final booking = state.extra as Map<String, dynamic>?;
                return _BookingDetailPage(
                  historyId: historyId,
                  booking: booking,
                );
              },
            ),
          ],
        ),

        // ── Branch 2: Account Branch ─────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.account,
              builder: (context, state) => const AccountTab(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── Booking Detail Page Async Shell ──────────────────────────────────────────

class _BookingDetailPage extends StatefulWidget {
  final String historyId;
  final Map<String, dynamic>? booking;
  const _BookingDetailPage({required this.historyId, this.booking});

  @override
  State<_BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<_BookingDetailPage> {
  Map<String, dynamic>? _booking;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _booking = widget.booking;
    } else {
      _fetchBooking();
    }
  }

  Future<void> _fetchBooking() async {
    setState(() => _loading = true);
    try {
      final bookings = await _fetchMyBookings();
      final match = bookings.firstWhere(
        (b) =>
            b['id']?.toString() == widget.historyId ||
            b['referenceId']?.toString() == widget.historyId,
        orElse: () => const {},
      );
      if (!mounted) return;
      if (match.isEmpty) {
        setState(() {
          _error = 'Booking not found.';
          _loading = false;
        });
      } else {
        setState(() {
          _booking = match;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load booking.';
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMyBookings() async {
    final data =
        await ApiClient.get('/api/mobile/bookings') as Map<String, dynamic>;
    final bookings = data['bookings'] as List<dynamic>;
    return bookings.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Detail')),
        body: Center(
          child: Text(_error ?? 'Booking not found.',
              style: const TextStyle(fontSize: 16)),
        ),
      );
    }
    return BookingDetailScreen(booking: _booking!);
  }
}
