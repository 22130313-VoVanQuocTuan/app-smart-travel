import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel/presentation/blocs/chat/owner_chat_list_bloc.dart';
import 'package:smart_travel/presentation/blocs/chat/owner_chat_list_event.dart';
import 'package:smart_travel/presentation/blocs/chat/user_chat_bloc.dart';
import 'package:smart_travel/presentation/blocs/chat/user_chat_event.dart';
import '../../../injection_container.dart' as di;
import 'user_chat_screen.dart';

// Bảng màu chuẩn 2026 đồng bộ với UserChatScreen
class _AppColors {
  static const emeraldLight = Color(0xFF34D399);
  static const emeraldDark = Color(0xFF059669);
  static const emeraldDeep = Color(0xFF10B981);

  static const bgTop = Color(0xFFF8FAFC);
  static const bgBottom = Color(0xFFF0FDF4);

  static const white = Colors.white;
  static const grey50 = Color(0xFFF9FAFB);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey800 = Color(0xFF1F2937);
  static const grey900 = Color(0xFF111827);

  static const avatarStart = Color(0xFFE2E8F0);
  static const avatarEnd = Color(0xFFCBD5E1);
}

class OwnerChatListScreen extends StatelessWidget {
  final int ownerId;
  final String ownerName;

  const OwnerChatListScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OwnerChatListBloc()..add(LoadOwnerChatsEvent(ownerId)),
      child: Scaffold(
        backgroundColor: _AppColors.bgTop,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _AppColors.white,
          foregroundColor: _AppColors.grey900,
          centerTitle: false,
          title: const Text(
            "Tin nhắn từ khách",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _AppColors.grey200, height: 1),
          ),
        ),
        body: BlocBuilder<OwnerChatListBloc, List<DocumentSnapshot>>(
          builder: (context, chatRooms) {
            // ---------------- EMPTY STATE GIAO DIỆN MỚI ----------------
            if (chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _AppColors.emeraldDeep.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mark_chat_unread_rounded,
                        size: 56,
                        color: _AppColors.emeraldDeep.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Hộp thư trống",
                      style: TextStyle(
                        color: _AppColors.grey900,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Hiện chưa có khách hàng nào liên hệ.",
                      style: TextStyle(
                        color: _AppColors.grey500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ---------------- LIST TIN NHẮN GIAO DIỆN MỚI ----------------
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: chatRooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12), // Tạo khoảng cách giữa các Card
              itemBuilder: (context, index) {
                var data = chatRooms[index].data() as Map<String, dynamic>;
                List participants = data['participants'] ?? [];
                Map<String, dynamic> names = data['participantNames'] ?? {};

                // LOGIC CŨ: Lấy ID và Tên khách
                int customerId = participants.firstWhere(
                      (id) => id != ownerId,
                  orElse: () => 0,
                );

                // Nếu lỗi database lòi ra ông khách số 0 thì ẩn đi (logic bảo vệ cũ)
                if (customerId == 0) return const SizedBox.shrink();

                String customerName = names[customerId.toString()] ?? "Khách hàng $customerId";
                String initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : 'K';
                String lastMessage = data['lastMessage'] ?? "Chưa có tin nhắn...";

                return Container(
                  decoration: BoxDecoration(
                    color: _AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.grey400.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // LOGIC ĐIỀU HƯỚNG CŨ K CẦN SỬA
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider<UserChatBloc>(
                              create: (_) => di.sl<UserChatBloc>()..add(
                                LoadChatEvent(
                                    myId: ownerId,
                                    targetId: customerId,
                                    myName: ownerName,
                                    targetName: customerName
                                ),
                              ),
                              child: UserChatScreen(
                                ownerId: customerId,
                                ownerName: customerName,
                                receiverRole: 'Khách hàng',
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 1. Custom Avatar Gradient
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_AppColors.emeraldLight, _AppColors.emeraldDeep],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _AppColors.emeraldDeep.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: _AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 2. Tên và Tin nhắn
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _AppColors.grey900,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lastMessage,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: _AppColors.grey500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 3. Icon Mũi tên đi tới
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _AppColors.grey50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: _AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}