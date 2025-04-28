import 'dart:convert';
import 'package:flutter_chat_app/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final _baseUrl = 'http://10.0.2.2:8000';
  static const _tokenKey = 'jwt_token';

  Future<User> logIn({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final user = User.fromJson(data);

      // cache jwt
      if (user.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, user.token!);
      }

      return user;
    } else {
      throw Exception('Failed to login: ${res.body}');
    }
  }

  // reads cached jwt
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // removes cached jwt
  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}