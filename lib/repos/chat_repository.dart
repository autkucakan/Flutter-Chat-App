import 'package:flutter_chat_app/services/api_service.dart';
import 'package:flutter_chat_app/helper/database_helper.dart';

class ChatRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  ChatRepository({required this.apiService, required this.dbHelper});

  /// try cache, otherwise fetch+cache from API.
  Future<List<Map<String, dynamic>>> getChats({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final local = await dbHelper.getChats();
      if (local.isNotEmpty) {
        return local;
      }
    }
    return _fetchAndCacheChats();
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheChats() async {
    try {
      final remote = await apiService.fetchChats();
      // remote is List<dynamic> of Map<String, dynamic>
      // Save/replace each in local DB
      for (final c in remote) {
        await dbHelper.insertChat(c as Map<String, dynamic>);
      }
      return await dbHelper.getChats();
    } catch (e) {
      final cached = await dbHelper.getChats();
      if (cached.isNotEmpty) {
        return cached;
      }
      throw Exception('ChatRepository.getChats failed: $e');
    }
  }

  /// Create a new chat remotely and cache it locally.
  Future<Map<String, dynamic>> createChat({
    required String name,
    required List<int> userIds,
  }) async {
    try {
      final newChat = await apiService.createChat(name: name, userIds: userIds);
      await dbHelper.insertChat(newChat);
      return newChat;
    } catch (e) {
      throw Exception('ChatRepository.createChat failed: $e');
    }
  }

  /// Fetch a single chat with local fallback.
  Future<Map<String, dynamic>> getChat(int chatId) async {
    try {
      final chat = await apiService.fetchChat(chatId);
      await dbHelper.insertChat(chat);
      return chat;
    } catch (e) {
      final all = await dbHelper.getChats();
      final found = all.firstWhere((c) => c['id'] == chatId, orElse: () => {});
      if (found.isNotEmpty) return found;
      throw Exception('ChatRepository.getChat failed: $e');
    }
  }
}
