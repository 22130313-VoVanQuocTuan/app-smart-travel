import 'package:smart_travel/domain/entities/auth.dart';

class LoginResponseModal {
  final int? userId;
  final String token;
  final String? refreshToken;
  final String? role;
  final String? fullName;
  final bool? hostVerified; // null for non-HOST, true/false for HOST

  LoginResponseModal({
    this.userId,
    required this.token,
    required this.refreshToken,
    required this.role,
    required this.fullName,
    this.hostVerified,
  });

  // Chuyển từ Json → Modal (data)
  factory LoginResponseModal.fromJson(Map<String, dynamic> json) {
    return LoginResponseModal(
      userId: (json['userId'] ?? json['id']) as int?,
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      role: json['role'] as String?,
      fullName: json['fullName'] as String?,
      hostVerified: json['hostVerified'] as bool?,
    );
  }

  // Chuyển từ Model → Entity (domain)
  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      fullName: fullName,
      token: token,
      refreshToken: refreshToken,
      role: role,
      hostVerified: hostVerified,
    );
  }
}