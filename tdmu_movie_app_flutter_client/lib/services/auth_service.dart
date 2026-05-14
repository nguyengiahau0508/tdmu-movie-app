import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const String _tokenStorageKey = 'auth_token';
  final http.Client _client;
  final String _baseUrl = ApiConfig.baseUrl;

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _authenticate('/auth/register', {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<AuthSession> login({required String email, required String password}) {
    return _authenticate('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenStorageKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await me(token);
      return AuthSession(token: token, user: user);
    } on Exception {
      await clearSession();
      return null;
    }
  }

  Future<AuthUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(data, fallback: 'Không thể lấy thông tin user.'),
      );
    }

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
  }

  Future<AuthSession> _authenticate(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = _decodeJson(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _errorMessage(data, fallback: 'Đăng nhập/đăng ký thất bại.'),
      );
    }

    final token = data['token'] as String?;
    final userMap = data['user'] as Map<String, dynamic>?;
    if (token == null || token.isEmpty || userMap == null) {
      throw Exception('API trả về dữ liệu xác thực không hợp lệ.');
    }

    final session = AuthSession(token: token, user: AuthUser.fromJson(userMap));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);

    return session;
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  String _errorMessage(Map<String, dynamic> data, {required String fallback}) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }

    return fallback;
  }
}
