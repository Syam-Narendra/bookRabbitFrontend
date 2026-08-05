import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'utils/configure_url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable clean path-based URLs (no # hash) for Flutter Web conditionally.
  configureUrlStrategy();

  // Run theme + token load in parallel before showing any UI.
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
        return MaterialApp.router(
          title: 'Book Rabbit',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: appRouter,
        );
      },
    );
  }
}
