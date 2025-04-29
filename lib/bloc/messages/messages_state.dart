abstract class MessagesState {}

/// Initial loading of history
class MessagesLoading extends MessagesState {}

/// History loaded (and after every send, reloaded)
class MessagesLoaded extends MessagesState {
  final List<Map<String, dynamic>> messages;

  MessagesLoaded(this.messages);
}

/// Error fetching or sending
class MessagesFailure extends MessagesState {
  final String error;
  MessagesFailure(this.error);
}

/// When a send is in flight
class MessagesSending extends MessagesState {
  final List<Map<String, dynamic>> currentMessages;
  MessagesSending(this.currentMessages);
}
