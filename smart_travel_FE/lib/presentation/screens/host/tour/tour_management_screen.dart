// lib/presentation/screens/host/tour/tour_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/injection_container.dart';
import 'package:smart_travel/presentation/blocs/tour/tour_bloc.dart';
import 'package:smart_travel/presentation/blocs/tour/tour_event.dart';
import 'package:smart_travel/presentation/blocs/tour/tour_state.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/service/tour_service.dart';
import 'tour_form_dialog.dart';

class TourManagementScreen extends StatefulWidget {
  final int homestayId;
  final String homestayName;

  const TourManagementScreen({
    super.key,
    required this.homestayId,
    required this.homestayName,
  });

  @override
  State<TourManagementScreen> createState() => _TourManagementScreenState();
}

class _TourManagementScreenState extends State<TourManagementScreen> {
  late TourBloc _tourBloc;
  late TourService _tourService;

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    _tourService = TourService(dioClient);
    _tourBloc = sl<TourBloc>();
    _loadTours();
  }

  void _loadTours() {
    _tourBloc.add(LoadToursEvent(widget.homestayId));
  }

  String _formatCurrency(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  void _showAddTourDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TourFormDialog(
        homestayId: widget.homestayId,
        onSuccess: () => _loadTours(),
      ),
    );
  }

  void _showEditTourDialog(Map<String, dynamic> tour) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TourFormDialog(
        homestayId: widget.homestayId,
        tour: tour,
        onSuccess: () => _loadTours(),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> tour) {
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
                  const TextSpan(text: "Bạn có chắc chắn muốn xóa tour\n"),
                  TextSpan(text: "\"${tour['name']}\"", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
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
                    _tourBloc.add(DeleteTourEvent(tour['id']));
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
    _tourBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quản Lý Tour - ${widget.homestayName}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddTourDialog,
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            tooltip: "Thêm tour mới",
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _tourBloc,
        child: BlocConsumer<TourBloc, TourState>(
          listener: (context, state) {
            if (state is TourLoaded) {
              // Đã load thành công
            }
            if (state is TourSuccess) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is TourError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
              );
            }
          },
          builder: (context, state) {
            if (state is TourLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is TourLoaded) {
              final tours = state.tours;
              if (tours.isEmpty) {
                return _buildEmptyView();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tours.length,
                itemBuilder: (context, index) => _buildTourCard(tours[index]),
              );
            }
            if (state is TourError && state.tours.isEmpty) {
              return _buildErrorView(state.message);
            }
            return _buildEmptyView();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Icon(Icons.tour, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có tour nào",
            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showAddTourDialog,
            icon: const Icon(Icons.add),
            label: const Text("Thêm tour mới"),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTours,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Tải lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour) {
    final thumbnail = tour['thumbnail'] ?? '';
    final name = tour['name'] ?? 'Chưa có tên';
    final price = tour['pricePerPerson'] ?? 0;
    final durationDays = tour['durationDays'] ?? 0;
    final durationNights = tour['durationNights'] ?? 0;
    final maxPeople = tour['maxPeople'] ?? 0;
    final minPeople = tour['minPeople'] ?? 1;
    final isActive = tour['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withOpacity(0.06),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showEditTourDialog(tour),
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh thumbnail
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: thumbnail.isNotEmpty
                        ? Image.network(thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: 16),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '$durationDays ngày $durationNights đêm',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '$minPeople - $maxPeople người',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_formatCurrency(price)} VNĐ/người',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status và actions
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Đang bán' : 'Ngừng bán',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blue,
                          bgColor: Colors.blue.withOpacity(0.1),
                          onTap: () => _showEditTourDialog(tour),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: Colors.red,
                          bgColor: Colors.red.withOpacity(0.1),
                          onTap: () => _confirmDelete(tour),
                        ),
                      ],
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
      child: const Icon(Icons.tour, color: AppColors.primary, size: 30),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}