import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'api_exceptions.dart';

class AuthService {
  final http.Client _client;

  AuthService([http.Client? client]) : _client = client ?? http.Client();

  Future<AuthToken> login({required String email, required String password}) async {
    final response = await _client.post(
      ApiConfig.endpoint('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid auth response structure');
      }
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException('Authentication succeeded but bearer token is missing');
      }
      return AuthToken(
        token: token,
        expiresAt: _parseDate(data['expires_at']),
      );
    }

    throw ApiException(
      'Authentication failed: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  DateTime? _parseDate(dynamic input) {
    if (input is String) {
      return DateTime.tryParse(input);
    }
    return null;
  }
}

class AuthToken {
  final String token;
  final DateTime? expiresAt;

  AuthToken({required this.token, this.expiresAt});
}
