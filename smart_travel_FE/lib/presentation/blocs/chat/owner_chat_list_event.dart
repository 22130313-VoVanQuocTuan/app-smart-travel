import 'package:equatable/equatable.dart';

abstract class OwnerChatListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadOwnerChatsEvent extends OwnerChatListEvent {
  final int ownerId;
  LoadOwnerChatsEvent(this.ownerId);
}