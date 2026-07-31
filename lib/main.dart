import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/vendor_login_screen.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_success_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/support_screen.dart';
import 'services/auth_service.dart';
import 'services/vendor_auth_service.dart';
import 'services/api_client.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Run theme + token load in parallel before showing any UI
  await Future.wait([
    ThemeService.init(),
    ApiClient.loadToken(), // Fast local-storage read — NO network call
    ApiClient.loadAdminCookie(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        // Optimistic auth: if a token exists on disk, show HomeScreen immediately.
        // HomeScreen will verify the token in the background and redirect to login
        // only if the server rejects it. No flash of LoginScreen for valid sessions.
        final Widget initialScreen = ApiClient.token != null
            ? const _SessionVerifierHome()
            : const SplashScreen();

        return MaterialApp(
          title: 'Book Rabbit',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: initialScreen,
          routes: {
            '/login': (context) => AuthService.currentUser != null
                ? const HomeScreen()
                : const LoginScreen(),
            '/vendor_login': (context) => const VendorLoginScreen(),
            '/vendor_dashboard': (context) => VendorAuthService.currentOwner != null
                ? const VendorDashboardScreen()
                : const VendorLoginScreen(),
            '/setup_profile': (context) => AuthService.currentUser != null
                ? const SetupProfileScreen()
                : const LoginScreen(),
            '/home': (context) => AuthService.currentUser != null
                ? const HomeScreen()
                : const LoginScreen(),
            '/terms': (context) => const TermsConditionsScreen(),
            '/support': (context) => const SupportScreen(),
            '/test-success': (context) => BookingSuccessScreen(
                  referenceId: 'BRB-250524-00123',
                  ground: const {
                    'title': 'Greenfield Football Turf',
                    'location': 'Banjara Hills, Hyderabad, Telangana',
                    'rating': 4.6,
                    'imageUrl':
                        'https://images.unsplash.com/photo-1459865264687-595d652de67e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  },
                  date: DateTime.now(),
                  startTime: '06:00 PM',
                  endTime: '08:00 PM',
                  finalPrice: 600,
                ),
          },
        );
      },
    );
  }
}

/// Shown immediately when a stored token is found on disk.
/// Renders HomeScreen at once (no flicker) and silently verifies
/// the session against the server in the background.
/// If the server rejects the token (401 / network error after retry),
/// it replaces the stack with LoginScreen.
class _SessionVerifierHome extends StatefulWidget {
  const _SessionVerifierHome();

  @override
  State<_SessionVerifierHome> createState() => _SessionVerifierHomeState();
}

class _SessionVerifierHomeState extends State<_SessionVerifierHome> {
  @override
  void initState() {
    super.initState();
    _verifyInBackground();
  }

  Future<void> _verifyInBackground() async {
    try {
      await AuthService.fetchMe(); // Sets currentUser if valid
    } on AuthException {
      // Server explicitly rejected the token (401/403) — clear and go to login
      await ApiClient.clearToken();
      AuthService.currentUser = null;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      // Network error, timeout, server error, etc.
      // Token may still be valid — keep user on HomeScreen silently.
      // They'll get errors on individual API calls if needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render HomeScreen immediately — no waiting, no flash
    return const HomeScreen();
  }
}
