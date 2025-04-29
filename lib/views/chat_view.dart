// lib/views/chat_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_event.dart';
import 'package:flutter_chat_app/bloc/messages/messages_state.dart';
import 'package:flutter_chat_app/repos/message_repository.dart';
import 'package:flutter_chat_app/services/api_service.dart';

/// Chat screen that shows history + live messages for a single chat.
/// ─ My messages  : right-hand side, primary-colour bubble
/// ─ Their messages: left-hand side, surfaceVariant bubble
class ChatScreen extends StatefulWidget {
  final int chatId;
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ApiService _api;
  late final MessagesBloc _bloc;

  final _input  = TextEditingController();
  final _scroll = ScrollController();

  int? _meId; // cached from JWT or /users/me

  @override
  void initState() {
    super.initState();

    _api  = context.read<ApiService>();
    _meId = _api.currentUserId;

    // If JWT had no user_id, resolve once through /users/me
    if (_meId == null) _bootstrapCurrentUser();

    // Attach WebSocket for live updates
    final repo = context.read<MessageRepository>();
    repo.connect(widget.chatId);

    _bloc = MessagesBloc(repo: repo, chatId: widget.chatId)
      ..add(WorkspaceMessages(chatId: widget.chatId));
  }

  Future<void> _bootstrapCurrentUser() async {
    try {
      final me = await _api.fetchCurrentUser();
      if (mounted) setState(() => _meId = me['id'] as int?);
    } catch (e) {
      debugPrint('⚠️  Could not resolve /users/me → $e');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _bloc.close();
    context.read<MessageRepository>().disconnect();
    super.dispose();
  }

  /* ───────────── helper: extract sender id robustly ───────────── */

  int? _senderId(Map<String, dynamic> m) {
    final raw = m['senderId'] ??
        m['sender_id'] ??
        m['sender'] ??
        m['userId']   ||  // ← NEW
        m['user_id']  ||  // ← NEW
        m['user'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    if (raw is Map<String, dynamic>) return raw['id'] as int?;
    return null;
  }

  String _content(Map<String, dynamic> m) {
    final raw = m['content'] ?? m['text'] ?? '';
    if (raw is! String) return raw.toString();

    final trimmed = raw.trimLeft();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return (decoded['text'] ?? decoded['content'] ?? raw).toString();
        }
      } catch (_) {/* ignore */}
    }
    return raw;
  }

  /* ─────────────────────────── UI ─────────────────────────── */

  @override
  Widget build(BuildContext context) {
    if (_meId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Column(
          children: [
            /// -------------- message list --------------
            Expanded(
              child: BlocConsumer<MessagesBloc, MessagesState>(
                listener: (_, __) => _jumpToBottom(),
                builder : (_, state) {
                  if (state is MessagesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MessagesFailure) return _onFailure(state);

                  final msgs = switch (state) {
                    MessagesLoaded  s => s.messages,
                    MessagesSending s => s.currentMessages,
                    _                 => <Map<String, dynamic>>[],
                  };

                  return ListView.builder(
                    controller: _scroll,
                    padding   : const EdgeInsets.symmetric(vertical: 8),
                    itemCount : msgs.length,
                    itemBuilder: (_, i) {
                      final m    = msgs[i];
                      final isMe = _senderId(m) == _meId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight   // my bubble → right
                            : Alignment.centerLeft,   // their bubble → left
                        child: _MessageBubble(
                          text : _content(m),
                          isMe : isMe,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// -------------- input row ----------------
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller : _input,
                        decoration : const InputDecoration(
                          hintText: 'Type a message…',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    BlocBuilder<MessagesBloc, MessagesState>(
                      buildWhen: (p, n) =>
                          n is MessagesSending || p is MessagesSending,
                      builder: (_, s) => s is MessagesSending
                          ? const SizedBox(
                              width : 24, height: 24,
                              child  : CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon     : const Icon(Icons.send),
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

  Widget _onFailure(MessagesFailure f) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: ${f.error}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  _bloc.add(WorkspaceMessages(chatId: widget.chatId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  /* ───────── internal helpers ───────── */

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve   : Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    _bloc.add(SendMessage(chatId: widget.chatId, content: text));
    _input.clear();
  }
}

/* ────────── message bubble widget ────────── */

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool   isMe;
  const _MessageBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? theme.colorScheme.primary.withOpacity(0.85)
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft     : const Radius.circular(18),
          topRight    : const Radius.circular(18),
          bottomLeft  : Radius.circular(isMe ? 18 : 4),
          bottomRight : Radius.circular(isMe ? 4  : 18),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isMe ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
