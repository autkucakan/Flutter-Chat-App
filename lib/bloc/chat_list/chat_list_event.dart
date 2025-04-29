// lib/bloc/chat_list/chat_list_event.dart

import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the user lands on the chat list screen.
class WorkspaceChatList extends ChatListEvent {}

/// Optional: update the preview (e.g. last message) of a single chat.
class UpdateChatPreview extends ChatListEvent {
  final Map<String, dynamic> chat;
  const UpdateChatPreview(this.chat);

  @override
  List<Object?> get props => [chat];
}
