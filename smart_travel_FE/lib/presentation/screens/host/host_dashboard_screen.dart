import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_event.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_state.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_bloc.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_event.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_state.dart';
import 'package:smart_travel/presentation/widgets/statistic/host_statistics_overview_widget.dart';
import 'package:smart_travel/injection_container.dart' as di;
import 'package:smart_travel/router/route_names.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is! ProfileLoaded) {
      context.read<ProfileBloc>().add(LoadProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản Lý Homestay'),
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // 1. Lấy state từ ProfileBloc để có ID và Tên chuẩn
              final profileState = context.read<ProfileBloc>().state;

              if (profileState is ProfileLoaded) {
                final hostId = profileState.user.id; // Lấy ID từ user entity
                final hostName = profileState.user.fullName;

                // 2. Chuyển hướng
                Navigator.pushNamed(
                  context,
                  RouteNames.hostChatList,
                  arguments: {
                    'ownerId': hostId,
                    'ownerName': hostName,
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đang tải dữ liệu hồ sơ, vui lòng đợi...")),
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
            tooltip: "Tin nhắn từ khách",
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Chào Mừng, Chủ Homestay',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý homestay và lịch đặt của bạn',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 16),
            // Statistics Overview
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded) {
                  return BlocProvider(
                    create: (context) => di.sl<StatisticsBloc>()..add(LoadHostDashboardStats(profileState.user.id)),
                    child: BlocBuilder<StatisticsBloc, StatisticsState>(
                      builder: (context, state) {
                        if (state is StatisticsLoaded) {
                          return HostStatisticsOverviewWidget(stats: state.stats, hostId: profileState.user.id);
                        }
                        if (state is StatisticsError) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                'Lỗi: ${state.message}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.7), const Color(0xFF7C4DFF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  );
                }
                // Nếu chưa load profile, hiển thị loading khung chờ
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
            const SizedBox(height: 16),
            // Menu Grid
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                children: [
                  _buildMenuCard(
                    context: context,
                    icon: Icons.home,
                    label: 'Quản Lý Homestay',
                    color: Colors.purple,
                    route: '/host-homestay-management',
                  ),

                  _buildMenuCard(
                    context: context,
                    icon: Icons.calendar_today,
                    label: 'Lịch Đặt',
                    color: Colors.teal,
                    route: '/host-bookings',
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.star,
                    label: 'Đánh Giá',
                    color: Colors.orange,
                    route: '/host-reviews',
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.person,
                    label: 'Thông Tin Tài Khoản',
                    color: Colors.pink,
                    route: RouteNames.hostProfile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xác nhận đăng xuất'),
      content: const Text('Bạn có muốn đăng xuất khỏi tài khoản này?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<ProfileBloc>().add(Logout());
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text(
            'Xác nhận',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

