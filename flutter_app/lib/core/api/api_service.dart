import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/config.dart';
import '../utils/secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final String? token = await SecureStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  ApiException _handleError(http.Response response) {
    String errorMessage = 'Something went wrong';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) {
        errorMessage = body['message'] ?? errorMessage;
      }
    } catch (_) {}
    return ApiException(errorMessage, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت وتأكيد تشغيل السيرفر وعنوان الـ IP.');
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, String? idempotencyKey}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final headers = await _getHeaders();
      if (idempotencyKey != null) {
        headers['X-Idempotency-Key'] = idempotencyKey;
      }
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // If the response contains a new JWT token, automatically save it
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'];
          if (data.containsKey('token')) {
            await SecureStorage.saveToken(data['token']);
          }
        }
        return responseData;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت وتأكيد تشغيل السيرفر وعنوان الـ IP.');
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت وتأكيد تشغيل السيرفر وعنوان الـ IP.');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final response = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت وتأكيد تشغيل السيرفر وعنوان الـ IP.');
    }
  }
}
