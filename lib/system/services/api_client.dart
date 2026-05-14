import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static String? _token;
  static String? _refreshToken;
  final http.Client _client;
  static const String _defaultAndroidUrl = 'http://10.0.2.2:8080';
  static const String _defaultIOSSimulatorUrl = 'http://localhost:8080';
  static const String _defaultDesktopUrl = 'http://localhost:8080';
  static const String _defaultWebUrl = 'http://localhost:8080';

  static String get baseUrl {
    const value = String.fromEnvironment('BACKEND_BASE_URL');
    if (value.isNotEmpty) return value;
    if (kIsWeb) return _defaultWebUrl;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _defaultAndroidUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _defaultIOSSimulatorUrl;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _defaultDesktopUrl;
      default:
        return _defaultDesktopUrl;
    }
  }

  static void setAuthToken(String? token) {
    _token = token;
  }

  static String? get authToken => _token;

  static void setRefreshToken(String? token) {
    _refreshToken = token;
  }

  static String? get refreshToken => _refreshToken;

  Future<T?> get<T>(
    String path, {
    T Function(Object? json)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _send('GET', path, fromJson: fromJson, requiresAuth: requiresAuth);
  }

  Future<T?> post<T>(
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _send(
      'POST',
      path,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }

  Future<T?> put<T>(
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _send(
      'PUT',
      path,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }

  Future<T?> patch<T>(
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _send(
      'PATCH',
      path,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }

  Future<void> delete(String path, {bool requiresAuth = true}) async {
    await _send<void>('DELETE', path, requiresAuth: requiresAuth);
  }

  Future<T?> _send<T>(
    String method,
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth && _token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };

    late final http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    final payload = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw UnauthorizedException(_errorMessage(payload, 'Invalid token'));
      }
      throw ApiException(
        _errorMessage(
          payload,
          'Request failed with status ${response.statusCode}',
        ),
        statusCode: response.statusCode,
      );
    }

    final unwrappedPayload = _unwrapPayload(payload);
    if (fromJson == null) {
      return unwrappedPayload as T?;
    }
    return fromJson(unwrappedPayload);
  }

  Object? _unwrapPayload(Object? payload) {
    if (payload is Map<String, dynamic> && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload;
  }

  String _errorMessage(Object? payload, String fallback) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'] ?? payload['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}

class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
