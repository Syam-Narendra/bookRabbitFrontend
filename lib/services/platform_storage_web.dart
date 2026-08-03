// Web implementation using the modern package:web + dart:js_interop approach.
//
// Uses window.sessionStorage instead of localStorage: sessionStorage is scoped
// to the browser tab and cleared when it closes, so a stolen token/cookie via
// XSS is not persisted across sessions. Same-tab refreshes still restore the
// session. (Full mitigation would require HttpOnly cookies + a cookie-backed
// auth flow on the web build; sessionStorage is the practical middle ground.)
import 'package:web/web.dart' as web;

abstract class PlatformStorage {
  static const _key = 'br_auth_token';
  static const _adminCookieKey = 'br_admin_cookie';

  static String? _read(String key) {
    final val = web.window.sessionStorage.getItem(key);
    return (val == null || val.isEmpty) ? null : val;
  }

  static void _write(String key, String value) {
    web.window.sessionStorage.setItem(key, value);
  }

  static void _delete(String key) {
    web.window.sessionStorage.removeItem(key);
  }

  static Future<String?> readToken() async => _read(_key);

  static Future<void> writeToken(String token) async => _write(_key, token);

  static Future<void> deleteToken() async => _delete(_key);

  static Future<String?> readAdminCookie() async => _read(_adminCookieKey);

  static Future<void> writeAdminCookie(String cookie) async => _write(_adminCookieKey, cookie);

  static Future<void> deleteAdminCookie() async => _delete(_adminCookieKey);
}
