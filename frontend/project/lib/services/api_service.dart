import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static String? _token;
  
  static void setToken(String token) {
    _token = token;
  }
  
  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // GET Request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  static Future<Map<String, dynamic>> put(
    String endpoint, 
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  static Future<Map<String, dynamic>> patch(
    String endpoint, 
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload File (for mobile - uses File)
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file,
    String fieldName,
  ) async {
    try {
      print('Uploading file to: ${AppConstants.baseUrl}$endpoint'); // Debug log
      print('File path: ${file.path}'); // Debug log
      print('Field name: $fieldName'); // Debug log
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );
      
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('Token attached: ${_token!.substring(0, 20)}...'); // Debug log (partial token)
      } else {
        print('WARNING: No token attached to upload request'); // Debug log
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
        ),
      );
      
      print('Sending upload request...'); // Debug log
      final streamedResponse = await request.send();
      print('Response status: ${streamedResponse.statusCode}'); // Debug log
      
      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}'); // Debug log
      
      return _handleResponse(response);
    } catch (e) {
      print('Upload error: $e'); // Debug log
      throw _handleError(e);
    }
  }

  // Upload File Bytes (for web - uses Uint8List)
  static Future<Map<String, dynamic>> uploadFileBytes(
    String endpoint,
    Uint8List bytes,
    String fieldName,
    String filename,
  ) async {
    try {
      print('Uploading file bytes to: ${AppConstants.baseUrl}$endpoint'); // Debug log
      print('File size: ${bytes.length} bytes'); // Debug log
      print('Field name: $fieldName'); // Debug log
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );
      
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('Token attached: ${_token!.substring(0, 20)}...'); // Debug log (partial token)
      } else {
        print('WARNING: No token attached to upload request'); // Debug log
      }
      
      // Determine content type from filename extension
      String contentType = 'image/jpeg'; // default
      final ext = filename.toLowerCase().split('.').last;
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      }
      print('Content type: $contentType'); // Debug log
      
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
      
      print('Sending upload request...'); // Debug log
      final streamedResponse = await request.send();
      print('Response status: ${streamedResponse.statusCode}'); // Debug log
      
      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}'); // Debug log
      
      return _handleResponse(response);
    } catch (e) {
      print('Upload error: $e'); // Debug log
      throw _handleError(e);
    }
  }

  // Handle Response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized. Please login again.', 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Access denied.', 403);
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found.', 404);
    } else if (response.statusCode == 422) {
      throw ApiException(body['message'] ?? 'Validation error.', 422);
    } else {
      throw ApiException(
        body['message'] ?? 'Something went wrong.',
        response.statusCode,
      );
    }
  }

  // Handle Error
  static ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error is SocketException) {
      return ApiException('No internet connection.', 0);
    } else {
      return ApiException('Something went wrong. Please try again.', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
