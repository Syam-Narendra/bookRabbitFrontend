import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/touchable_opacity.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({
    super.key,
    this.onRetry,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (kIsWeb) {
        // Trigger page refresh on web to test connection
        // html.window.location.reload()
      }
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF191210) : const Color(0xFFFFF8F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              28,
              32,
              28,
              MediaQuery.of(context).size.width >= 720 ? 32 : 110,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Rabbit Image Illustration
                  Image.asset(
                    'assets/images/no_internet.png',
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/vendor-login-rabbit.png',
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  )
                      .animate()
                      .fade(duration: 400.ms)
                      .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.0, 1.0)),

                  const SizedBox(height: 32),

                  // 2. No Internet Heading
                  Text(
                    'No Internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                      letterSpacing: -0.4,
                    ),
                  )
                      .animate()
                      .fade(delay: 100.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 8),

                  // 3. Subtitle
                  Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: context.subTextColor,
                      height: 1.4,
                    ),
                  )
                      .animate()
                      .fade(delay: 200.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 36),

                  // 4. Primary Try Again Button
                  TouchableOpacity(
                    onTap: _isChecking ? null : _handleRetry,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5200),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5200).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isChecking)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fade(delay: 300.ms)
                      .slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
