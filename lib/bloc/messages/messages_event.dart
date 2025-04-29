abstract class MessagesEvent {}

/// Fetch message history (with optional pagination)
class WorkspaceMessages extends MessagesEvent {
  final int chatId;
  final int? skip;
  final int? limit;

  WorkspaceMessages({
    required this.chatId,
    this.skip,
    this.limit,
  });
}

/// Send a new message
class SendMessage extends MessagesEvent {
  final int chatId;
  final String content;

  SendMessage({
    required this.chatId,
    required this.content,
  });
}

/// Fired by the repository when a WS message arrives
class IncomingMessageReceived extends MessagesEvent {
  final Map<String, dynamic> message;
  IncomingMessageReceived(this.message);
}
