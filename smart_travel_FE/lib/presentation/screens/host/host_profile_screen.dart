import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/core/utils/auth_helper.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_bloc.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_event.dart';
import 'package:smart_travel/presentation/blocs/profile/profile_state.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/presentation/widgets/profile/profile_menu_item_widget.dart';
import 'package:smart_travel/router/route_names.dart';

class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key});

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
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
        title: const Text('Thong tin ca nhan Host'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            if (AuthHelper.isTokenExpiredError(state.message)) {
              AuthHelper.handleAuthError(context, state.message);
              return;
            }

            final snackBar = SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Loi',
                message: state.message,
                contentType: ContentType.failure,
              ),
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(snackBar);
          } else if (state is LogoutSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.login,
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! ProfileLoaded) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ProfileBloc>().add(LoadProfile());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tai lai thong tin'),
              ),
            );
          }

          final user = state.user;
          final dateFormat = DateFormat('dd/MM/yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeaderCard(
                  fullName: user.fullName,
                  email: user.email,
                  phone: user.phone,
                  avatarUrl: user.avatarUrl,
                  createdAt: dateFormat.format(user.createdAt),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Thong tin ho so',
                  items: [
                    ProfileMenuItemWidget(
                      icon: Icons.edit_outlined,
                      title: 'Chinh sua thong tin ca nhan',
                      iconColor: Colors.blue,
                      onTap: () async {
                        await Navigator.pushNamed(context, RouteNames.editProfile);
                        if (context.mounted) {
                          context.read<ProfileBloc>().add(LoadProfile());
                        }
                      },
                    ),
                    ProfileMenuItemWidget(
                      icon: Icons.badge_outlined,
                      title: 'Vai tro',
                      trailing: user.role,
                      iconColor: Colors.teal,
                      onTap: () {},
                    ),
                    ProfileMenuItemWidget(
                      icon: Icons.location_on_outlined,
                      title: 'Dia chi',
                      trailing: _compactLocation(
                        address: user.address,
                        city: user.city,
                        country: user.country,
                      ),
                      iconColor: Colors.orange,
                      onTap: () async {
                        await Navigator.pushNamed(context, RouteNames.editProfile);
                        if (context.mounted) {
                          context.read<ProfileBloc>().add(LoadProfile());
                        }
                      },
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Bao mat tai khoan',
                  items: [
                    ProfileMenuItemWidget(
                      icon: Icons.lock_outline,
                      title: 'Doi mat khau',
                      iconColor: Colors.deepPurple,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          RouteNames.changePassword,
                        );
                      },
                    ),
                    ProfileMenuItemWidget(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Quan ly tai khoan',
                      iconColor: Colors.redAccent,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          RouteNames.accountManagement,
                        );
                      },
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Thong tin ung dung',
                  items: [
                    ProfileMenuItemWidget(
                      icon: Icons.description_outlined,
                      title: 'Dieu khoan dich vu',
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.termsOfService);
                      },
                    ),
                    ProfileMenuItemWidget(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Chinh sach bao mat',
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.privacyPolicy);
                      },
                    ),
                    ProfileMenuItemWidget(
                      icon: Icons.logout,
                      title: 'Dang xuat',
                      iconColor: Colors.red,
                      onTap: _showLogoutDialog,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required String fullName,
    required String email,
    required String? phone,
    required String? avatarUrl,
    required String createdAt,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                child:
                    avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          size: 34,
                          color: AppColors.primary,
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildBadge(Icons.storefront_outlined, 'Host'),
              if (phone != null && phone.isNotEmpty)
                _buildBadge(Icons.phone_outlined, phone),
              _buildBadge(Icons.calendar_month_outlined, 'Tham gia $createdAt'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.4,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  String _compactLocation({
    required String? address,
    required String? city,
    required String? country,
  }) {
    final parts = <String>[
      if (address != null && address.isNotEmpty) address,
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
    ];
    if (parts.isEmpty) {
      return 'Chua cap nhat';
    }
    return parts.join(', ');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Dang xuat'),
            content: const Text('Ban co muon dang xuat khoi tai khoan host?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Huy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ProfileBloc>().add(Logout());
                },
                child: const Text(
                  'Dang xuat',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
