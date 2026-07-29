import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/vendor_login_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_success_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/support_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Book Rabbit',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/vendor_login': (context) => const VendorLoginScreen(),
            '/setup_profile': (context) => AuthService.currentUser != null ? const SetupProfileScreen() : const LoginScreen(),
            '/test-success': (context) => BookingSuccessScreen(
                  referenceId: 'BRB-250524-00123',
                  ground: const {
                    'title': 'Greenfield Football Turf',
                    'location': 'Banjara Hills, Hyderabad, Telangana',
                    'rating': 4.6,
                    'imageUrl': 'https://images.unsplash.com/photo-1459865264687-595d652de67e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  },
                  date: DateTime.now(),
                  startTime: '06:00 PM',
                  endTime: '08:00 PM',
                  finalPrice: 600,
                ),
            '/terms': (context) => const TermsConditionsScreen(),
            '/support': (context) => const SupportScreen(),
            '/home': (context) => AuthService.currentUser != null ? const HomeScreen() : const LoginScreen(),
          },
        );
      },
    );
  }
}

