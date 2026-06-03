// models/chat_room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final int partnerId;
  final String partnerName;
  final String? lastMessage;
  final int? lastSenderId;
  final int unreadCount;
  final DateTime? updatedAt;

  ChatRoomModel({
    required this.roomId,
    required this.partnerId,
    required this.partnerName,
    this.lastMessage,
    this.lastSenderId,
    required this.unreadCount,
    this.updatedAt,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      roomId: doc.id,
      partnerId: data['partnerId'] ?? 0,
      partnerName: data['partnerName'] ?? '',
      lastMessage: data['lastMessage'],
      lastSenderId: data['lastSenderId'],
      unreadCount: data['unreadCount'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}