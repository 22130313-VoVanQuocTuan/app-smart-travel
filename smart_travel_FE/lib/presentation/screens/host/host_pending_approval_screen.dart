import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_event.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class HostPendingApprovalScreen extends StatelessWidget {
  const HostPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chờ Duyệt'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade100,
                ),
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 64,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tài Khoản Chủ Homestay Chờ Duyệt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cảm ơn bạn đã đăng ký làm chủ homestay. Hồ sơ của bạn đang được admin kiểm duyệt. Bạn sẽ được thông báo qua email khi hồ sơ được phê duyệt.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông Tin Hồ Sơ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        const Text(
                          'Số CCCD/CMND đã cung cấp',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        const Text(
                          'Ảnh chân dung đã upload',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        const Text(
                          'Giấy tờ sở hữu đã cung cấp',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Refresh to check if approved
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang kiểm tra trạng thái...'),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Kiểm Tra Trạng Thái'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // Logout
                  context.read<ProfileBloc>().add(Logout());
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng Xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

