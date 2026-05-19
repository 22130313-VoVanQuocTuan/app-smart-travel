import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_event.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_state.dart';
import 'package:smart_travel/presentation/screens/host/host_statistics_screen.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

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
              _showLogoutDialog(context);
            },
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
            const SizedBox(height: 32),
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
                  _buildStatisticsCard(context),
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
                    route: '/profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatisticsCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        int hostId = 0;
        final profileState = context.read<ProfileBloc>().state;
        if (profileState is ProfileLoaded) {
          hostId = profileState.user.id;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HostStatisticsScreen(hostId: hostId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.7), const Color(0xFF7C4DFF)],
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_rounded, size: 48, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Thống Kê Doanh Thu',
              style: TextStyle(
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

