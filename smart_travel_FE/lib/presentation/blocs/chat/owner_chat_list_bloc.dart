      import 'package:bloc/bloc.dart';
      import 'package:cloud_firestore/cloud_firestore.dart';
      import 'owner_chat_list_event.dart';

      class OwnerChatListBloc extends Bloc<OwnerChatListEvent, List<DocumentSnapshot>> {
        final FirebaseFirestore _firestore = FirebaseFirestore.instance;

        OwnerChatListBloc() : super([]) {
          on<LoadOwnerChatsEvent>((event, emit) async {
            await emit.forEach(
              _firestore.collection('chats')
                  .where('participants', arrayContains: event.ownerId)
                  .orderBy('lastUpdated', descending: true)
                  .snapshots(),
              onData: (snapshot) => snapshot.docs,
            );
          });
        }
      }