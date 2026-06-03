import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_travel/presentation/blocs/chat/user_chat_bloc.dart';
import 'package:smart_travel/presentation/blocs/chat/user_chat_event.dart';
import 'package:smart_travel/presentation/blocs/chat/user_chat_state.dart';

// Bảng màu chuẩn 2026: Emerald chủ đạo + Phối Sky/Purple Pastel
class _AppColors {
  // Màu chính (Emerald / Xanh Ngọc)
  static const emeraldLight = Color(0xFF34D399);
  static const emeraldDark = Color(0xFF059669);
  static const emeraldDeep = Color(0xFF10B981);
  static const emeraldDeepText = Color(0xFF064E3B);

  // Màu nền phối (Backgrounds)
  static const bgTop = Color(0xFFF8FAFC); // Xám trắng
  static const bgBottom = Color(0xFFF0FDF4); // Xanh ngọc siêu siêu nhạt

  // Màu cơ bản
  static const white = Colors.white;
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF1F5F9);
  static const grey200 = Color(0xFFE5E7EB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey600 = Color(0xFF475569);
  static const grey800 = Color(0xFF1F2937);
  static const grey900 = Color(0xFF111827);

  // Màu phối thêm để không bị đơn điệu
  static const hostAvatarStart = Color(0xFFE2E8F0);
  static const hostAvatarEnd = Color(0xFFCBD5E1);
  static const skyPale = Color(0xFFEFF6FF); // Xanh dương pastel (cho nút +)
  static const skyBorder = Color(0xFFBFDBFE); // Viền xanh dương
  static const skyIcon = Color(0xFF3B82F6);
  static const purpleShadow = Color(
    0xFFC084FC,
  ); // Tím pastel (chỉ dùng đổ bóng mờ)
}

class UserChatScreen extends StatefulWidget {
  final int ownerId;
  final String ownerName;
  final String receiverRole;

  const UserChatScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.receiverRole = 'Chủ homestay',
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    context.read<UserChatBloc>().add(SendUserMessageEvent(_controller.text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_AppColors.bgTop, _AppColors.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: BlocBuilder<UserChatBloc, UserChatState>(
                  builder: (context, state) {
                    final myId = context.read<UserChatBloc>().myId;
                    if (state is ChatLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _AppColors.emeraldDeep,
                        ),
                      );
                    }
                    if (state is ChatLoaded) {
                      final messages = state.messages;
                      if (messages.isEmpty) {
                        return _buildEmptyChat();
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final doc = messages[index] as QueryDocumentSnapshot;
                          final data = doc.data() as Map<String, dynamic>;
                          print(
                            "DEBUG MESSAGE: senderId=${data['senderId']}, myId=$myId",
                          );
                          final isMe = data['senderId'] == myId;

                          final timestamp = data['timestamp'] as Timestamp?;
                          final timeString =
                              timestamp != null
                                  ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                  : '...';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment:
                                  isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  _buildHostAvatar(size: 28, fontSize: 12),
                                  // Avatar nhỏ cho list chat
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: _messageBubbleDecoration(isMe),
                                    child: Column(
                                      crossAxisAlignment:
                                          isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['text'] ?? '',
                                          style: TextStyle(
                                            color:
                                                isMe
                                                    ? _AppColors.white
                                                    : _AppColors.grey800,
                                            fontSize: 15,
                                            height: 1.35,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color:
                                                isMe
                                                    ? _AppColors.white
                                                        .withOpacity(0.8)
                                                    : _AppColors.grey400,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 40),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------- Khung Chưa Có Tin Nhắn ----------------------
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _AppColors.emeraldDeep.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: _AppColors.emeraldDeep,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hãy gửi lời chào đầu tiên!",
            style: TextStyle(
              color: _AppColors.emeraldDeepText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Chủ nhà thường trả lời trong vài phút",
            style: TextStyle(color: _AppColors.grey500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------------- Style Bong Bóng Tin Nhắn ----------------------
  BoxDecoration _messageBubbleDecoration(bool isMe) {
    if (isMe) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.emeraldLight, _AppColors.emeraldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.emeraldDeep.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _AppColors.purpleShadow.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(-2, 6),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.white, _AppColors.grey50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: _AppColors.grey200, width: 1),
        boxShadow: [
          BoxShadow(
            color: _AppColors.grey200.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }
  }

  // ---------------------- Avatar Chủ Nhà (Hỗ trợ kích thước tùy chỉnh) ----------------------
  Widget _buildHostAvatar({double size = 32, double fontSize = 14}) {
    final initial =
        widget.ownerName.isNotEmpty ? widget.ownerName[0].toUpperCase() : 'H';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_AppColors.hostAvatarStart, _AppColors.hostAvatarEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.grey400.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: _AppColors.grey600,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  // ---------------------- AppBar Nổi Bật & To Rõ Hơn ----------------------
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      // Kéo giãn header cho bề thế
      decoration: BoxDecoration(
        color: _AppColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.emeraldDeep.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        elevation: 0,
        toolbarHeight: 65,
        // Tăng chiều cao của AppBar lên
        backgroundColor: Colors.transparent,
        foregroundColor: _AppColors.grey900,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                _buildHostAvatar(size: 46, fontSize: 18),
                // Phóng to avatar trên Header
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _AppColors.emeraldDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.ownerName,
                  style: const TextStyle(
                    fontSize: 18, // Chữ to hơn
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: _AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2), // Giãn cách nhẹ giữa tên và status
                Row(
                  children: [
                    Text(
                      '${widget.receiverRole} • ', // SỬA LẠI DÒNG NÀY ĐỂ HIỂN THỊ ĐỘNG
                      style: const TextStyle(
                        fontSize: 13, // Chữ to hơn xíu
                        color: _AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        fontSize: 13,
                        color: _AppColors.emeraldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Khung Nhập Tin Nhắn ----------------------
  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _AppColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _AppColors.emeraldDeep.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.emeraldDeep.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: _AppColors.skyPale,
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.skyBorder, width: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 15, color: _AppColors.grey800),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: _AppColors.grey400, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.emeraldLight, _AppColors.emeraldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.emeraldDeep.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: _AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
