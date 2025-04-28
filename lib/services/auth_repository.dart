import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final _baseUrl = 'http://10.0.2.2:8000';
  static const _tokenKey = 'jwt_token';

  /// Returns the raw bearer token
  Future<String> logIn({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null) {
        throw Exception('Login succeeded but no access_token in response.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return token;
    } else {
      throw Exception('Failed to login: ${res.body}');
    }
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}