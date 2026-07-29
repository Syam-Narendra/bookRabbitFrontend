// Native (iOS/Android/macOS/Windows/Linux) implementation: uses flutter_secure_storage
// for OS-level keychain / keystore encryption.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PlatformStorage {
  static const _key = 'br_auth_token';
  static const _storage = FlutterSecureStorage();

  static Future<String?> readToken() async {
    return _storage.read(key: _key);
  }

  static Future<void> writeToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _key);
  }
}
