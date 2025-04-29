import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_bloc.dart';
import 'package:flutter_chat_app/bloc/messages/messages_event.dart';
import 'package:flutter_chat_app/bloc/messages/messages_state.dart';
import '../repos/message_repository.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    final repo = context.read<MessageRepository>();

    // Establish WS connection (once per chat)
    repo.connect(widget.chatId);

    // Bloc – now handles live WS events internally
    _bloc = MessagesBloc(repo: repo, chatId: widget.chatId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meId = _api.currentUserId;           // ← whatever type you use (int / String)

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Column(
          children: [
            // —————————— MESSAGE LIST ——————————
            Expanded(
              child: BlocConsumer<MessagesBloc, MessagesState>(
                listener: (_, state) {
                  if (state is MessagesLoaded) {
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
                },
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
                      final m = msgs[i] as Map<String, dynamic>;

                      // robust sender check (covers int / String mix)
                      final sender =
                          m['senderId'] ?? m['sender_id'] ?? m['sender'];
                      final isMe =
                          sender != null &&
                          sender.toString() == meId.toString();

                      // decode ‘content’ safely (may arrive JSON-encoded)
                      final raw = m['content'] ?? m['text'] ?? '';
                      String display;
                      if (raw is String && raw.trim().startsWith('{')) {
                        try {
                          final decoded = json.decode(raw);
                          display = decoded is Map<String, dynamic>
                              ? (decoded['text'] ??
                                      decoded['content'] ??
                                      raw)
                                  .toString()
                              : raw;
                        } catch (_) {
                          display = raw;
                        }
                      } else {
                        display = raw.toString();
                      }

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
                          child: Text(display),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // —————————— INPUT ——————————
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                        ),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _bloc.add(SendMessage(chatId: widget.chatId, content: text));
    _controller.clear();
  }
}
