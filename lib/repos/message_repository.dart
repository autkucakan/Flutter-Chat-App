// message_repository.dart
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_chat_app/services/api_service.dart';
import 'package:flutter_chat_app/helper/database_helper.dart';

class MessageRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;
  IOWebSocketChannel? _channel;

  MessageRepository({required this.apiService, required this.dbHelper});

  Future<List<Map<String, dynamic>>> getMessages(
    int chatId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final local = await dbHelper.getMessagesForChat(chatId);
      if (local.isNotEmpty) return local;
    }
    return _fetchAndCacheMessages(chatId);
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheMessages(int chatId) async {
    try {
      final remote = await apiService.fetchMessages(chatId);
      for (final m in remote) {
        // adapt these keys to match your actual JSON:
        final content = m['content'] ?? m['text'] ?? '';
        final senderId =
            m['sender_id'] ?? m['senderId'] ?? apiService.currentUserId;
        final timestamp =
            m['timestamp'] ??
            m['created_at'] ??
            DateTime.now().toIso8601String();

        final toInsert = <String, dynamic>{
          'chatId': chatId,
          'senderId': senderId,
          'content': content,
          'timestamp': timestamp,
        };

        if (m['id'] != null) {
          toInsert['id'] = m['id'];
        }

        await dbHelper.insertMessage(toInsert);
      }
      return await dbHelper.getMessagesForChat(chatId);
    } catch (e) {
      final cached = await dbHelper.getMessagesForChat(chatId);
      if (cached.isNotEmpty) return cached;
      throw Exception('MessageRepository.getMessages failed: $e');
    }
  }

  void connect(int chatId) {
    _channel = apiService.connectToChat(chatId);
    _channel!.stream.listen((data) async {
      final msg = json.decode(data as String) as Map<String, dynamic>;

      // same sanitization as above:
      final content = msg['content'] ?? msg['text'] ?? '';
      final senderId =
          msg['sender_id'] ?? msg['senderId'] ?? apiService.currentUserId;
      final timestamp =
          msg['timestamp'] ??
          msg['created_at'] ??
          DateTime.now().toIso8601String();

      final toInsert = <String, dynamic>{
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp,
      };

      if (msg['id'] != null) {
        toInsert['id'] = msg['id'];
      }

      await dbHelper.insertMessage(toInsert);
    });
  }

  Stream<Map<String, dynamic>> get messageStream => _channel!.stream.map(
    (d) => json.decode(d as String) as Map<String, dynamic>,
  );

  Future<void> sendMessage(String content) async {
    if (_channel == null) {
      throw Exception('Not connected to any chat WebSocket.');
    }
    _channel!.sink.add(json.encode({'content': content}));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
