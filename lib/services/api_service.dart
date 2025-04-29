// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

class ApiService {
  // === Configuration ===
  static const String _baseUrl = 'http://172.16.12.215:8000/api';
  static const String _tokenKey = 'jwt_token';

  final http.Client _client;
  String? _token;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Expose the current JWT (or null if not logged in)
  String? get token => _token;

  /// Load JWT from local cache (call this on app start).
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  /// Helper to build headers with or without Authorization.
  Map<String, String> _headers({bool jsonEncode = true, bool useForm = false}) {
    final headers = <String, String>{};
    if (useForm) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    } else if (jsonEncode) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // === Authentication ===

  /// Log in with username/password form data, cache JWT locally, and return it.
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers(useForm: true),
      body: {'username': username, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null) {
        throw Exception('Login succeeded but no access_token returned.');
      }
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return token;
    } else {
      throw Exception(
        'Login failed [${response.statusCode}]: ${response.body}',
      );
    }
  }

  /// Log out by clearing the in-memory and persisted JWT.
  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Register a new user with raw JSON.
  Future<void> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers(),
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Signup failed [${response.statusCode}]: ${response.body}',
      );
    }
  }

  // === Users ===

  /// Fetch all users.
  Future<List<dynamic>> fetchUsers() async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/users/'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch users [${res.statusCode}]');
  }

  /// Fetch a single user by ID.
  Future<Map<String, dynamic>> fetchUser(int userId) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch user $userId [${res.statusCode}]');
  }

  /// Fetch the currently authenticated user's profile.
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to fetch current user [${res.statusCode}]: ${res.body}',
    );
  }

  /// Decode the stored JWT and return the `user_id` claim (or null).
  int? get currentUserId {
    if (_token == null) return null;
    final parts = _token!.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    // normalize Base64 (add padding) then decode
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(decoded) as Map<String, dynamic>;
    return map['user_id'] as int?;
  }

  // === Chats ===

  /// Fetch all chats.
  Future<List<dynamic>> fetchChats() async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/chats/'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch chats [${res.statusCode}]');
  }

  /// Create a new chat.
  Future<Map<String, dynamic>> createChat({
    required String name,
    required List<int> userIds,
  }) async {
    final res = await _client.post(
      Uri.parse('$_baseUrl/chats/'),
      headers: _headers(),
      body: json.encode({'name': name, 'user_ids': userIds}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create chat [${res.statusCode}]: ${res.body}');
  }

  /// Fetch one chat by ID.
  Future<Map<String, dynamic>> fetchChat(int chatId) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/chats/$chatId'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch chat $chatId [${res.statusCode}]');
  }

  // === Messages ===

  /// Fetch all messages in a chat.
  Future<List<dynamic>> fetchMessages(int chatId) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/chats/$chatId/messages'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw Exception(
      'Failed to fetch messages for chat $chatId [${res.statusCode}]',
    );
  }

  // === WebSocket for real-time chat ===

  /// Connect to the WebSocket for a given chat.
  /// Remember to .stream.listen(...) and .sink.add(...) on the returned channel.
  IOWebSocketChannel connectToChat(int chatId) {
    if (_token == null) {
      throw Exception('You must be logged in to open a WebSocket.');
    }
    final uri = Uri(
      scheme: 'ws',
      host: '172.16.12.215',
      port: 8000,
      path: '/api/ws/chat/$chatId',
      queryParameters: {'token': _token},
    );
    return IOWebSocketChannel.connect(uri.toString());
  }

  /// Clean up the HTTP client when done.
  void dispose() {
    _client.close();
  }
}
