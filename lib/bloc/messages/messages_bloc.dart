import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/repos/message_repository.dart';
import 'messages_event.dart';
import 'messages_state.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _repo;
  final int chatId;
  StreamSubscription<Map<String, dynamic>>? _sub;

  MessagesBloc({required MessageRepository repo, required this.chatId})
      : _repo = repo,
        super(MessagesLoading()) {
    // UI-initiated actions
    on<WorkspaceMessages>(_onLoad);
    on<SendMessage>(_onSend);

    // Real-time WS → state
    on<IncomingMessageReceived>(_onIncoming);

    // listen once; repo stream is broadcast
    _sub = _repo.messageStream.listen((msg) {
      if (msg['chatId'] == chatId) add(IncomingMessageReceived(msg));
    });

    // initial history
    add(WorkspaceMessages(chatId: chatId));
  }

  // ------------ handlers ------------
  Future<void> _onLoad(
      WorkspaceMessages e, Emitter<MessagesState> emit) async {
    emit(MessagesLoading());
    try {
      final msgs = await _repo.getMessages(e.chatId);
      emit(MessagesLoaded(msgs));
    } catch (err) {
      emit(MessagesFailure(err.toString()));
    }
  }

  Future<void> _onSend(
      SendMessage e, Emitter<MessagesState> emit) async {
    final current = state is MessagesLoaded
        ? (state as MessagesLoaded).messages
        : <Map<String, dynamic>>[];
    emit(MessagesSending(current));
    try {
      await _repo.sendMessage(e.content);
      // on success we optimistically add; incoming WS will also hit
    } catch (err) {
      emit(MessagesFailure(err.toString()));
    }
  }

  void _onIncoming(
      IncomingMessageReceived e, Emitter<MessagesState> emit) {
    final current = state is MessagesLoaded
        ? (state as MessagesLoaded).messages
        : <Map<String, dynamic>>[];
    final updated = List<Map<String, dynamic>>.from(current)..add(e.message);
    emit(MessagesLoaded(updated));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
