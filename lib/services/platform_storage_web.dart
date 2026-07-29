// Web implementation using the modern package:web + dart:js_interop approach.
// Uses window.localStorage directly — reliable across page refreshes, no encryption issues.
import 'package:web/web.dart' as web;

abstract class PlatformStorage {
  static const _key = 'br_auth_token';

  static Future<String?> readToken() async {
    final val = web.window.localStorage.getItem(_key);
    return (val == null || val.isEmpty) ? null : val;
  }

  static Future<void> writeToken(String token) async {
    web.window.localStorage.setItem(_key, token);
  }

  static Future<void> deleteToken() async {
    web.window.localStorage.removeItem(_key);
  }
}
