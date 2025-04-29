// lib/bloc/chat_list/chat_list_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';
import 'package:flutter_chat_app/repos/chat_repository.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository repository;

  ChatListBloc({required this.repository}) : super(ChatListLoading()) {
    on<WorkspaceChatList>(_onLoadList);
    // on<UpdateChatPreview>(_onUpdatePreview);
  }

  Future<void> _onLoadList(
      WorkspaceChatList event,
      Emitter<ChatListState> emit,
  ) async {
    emit(ChatListLoading());
    try {
      final chats = await repository.getChats();
      emit(ChatListLoaded(chats));
    } catch (e) {
      emit(ChatListFailure(e.toString()));
    }
  }

  // Future<void> _onUpdatePreview(
  //   UpdateChatPreview event,
  //   Emitter<ChatListState> emit,
  // ) async {
  //   // optional: update a single chat preview in the existing list
  // }
}
