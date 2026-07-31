// Stub — never actually used at runtime; satisfies the analyzer.
abstract class PlatformStorage {
  static Future<String?> readToken() async => null;
  static Future<void> writeToken(String token) async {}
  static Future<void> deleteToken() async {}

  static Future<String?> readAdminCookie() async => null;
  static Future<void> writeAdminCookie(String cookie) async {}
  static Future<void> deleteAdminCookie() async {}
}
