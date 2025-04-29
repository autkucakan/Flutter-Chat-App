// lib/views/chat_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_event.dart';
import 'package:flutter_chat_app/bloc/messages/messages_state.dart';
import 'package:flutter_chat_app/repos/message_repository.dart';
import 'package:flutter_chat_app/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ApiService _api;
  late final MessagesBloc _bloc;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();

    _bootstrapCurrentUser(); // ⇒ sets _currentUserId

    final repo = context.read<MessageRepository>();
    repo.connect(widget.chatId);                 // live WS for this chat
    _bloc = MessagesBloc(repo: repo, chatId: widget.chatId);
  }

  Future<void> _bootstrapCurrentUser() async {
    try {
      final user = await _api.fetchCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user['id'] as int?);
      }
    } catch (e) {
      debugPrint('Couldn’t fetch current user: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _bloc.close();
    context.read<MessageRepository>().disconnect();
    super.dispose();
  }

  /* ---------- helpers ---------- */

  int? _senderIdFromMessage(Map<String, dynamic> m) {
    final raw = m['sender_id'] ??
        m['senderId'] ??
        (m['sender'] is Map ? m['sender']['id'] : m['sender']);
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse(raw.toString());
  }

  String _extractText(dynamic raw) {
    if (raw is! String) return raw.toString();
    if (raw.trimLeft().startsWith('{')) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          return (decoded['text'] ?? decoded['content'] ?? raw).toString();
        }
      } catch (_) {}
    }
    return raw;
  }

  /* ---------- UI ---------- */

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      // Don’t build the list until we know who “me” is.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final meId = _currentUserId!;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Column(
          children: [
            /* -------- MESSAGE LIST -------- */
            Expanded(
              child: BlocConsumer<MessagesBloc, MessagesState>(
                listener: (_, __) => _jumpToBottom(),
                builder: (_, state) {
                  if (state is MessagesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MessagesFailure) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error: ${state.error}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _bloc.add(
                              WorkspaceMessages(chatId: widget.chatId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final msgs = (state is MessagesLoaded)
                      ? state.messages
                      : (state as MessagesSending).currentMessages;

                  return ListView.builder(
                    controller: _scroll,
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final senderId = _senderIdFromMessage(m);
                      final isMe = senderId != null && senderId == meId;

                      final text = _extractText(
                        m['content'] ?? m['text'] ?? '',
                      );

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blueAccent.withOpacity(0.75)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(text),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /* -------- INPUT -------- */
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration:
                            const InputDecoration(hintText: 'Type a message'),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    BlocBuilder<MessagesBloc, MessagesState>(
                      builder: (_, state) => (state is MessagesSending)
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _send,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _bloc.add(SendMessage(chatId: widget.chatId, content: text));
    _controller.clear();
  }
}
