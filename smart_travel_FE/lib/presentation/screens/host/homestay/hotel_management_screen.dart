// lib/presentation/screens/host/homestay/homestay_management_screen.dart
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_travel/presentation/blocs/auth/auth_state.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_management_bloc.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_management_event.dart';
import 'package:smart_travel/presentation/blocs/homestay/homestay_management_state.dart';
import 'package:smart_travel/presentation/screens/host/homestay/hotel_form_dialog.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/service/homestay_service.dart';

class HomestayManagementScreen extends StatefulWidget {
  const HomestayManagementScreen({super.key});

  @override
  State<HomestayManagementScreen> createState() => _HomestayManagementScreenState();
}

class _HomestayManagementScreenState extends State<HomestayManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Homestay> _currentHomestays = [];
  int _currentPage = 0;
  int _totalPages = 0;
  late HomestayManagementBloc _homestayBloc;

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    final homestayService = HomestayService(dioClient);
    _homestayBloc = HomestayManagementBloc(homestayService: homestayService);

    if (_isHotelAdmin()) {
      _loadData();
    }
  }

  bool _isHotelAdmin() {
    final authState = context.read<AuthBloc>().state;
    String? role;
    if (authState is LoginSuccess) {
      role = authState.response.role;
    } else if (authState is HostAuthenticated) {
      role = authState.role;
    }
    return role == "HOST";
  }

  void _loadData({int page = 0}) {
    _homestayBloc.add(
      LoadMyHomestaysEvent(
        keyword: _searchController.text.trim(),
        page: page,
        sortBy: 'id',
        sortDir: 'asc',
      ),
    );
  }

  String _formatCurrency(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  void _showModal({Homestay? homestay}) {
    if (!_isHotelAdmin()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HomestayFormDialog(
        homestay: homestay,
        onSuccess: () => _loadData(),
      ),
    );
  }

  void _confirmDelete(Homestay homestay) {
    if (!_isHotelAdmin()) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 32),
            ),
            const SizedBox(height: 20),
            const Text("Xác nhận xóa?", style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: "Bạn có chắc chắn muốn xóa\n"),
                  TextSpan(text: "\"${homestay.name}\"", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const TextSpan(text: " không?"),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Hủy bỏ"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _homestayBloc.add(DeleteHomestayEvent(homestay.id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Xóa ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homestayBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHotelAdmin = _isHotelAdmin();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quản Lý Homestay', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
        elevation: 0,
        actions: [
          if (isHotelAdmin)
            IconButton(
              onPressed: () => _showModal(homestay: null),
              icon: const Icon(Icons.add_card, color: Colors.white, size: 26),
              tooltip: "Thêm homestay",
            ),
        ],
      ),
      body: !isHotelAdmin
          ? _buildAccessDeniedView()
          : BlocProvider.value(
        value: _homestayBloc,
        child: BlocConsumer<HomestayManagementBloc, HomestayManagementState>(
          listener: (context, state) {
            if (state is HomestayManagementLoaded) {
              _currentHomestays = state.homestays;
              _currentPage = state.currentPage;
              _totalPages = state.totalPages;
            }
            if (state is HomestayManagementSuccess) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is HomestayManagementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
              );
            }
          },
          builder: (context, state) {
            final bool isLoading = state is HomestayManagementLoading;
            return Stack(
              children: [
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildHomestayList(_currentHomestays, state)),
                    if (_totalPages > 1) ...[_buildPagination(), const SizedBox(height: 20)],
                  ],
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.gpp_bad_rounded, size: 80, color: Colors.red[300]),
          ),
          const SizedBox(height: 24),
          const Text("Hạn chế truy cập", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textGray)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Bạn không có quyền quản lý homestay. Vui lòng liên hệ Admin để được hỗ trợ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF909090).withOpacity(0.1), spreadRadius: 0, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên, địa điểm...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _loadData(page: 0);
            },
          )
              : null,
        ),
        onSubmitted: (_) => _loadData(page: 0),
      ),
    );
  }

  Widget _buildHomestayList(List<Homestay> homestays, HomestayManagementState state) {
    if (homestays.isEmpty && state is! HomestayManagementLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: Icon(Icons.travel_explore, size: 60, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text("Chưa tìm thấy homestay nào", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: homestays.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildHomestayCard(homestays[index]),
    );
  }

  Widget _buildHomestayCard(Homestay homestay) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1A1A).withOpacity(0.06), offset: const Offset(0, 8), blurRadius: 24, spreadRadius: -4)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showModal(homestay: homestay),
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'homestay_img_${homestay.id}',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: homestay.thumbnail != null
                              ? Image.network(homestay.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                              : _buildPlaceholder(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                        child: Text("#${homestay.id}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              homestay.name??"",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3748), height: 1.2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (homestay.stars! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                children: [
                                  Text("${homestay.stars}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              homestay.destinationName ?? homestay.address??'',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "${_formatCurrency(homestay.pricePerNight ?? 0)} VNĐ",
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFEFF6FF),
                      onTap: () => _showModal(homestay: homestay),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.tour,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/host-tour-management',
                          arguments: {
                            'homestayId': homestay.id,
                            'homestayName': homestay.name,
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      onTap: () => _confirmDelete(homestay),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.blue[50],
      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 30),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageBtn(
            icon: Icons.chevron_left_rounded,
            isEnabled: _currentPage > 0,
            onTap: () => _loadData(page: _currentPage - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Trang ${_currentPage + 1} / $_totalPages",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray, fontSize: 15),
            ),
          ),
          _buildPageBtn(
            icon: Icons.chevron_right_rounded,
            isEnabled: _currentPage < _totalPages - 1,
            onTap: () => _loadData(page: _currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn({required IconData icon, required bool isEnabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          shape: BoxShape.circle,
          boxShadow: isEnabled ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Icon(icon, size: 24, color: isEnabled ? AppColors.primary : Colors.grey[400]),
      ),
    );
  }
}