import 'package:flutter/material.dart';

class AuthHelper {
  /// Kiểm tra xem thông báo lỗi có liên quan đến việc hết hạn token không
  static bool isTokenExpiredError(String message) {
    final msg = message.toLowerCase();
    return msg.contains('unauthorized') ||
        msg.contains('401') ||
        msg.contains('phiên đăng nhập hết hạn') ||
        msg.contains('token');
  }

  /// Xử lý lỗi xác thực: Nếu token hết hạn, điều hướng người dùng về trang đăng nhập
  static void handleAuthError(BuildContext context, String message) {
    if (isTokenExpiredError(message)) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
