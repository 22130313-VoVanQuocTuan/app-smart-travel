// lib/presentation/screens/tour/tour_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/service/tour_service.dart';

class TourDetailScreen extends StatefulWidget {
  final int tourId;

  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  late TourService _tourService;
  Map<String, dynamic>? _tour;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    _tourService = TourService(dioClient);
    _loadTourDetail();
  }

  Future<void> _loadTourDetail() async {
    setState(() => _isLoading = true);
    try {
      final tour = await _tourService.getTourDetail(widget.tourId);
      setState(() {
        _tour = tour;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Chi tiết Tour', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.mainGradient)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final tour = _tour!;
    final schedules = tour['schedules'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh thumbnail
          if (tour['thumbnail'] != null)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(tour['thumbnail']),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên tour
                Text(
                  tour['name'] ?? 'Tour du lịch',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Thời gian
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${tour['durationDays']} ngày ${tour['durationNights']} đêm',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Giá
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatCurrency(tour['pricePerPerson'])} VNĐ/người',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả
                const Text('Mô tả', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  tour['description'] ?? 'Chưa có mô tả',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Bao gồm
                if (tour['included'] != null && (tour['included'] as List).isNotEmpty) ...[
                  const Text('Bao gồm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(tour['included'] as List).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Không bao gồm
                if (tour['excluded'] != null && (tour['excluded'] as List).isNotEmpty) ...[
                  const Text('Không bao gồm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(tour['excluded'] as List).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Lịch trình chi tiết
                if (schedules.isNotEmpty) ...[
                  const Text('Lịch trình chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...schedules.map((schedule) => _buildScheduleCard(schedule)),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final meals = schedule['meals'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${schedule['dayNumber']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schedule['title'] ?? 'Ngày ${schedule['dayNumber']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule['activities'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (schedule['accommodation'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.hotel, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Nghỉ tại: ${schedule['accommodation']}'),
                      ],
                    ),
                  ],
                  if (meals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: meals.map((meal) => Chip(
                        label: Text(meal),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        labelStyle: const TextStyle(fontSize: 12),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}