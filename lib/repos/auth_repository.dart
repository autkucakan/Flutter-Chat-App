import 'package:flutter_chat_app/services/api_service.dart';
import 'package:flutter_chat_app/helper/database_helper.dart';

class AuthRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  AuthRepository({
    required this.apiService,
    required this.dbHelper,
  });

  /// Log in via API, cache JWT (in ApiService) and return it.
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final token = await apiService.login(
        username: username,
        password: password,
      );
      print('[ApiService] logged in, token=$token');
      return token;
    } catch (e) {
      throw Exception('AuthRepository.login failed: $e');
    }
  }

  /// Clear JWT in-memory and persisted.
  Future<void> logout() async {
    try {
      await apiService.logout();
      // Optionally clear local user table if you store profile info
      // await dbHelper.deleteAllUsers();
    } catch (e) {
      throw Exception('AuthRepository.logout failed: $e');
    }
  }
}