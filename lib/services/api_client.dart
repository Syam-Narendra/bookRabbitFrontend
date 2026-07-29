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


  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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
