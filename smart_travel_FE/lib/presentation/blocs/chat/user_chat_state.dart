import 'package:equatable/equatable.dart';

abstract class UserChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatLoading extends UserChatState {}

class ChatLoaded extends UserChatState {
  final List<dynamic> messages;
  ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends UserChatState {
  final String message;
  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}