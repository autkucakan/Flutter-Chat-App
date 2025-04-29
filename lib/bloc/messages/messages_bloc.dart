import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/repos/message_repository.dart';
import 'messages_event.dart';
import 'messages_state.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _repo;
  final int chatId;

  MessagesBloc({
    required MessageRepository repo,
    required this.chatId,
  })  : _repo = repo,
        super(MessagesLoading()) {
    on<WorkspaceMessages>(_onLoad);
    on<SendMessage>(_onSend);

    // kick off initial load
    add(WorkspaceMessages(chatId: chatId));
  }

  Future<void> _onLoad(
      WorkspaceMessages event, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      final msgs = await _repo.getMessages(
        event.chatId,
        forceRefresh: false,
      );
      emit(MessagesLoaded(msgs));
    } catch (e) {
      emit(MessagesFailure(e.toString()));
    }
  }

  Future<void> _onSend(
      SendMessage event, Emitter<MessagesState> emit) async {
    final current = state is MessagesLoaded
        ? (state as MessagesLoaded).messages
        : <Map<String, dynamic>>[];
    emit(MessagesSending(current));
    try {
      await _repo.sendMessage(event.content);
      // after send, re-fetch full history
      final updated = await _repo.getMessages(event.chatId, forceRefresh: true);
      emit(MessagesLoaded(updated));
    } catch (e) {
      emit(MessagesFailure(e.toString()));
    }
  }
}