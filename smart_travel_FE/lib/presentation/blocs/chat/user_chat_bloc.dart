  import 'dart:async';

import 'package:bloc/bloc.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'user_chat_event.dart';
  import 'user_chat_state.dart';

  class UserChatBloc extends Bloc<UserChatEvent, UserChatState> {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final SharedPreferences sharedPreferences;
    StreamSubscription? _chatSubscription;

    String? currentChatRoomId;
    int? myId;
    int? targetId;
    String? myName;     // Thêm biến lưu tên mình
    String? targetName; // Thêm biến lưu tên đối phương

    UserChatBloc({required this.sharedPreferences}) : super(ChatLoading()) {
      on<LoadChatEvent>(_onLoadChat);
      on<UpdateMessagesEvent>((event, emit) => emit(ChatLoaded(event.messages)));
      on<SendUserMessageEvent>(_onSendMessage);
    }

    void _onLoadChat(LoadChatEvent event, Emitter<UserChatState> emit) {
      // Lấy ID trực tiếp từ Event, KHÔNG dùng SharedPreferences nữa
      myId = event.myId;
      targetId = event.targetId;
      myName = event.myName;
      targetName = event.targetName;

      currentChatRoomId = _getChatRoomId(myId!, targetId!);
      print("DEBUG: Chat room ID: $currentChatRoomId");

      _chatSubscription?.cancel();

      _chatSubscription = _firestore
          .collection('chats')
          .doc(currentChatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (!isClosed) {
          add(UpdateMessagesEvent(snapshot.docs));
        }
      });
    }

    Future<void> _onSendMessage(SendUserMessageEvent event, Emitter<UserChatState> emit) async {
      if (currentChatRoomId == null || event.text.trim().isEmpty || myId == null || targetId == null) return;

      // 1. Cập nhật thông tin phòng chat (để chủ nhà query được)
      await _firestore.collection('chats').doc(currentChatRoomId).set({
        'participants': [myId, targetId], // Lưu ID của cả 2 để query
        'participantNames': {
          myId.toString(): myName,
          targetId.toString(): targetName,
        },
        'lastMessage': event.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Thêm tin nhắn
      await _firestore.collection('chats')
          .doc(currentChatRoomId)
          .collection('messages')
          .add({
        'senderId': myId,
        'text': event.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    String _getChatRoomId(int id1, int id2) {
      return (id1 < id2) ? 'chat_${id1}_$id2' : 'chat_${id2}_$id1';
    }
    @override
    Future<void> close() {
      _chatSubscription?.cancel();
      return super.close();
    }
  }