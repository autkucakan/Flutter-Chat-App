// lib/chats.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Basit mesaj modeli: text ve kimin gönderdiği bilgisi
class Message {
  final String text;
  final bool isMe;
  Message({required this.text, required this.isMe});
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  IOWebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  // WebSocket bağlantısını kur
  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = 'ws://172.16.12.215:8000/api/ws/chat/1?token=$token';
    _channel = IOWebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        setState(() {
          _messages.add(Message(text: decoded['text'] as String, isMe: false));
        });
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;

    // Mesajı WebSocket üzerinden gönder
    final payload = jsonEncode({'text': text});
    _channel!.sink.add(payload);

    setState(() {
      _messages.add(Message(text: text, isMe: true));
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // Mesajların listelendiği alan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          msg.isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMe ? 16 : 0),
                        bottomRight: Radius.circular(msg.isMe ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Mesaj yazma ve gönderme alanı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
