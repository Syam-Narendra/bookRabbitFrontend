import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../router/route_extensions.dart';
import '../theme/app_theme.dart';

/// Shown when the user navigates to an unknown URL.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5200).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 52,
                  color: Color(0xFFFF5200),
                ),
              )
                  .animate()
                  .fade(duration: 500.ms)
                  .scale(curve: Curves.easeOutBack, duration: 500.ms),
              const SizedBox(height: 28),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: context.textColor,
                  letterSpacing: -2,
                ),
              )
                  .animate()
                  .fade(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 8),
              Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              )
                  .animate()
                  .fade(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              Text(
                "The page you're looking for doesn't exist or has been moved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: context.subTextColor,
                ),
              ).animate().fade(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: ElevatedButton.icon(
                    onPressed: () => context.goHome(),
                    icon: const Icon(Icons.home_outlined, color: Colors.white),
                    label: const Text(
                      'Go to Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5200),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: 280.ms, duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    color: context.subTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fade(delay: 330.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
