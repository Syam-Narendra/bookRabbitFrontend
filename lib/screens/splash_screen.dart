import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../router/route_extensions.dart';
import '../services/auth_service.dart';
import '../theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    //  REMOVE before production — deliberate delay to test splash screen on web
    // await Future.delayed(const Duration(seconds: 3));

    // Precache the logo image to ensure 0-frame delay/flicker when native splash is removed
    await precacheImage(
      const AssetImage('assets/images/sports_bunnies.png'),
      context,
    ).catchError((_) {});

    // Remove native splash seamlessly once Flutter has rendered its first frame and image is ready
    // Use Object catch to handle both Exception and PlatformException (web throws PlatformException)
    try {
      FlutterNativeSplash.remove();
    } on PlatformException catch (_) {
      // Web: flutter_native_splash not generated for web, safe to ignore
    } catch (_) {
      // Any other error removing splash — safe to ignore
    }

    // Restore auth session
    final isLoggedIn = await AuthService.restoreSession();

    if (!mounted) return;

    if (isLoggedIn) {
      context.goHome();
    } else {
      context.goUserLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Ambient background glow accents
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4B3A).withValues(alpha: 0.15),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF57C4C).withValues(alpha: 0.12),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Book Rabbit Mascots Branding
                  ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/sports_bunnies.png',
                          width: 170,
                          height: 170,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF4B3A,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sports_soccer,
                                  size: 56,
                                  color: Color(0xFFFF4B3A),
                                ),
                              ),
                        ),
                      )
                      .animate()
                      .fade(duration: 550.ms)
                      .scale(curve: Curves.easeOutBack, duration: 550.ms),

                  const SizedBox(height: 24),

                  // App Title
                  Text(
                        'Book Rabbit',
                        style: AppTypography.heading.copyWith(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fade(delay: 150.ms, duration: 450.ms)
                      .slideY(begin: 0.15, end: 0, duration: 450.ms),

                  const SizedBox(height: 8),

                  // App Tagline
                  Text(
                        'Instantly book your favourite sports grounds',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )
                      .animate()
                      .fade(delay: 280.ms, duration: 450.ms)
                      .slideY(begin: 0.15, end: 0, duration: 450.ms),

                  const SizedBox(height: 48),

                  // Loading Indicator
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF4B3A),
                      ),
                    ),
                  ).animate().fade(delay: 400.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
