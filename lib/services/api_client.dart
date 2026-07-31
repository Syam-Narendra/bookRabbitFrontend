import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import 'platform_storage.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thrown specifically when the server returns 401 or 403.
/// Use this to distinguish auth failures from transient network errors.
class AuthException extends ApiException {
  const AuthException(super.message);
}

/// Thin HTTP wrapper: base URL + bearer-token auth header + JSON error unpacking.
class ApiClient {
  ApiClient._();

  static String? _token;

  static String? get token => _token;

  /// Hydrate the in-memory token from platform storage. Call once at app boot.
  static Future<void> loadToken() async {
    _token = await PlatformStorage.readToken();
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await PlatformStorage.writeToken(token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await PlatformStorage.deleteToken();
  }

  // --- Admin/vendor session (cookie-based, fully separate from the bearer
  // token above — the backend's admin API issues a Set-Cookie session, not a
  // bearer token). ---
  static String? _adminCookie;

  static Future<void> loadAdminCookie() async {
    _adminCookie = await PlatformStorage.readAdminCookie();
  }

  static Future<void> setAdminCookie(String cookie) async {
    _adminCookie = cookie;
    await PlatformStorage.writeAdminCookie(cookie);
  }

  static Future<void> clearAdminCookie() async {
    _adminCookie = null;
    await PlatformStorage.deleteAdminCookie();
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Map<String, String> get _adminHeaders => {
        'Content-Type': 'application/json',
        if (_adminCookie != null) 'Cookie': _adminCookie!,
      };

  /// Captures the `name=value` part of a `Set-Cookie` response header (if
  /// present) and persists it, so the next admin request re-sends it.
  static Future<void> _captureAdminCookie(http.Response response) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final cookiePair = setCookie.split(';').first.trim();
    if (cookiePair.isNotEmpty) await setAdminCookie(cookiePair);
  }

  static Future<dynamic> adminGet(String path) async {
    final response =
        await http.get(Uri.parse('${AppConstants.apiBaseUrl}$path'), headers: _adminHeaders);
    await _captureAdminCookie(response);
    return _decode(response);
  }

  static Future<dynamic> adminPost(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _adminHeaders,
      body: body != null ? json.encode(body) : null,
    );
    await _captureAdminCookie(response);
    return _decode(response);
  }

  static Future<dynamic> adminPatch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _adminHeaders,
      body: body != null ? json.encode(body) : null,
    );
    await _captureAdminCookie(response);
    return _decode(response);
  }

  static Future<dynamic> get(String path) async {
    final response =
        await http.get(Uri.parse('${AppConstants.apiBaseUrl}$path'), headers: _headers);
    return _decode(response);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _decode(response);
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _decode(response);
  }

  static Future<dynamic> uploadFile(
    String path, {
    String method = 'PATCH',
    required String fieldName,
    required File file,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('${AppConstants.apiBaseUrl}$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';

    // Derive MIME type from extension so we never send application/octet-stream,
    // which the backend rejects.  ImagePicker temp files on Android sometimes
    // have no extension, so we default to image/jpeg (the most common format).
    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      'gif'  => 'image/gif',
      _      => 'image/jpeg',  // jpg / jpeg / unknown → safe default
    };

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }

  static Future<dynamic> uploadBytes(
    String path, {
    String method = 'PATCH',
    required String fieldName,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('${AppConstants.apiBaseUrl}$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';

    final ext = filename.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      'gif'  => 'image/gif',
      _      => 'image/jpeg',
    };

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    Map<String, dynamic>? data;
    try {
      data = response.body.isNotEmpty
          ? json.decode(response.body) as Map<String, dynamic>
          : null;
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final message = data?['error'] as String? ?? 'Session expired. Please login again.';
      throw AuthException(message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data?['error'] as String? ??
          'Something went wrong (${response.statusCode}). Please try again.';
      throw ApiException(message);
    }

    return data;
  }
}
