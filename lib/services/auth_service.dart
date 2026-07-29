import 'dart:io';
import '../models/app_user.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static AppUser? currentUser;

  /// Returns the OTP when the backend includes it (dev/stage only — omitted in production).
  static Future<String?> sendOtp(String phone) async {
    final data = await ApiClient.post('/api/mobile/otp/send', body: {'phone': phone}) as Map<String, dynamic>;
    return data['otp'] as String?;
  }

  static Future<AppUser> verifyOtp(String phone, String otp) async {
    final data = await ApiClient.post(
      '/api/mobile/otp/verify',
      body: {'phone': phone, 'otp': otp},
    ) as Map<String, dynamic>;

    final token = data['token'] as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    await ApiClient.setToken(token);
    currentUser = user;
    return user;
  }

  static Future<AppUser> fetchMe() async {
    final data = await ApiClient.get('/api/mobile/me') as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  static Future<AppUser> updateName(String fullName) async {
    final data = await ApiClient.patch(
      '/api/mobile/me',
      body: {'full_name': fullName},
    ) as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  static Future<AppUser> updateProfileImage(File file) async {
    final data = await ApiClient.uploadFile(
      '/api/mobile/me/photo',
      fieldName: 'image',
      file: file,
    ) as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  static Future<AppUser> updateProfileImageBytes(List<int> bytes, String filename) async {
    final data = await ApiClient.uploadBytes(
      '/api/mobile/me/photo',
      fieldName: 'image',
      bytes: bytes,
      filename: filename,
    ) as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    currentUser = user;
    return user;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/api/mobile/logout');
    } catch (_) {
      // Best-effort — clear local state regardless.
    }
    currentUser = null;
    await ApiClient.clearToken();
  }

  /// Called at app boot. Returns true if a valid, still-live session was restored.
  static Future<bool> restoreSession() async {
    await ApiClient.loadToken();
    if (ApiClient.token == null) return false;

    try {
      await fetchMe();
      return true;
    } catch (_) {
      currentUser = null;
      await ApiClient.clearToken();
      return false;
    }
  }
}
