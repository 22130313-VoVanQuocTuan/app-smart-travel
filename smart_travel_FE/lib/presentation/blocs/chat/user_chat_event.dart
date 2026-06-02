  import 'package:equatable/equatable.dart';

  abstract class UserChatEvent extends Equatable {
    @override
    List<Object?> get props => [];
  }

  class LoadChatEvent extends UserChatEvent {
    final int myId;       // ID của mình
    final int targetId;   // ID của đối phương
    final String myName;
    final String targetName;

    LoadChatEvent({required this.myId, required this.targetId, required this.myName, required this.targetName});

    @override
    List<Object?> get props => [myId, targetId, myName, targetName];
  }

  class SendUserMessageEvent extends UserChatEvent {
    final String text;
    SendUserMessageEvent(this.text);

    @override
    List<Object?> get props => [text];
  }

  class UpdateMessagesEvent extends UserChatEvent {
    final List<dynamic> messages;
    UpdateMessagesEvent(this.messages);

    @override
    List<Object?> get props => [messages];
  }