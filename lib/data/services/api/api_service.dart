import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP API Service
class ApiService {
  ApiService._();

  static final _storage = GetStorage();
  static const String _tokenKey = 'AUTH_TOKEN';

  /// Get stored auth token
  static String? get authToken => _storage.read(_tokenKey);

  /// Save auth token
  static Future<void> saveToken(String token) async {
    await _storage.write(_tokenKey, token);
  }

  /// Clear auth token
  static Future<void> clearToken() async {
    await _storage.remove(_tokenKey);
  }

  /// Common headers with auth
  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Static backend token for the inspection/telecalling API
  static const String _backendToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q';

  /// Determine correct headers based on URL
  static Map<String, String> _headersForUrl(String url) {
    // The development backend uses its own JWT token, not the CRM token
    if (url.contains('otobix-app-backend-development.onrender.com') ||
        url.contains('ob-dealerapp-kong.onrender.com')) {
      return <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_backendToken',
      };
    }
    return _headers;
  }

  /// POST request
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      // ── Ultra-Robust Failsafe: Inject userId if missing or empty ──
      if (body.containsKey('userId') &&
          (body['userId']?.toString().isEmpty ?? true)) {
        final storage = GetStorage();
        String fallbackId = storage.read('USER_ID')?.toString() ?? '';

        // Try other common keys if USER_ID is empty
        if (fallbackId.isEmpty) {
          fallbackId =
              storage.read('user_id')?.toString() ??
              storage.read('uid')?.toString() ??
              '';
        }

        if (fallbackId.isNotEmpty) {
          body['userId'] = fallbackId;
        }
      }

      final headers = _headersForUrl(url);
      debugPrint('📡 POST: $url');
      debugPrint('🔑 Headers: $headers');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('📬 Status: ${response.statusCode}');
      debugPrint('📬 Response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw data['message'] ??
            data['error'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// GET request
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      debugPrint('📡 GET: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headersForUrl(url),
      );

      debugPrint('📬 Status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ??
            data['error'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      debugPrint('📡 PUT: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: _headersForUrl(url),
        body: jsonEncode(body),
      );

      debugPrint('📬 Status: ${response.statusCode}');
      debugPrint('📬 Response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw data['message'] ??
            data['error'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      debugPrint('📡 DELETE: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(_headersForUrl(url));
      request.body = jsonEncode(body);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📬 Status: ${response.statusCode}');
      _logResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ??
            data['error'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  /// Multipart POST request
  static Future<Map<String, dynamic>> multipartPost({
    required String url,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    try {
      debugPrint('📡 MULTIPART: $url');
      debugPrint('📦 Fields: $fields');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add Headers
      final headers = _headersForUrl(url);
      headers.remove('Content-Type'); // Let http set multipart boundary
      request.headers.addAll(headers);

      // Add Fields
      request.fields.addAll(fields);

      // Add Files
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📬 Status: ${response.statusCode}');
      _logResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw data['message'] ??
            data['error'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      rethrow;
    }
  }

  static void _logResponse(http.Response res) {
    if (res.body.length > 500) {
      debugPrint('📬 Response: ${res.body.substring(0, 500)}...');
    } else {
      debugPrint('📬 Response: ${res.body}');
    }
  }
}
