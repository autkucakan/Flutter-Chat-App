import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_chat_app/services/api_service.dart';
import 'package:flutter_chat_app/helper/database_helper.dart';

class MessageRepository {
  final ApiService apiService;
  final DatabaseHelper dbHelper;

  IOWebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  int? _connectedChatId;

  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _incoming.stream;

  MessageRepository({required this.apiService, required this.dbHelper});

  /* ──────────────────── history ──────────────────── */

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
        await dbHelper.insertMessage(_sanitize(m, chatId));
      }
      return await dbHelper.getMessagesForChat(chatId);
    } catch (e) {
      final cached = await dbHelper.getMessagesForChat(chatId);
      if (cached.isNotEmpty) return cached;
      throw Exception('MessageRepository.getMessages failed: $e');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> m, int chatId) {
    dynamic rawSender =
        m['sender_id'] ??
        m['senderId'] ??
        m['sender'] ??
        m['user_id'] ??
        m['userId'] ??
        m['user'];

    int? senderId;
    if (rawSender is int) {
      senderId = rawSender;
    } else if (rawSender is String) {
      senderId = int.tryParse(rawSender);
    } else if (rawSender is Map<String, dynamic>) {
      senderId = rawSender['id'] as int?;
    }

    return <String, dynamic>{
      if (m['id'] != null) 'id': m['id'],
      'chatId': chatId,
      'senderId': senderId,
      'content': m['content'] ?? m['text'] ?? '',
      'timestamp':
          m['timestamp'] ?? m['created_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  /* ──────────────────── WebSocket ─────────────────── */

  void connect(int chatId) {
    if (_connectedChatId == chatId && _channel != null) return;

    _wsSub?.cancel();
    _channel?.sink.close();

    _connectedChatId = chatId;
    _channel = apiService.connectToChat(chatId);

    _wsSub = _channel!.stream.listen((data) async {
      final msg = _sanitize(
        json.decode(data as String) as Map<String, dynamic>,
        chatId,
      );
      await dbHelper.insertMessage(msg);
      _incoming.add(msg);
    });
  }

  Future<void> sendMessage(String content) async {
    if (_channel == null) {
      throw Exception('Not connected to any chat WebSocket.');
    }
    _channel!.sink.add(json.encode({'content': content}));
  }

  Future<void> disconnect() async {
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _wsSub = null;
    _channel = null;
    _connectedChatId = null;
  }
}
