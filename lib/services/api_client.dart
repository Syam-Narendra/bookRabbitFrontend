import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thin HTTP wrapper: base URL + bearer-token auth header + JSON error unpacking.
class ApiClient {
  ApiClient._();

  static const _tokenKey = 'auth_token';
  static final _storage = FlutterSecureStorage();

  static String? _token;

  static String? get token => _token;

  /// Hydrate the in-memory token from secure storage. Call once at app boot.
  static Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
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

  static dynamic _decode(http.Response response) {
    Map<String, dynamic>? data;
    try {
      data = response.body.isNotEmpty
          ? json.decode(response.body) as Map<String, dynamic>
          : null;
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data?['error'] as String? ??
          'Something went wrong (${response.statusCode}). Please try again.';
      throw ApiException(message);
    }

    return data;
  }
}
