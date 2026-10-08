import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/central_pool/providers/central_pool_providers.dart';
import '../security/session_storage.dart';

/// Structured RFC 7807 problem details exception.
class ApiException implements Exception {
  final int statusCode;
  final String title;
  final String detail;
  final String? correlationId;
  final String? errorCode;

  const ApiException({
    required this.statusCode,
    required this.title,
    required this.detail,
    this.correlationId,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException [$statusCode - $title]: $detail (Ref: $correlationId)';
}

/// Production API Client for Collaborative Finance Platform Backend Services.
class ApiClient {
  final String baseUrl;
  final SessionStorage sessionStorage;
  final http.Client _httpClient;
  final bool isRelease;

  ApiClient({
    String? baseUrl,
    required this.sessionStorage,
    http.Client? httpClient,
    this.isRelease = kReleaseMode,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = _validateAndResolveBaseUrl(baseUrl, isRelease: isRelease);

  static String _validateAndResolveBaseUrl(String? inputUrl, {required bool isRelease}) {
    if (isRelease) {
      final target = inputUrl ?? kCanonicalProductionBaseUrl;
      final uri = Uri.tryParse(target);
      final host = uri?.host.toLowerCase() ?? '';

      // In Release mode: STRICT FAIL-CLOSED on localhost, 127.0.0.1, :8080, emulator, dev, staging
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host.startsWith('127.') ||
          host == '10.0.2.2' ||
          uri?.port == 8080 ||
          target.contains('localhost') ||
          target.contains('127.0.0.1') ||
          target.contains(':8080') ||
          target.contains('-dev') ||
          target.contains('-staging') ||
          target.contains('emulator')) {
        throw StateError(
          'RELEASE SECURITY INVARIANT VIOLATION: ApiClient cannot target loopback, development, staging, or emulator endpoints in Release mode: $target',
        );
      }
      return target;
    }
    return inputUrl ?? 'http://localhost:8080';
  }

  /// Sends a GET request.
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    return _sendRequest('GET', path, queryParams: queryParams);
  }

  /// Sends a POST request.
  Future<dynamic> post(String path, {dynamic body, Map<String, String>? queryParams}) async {
    return _sendRequest('POST', path, body: body, queryParams: queryParams);
  }

  /// Sends a PUT request.
  Future<dynamic> put(String path, {dynamic body, Map<String, String>? queryParams}) async {
    return _sendRequest('PUT', path, body: body, queryParams: queryParams);
  }

  /// Sends a DELETE request.
  Future<dynamic> delete(String path, {Map<String, String>? queryParams}) async {
    return _sendRequest('DELETE', path, queryParams: queryParams);
  }

  Future<dynamic> _sendRequest(
    String method,
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    final correlationId = 'req-${DateTime.now().millisecondsSinceEpoch}';
    final token = await sessionStorage.getAccessToken();
    final tenantId = await sessionStorage.getTenantId() ?? 'TENANT-ALPHA';

    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    if (isRelease) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          uri.port == 8080 ||
          uri.toString().contains(':8080') ||
          uri.path.startsWith('/api/v1/auth/')) {
        throw StateError(
          'RELEASE SECURITY INVARIANT VIOLATION: Blocked forbidden release request to $uri',
        );
      }
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Correlation-ID': correlationId,
      'X-Tenant-ID': tenantId,
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 15));
          break;
        case 'GET':
        default:
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      } else {
        throw _parseErrorResponse(response.statusCode, response.body, correlationId);
      }
    } on TimeoutException {
      throw ApiException(
        statusCode: 504,
        title: 'Gateway Timeout',
        detail: 'The request timed out while waiting for the server to respond.',
        correlationId: correlationId,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 503,
        title: 'Network / Transport Error',
        detail: e.toString(),
        correlationId: correlationId,
      );
    }
  }

  ApiException _parseErrorResponse(int statusCode, String body, String correlationId) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return ApiException(
        statusCode: statusCode,
        title: json['title'] as String? ?? _defaultTitleForStatus(statusCode),
        detail: json['detail'] as String? ?? json['message'] as String? ?? 'An unexpected error occurred.',
        correlationId: json['correlation_id'] as String? ?? correlationId,
        errorCode: json['code'] as String? ?? json['error'] as String?,
      );
    } catch (_) {
      return ApiException(
        statusCode: statusCode,
        title: _defaultTitleForStatus(statusCode),
        detail: body.isNotEmpty ? body : 'Server returned status $statusCode',
        correlationId: correlationId,
      );
    }
  }

  String _defaultTitleForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized Session';
      case 403:
        return 'Forbidden Action';
      case 404:
        return 'Resource Not Found';
      case 409:
        return 'Conflict / Invariant Breach';
      case 500:
        return 'Internal Financial Core Error';
      default:
        return 'Server Error';
    }
  }
}
