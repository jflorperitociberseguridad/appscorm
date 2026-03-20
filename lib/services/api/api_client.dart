import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'api_exceptions.dart';

typedef TokenResolver = String? Function();

typedef JsonMap = Map<String, dynamic>;

class ApiClient {
  final TokenResolver _tokenResolver;
  final http.Client _httpClient;

  ApiClient({
    required TokenResolver tokenResolver,
    http.Client? httpClient,
  })  : _tokenResolver = tokenResolver,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (extra != null) ...extra,
    };

    final token = _tokenResolver();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final uri = ApiConfig.endpoint(path, query);
    final response = await _httpClient.get(uri, headers: _buildHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, Map<String, dynamic>? query}) async {
    final response = await _httpClient.post(
      ApiConfig.endpoint(path, query),
      headers: _buildHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body, Map<String, dynamic>? query}) async {
    final response = await _httpClient.put(
      ApiConfig.endpoint(path, query),
      headers: _buildHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    final response = await _httpClient.delete(
      ApiConfig.endpoint(path, query),
      headers: _buildHeaders(),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('ApiClient: non-json response for ${response.request?.url}');
        }
        return response.body;
      }
    }

    throw ApiException(
      'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
      details: response.body,
    );
  }
}
