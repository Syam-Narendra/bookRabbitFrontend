class AppConstants {
  // Base URL for backend API.
  // Override at build/run time with --dart-define=API_BASE_URL=https://api.bookrabbit.com
  // so release builds don't ship pointed at localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Razorpay key.
  // Inject the live key at release-build time with
  // --dart-define=RAZORPAY_KEY_ID=rzp_live_xxxxxxxx, never ship a live key
  // hardcoded in source. The default below is the test key (dev only).
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_Szu0Z5NWw1MiEJ',
  );

  // App invite link
  static const String inviteLink = 'https://bookrabbit.com/invite/alex';
}
