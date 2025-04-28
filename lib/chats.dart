// lib/chats.dart
import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  // Eğer ileride kiminle sohbet edeceğini bilmek istersen, burada User objesini de alabilirsin.
  const ChatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: const Center(
        child: Text(
          'utkunun götü',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
