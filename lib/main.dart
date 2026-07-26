import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'screens/login_screen.dart';
import 'screens/vendor_login_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_success_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthService.restoreSession();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Rabbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF4B3A),
        textTheme: AppTypography.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          decorationColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4B3A),
          surface: Color(0xFF1C1C1E),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
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
        '/home': (context) => AuthService.currentUser != null ? const HomeScreen() : const LoginScreen(),
      },
    );
  }
}
