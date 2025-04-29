// lib/bloc/chat_list/chat_list_state.dart

import 'package:equatable/equatable.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

/// Waiting for data
class ChatListLoading extends ChatListState {}

/// Data loaded successfully
class ChatListLoaded extends ChatListState {
  final List<Map<String, dynamic>> chats;
  const ChatListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

/// An error occurred
class ChatListFailure extends ChatListState {
  final String error;
  const ChatListFailure(this.error);

  @override
  List<Object?> get props => [error];
}
