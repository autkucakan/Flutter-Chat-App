import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/bloc/chat_list/chat_list_bloc.dart';
import 'package:flutter_chat_app/bloc/chat_list/chat_list_event.dart';
import 'package:flutter_chat_app/bloc/chat_list/chat_list_state.dart';
import 'package:flutter_chat_app/repos/chat_repository.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatListBloc>(
      create: (context) => ChatListBloc(
        repository: context.read<ChatRepository>(),
      )..add(WorkspaceChatList()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: BlocListener<ChatListBloc, ChatListState>(
          listener: (context, state) {
            if (state is ChatListFailure) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          child: BlocBuilder<ChatListBloc, ChatListState>(
            builder: (context, state) {
              if (state is ChatListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ChatListLoaded) {
                final chats = state.chats;
                if (chats.isEmpty) {
                  return const Center(child: Text('No chats yet'));
                }
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final title = chat['name'] as String? ?? 'Chat ${chat['id']}';
                    final lastMsg = chat['last_message'] as String? ?? '—';
                    return ListTile(
                      title: Text(title),
                      subtitle: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, 
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: chat['id'] as int,
                        );
                      },
                    );
                  },
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }
}
