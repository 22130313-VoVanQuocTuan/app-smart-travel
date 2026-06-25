// lib/presentation/widgets/homestay/homestay_tour_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';

class HomestayTourSection extends StatelessWidget {
  final List<TourBrief> tours;
  final Set<int> selectedTourIds;
  final Function(TourBrief, bool) onToggleSelect;

  const HomestayTourSection({
    super.key,
    required this.tours,
    required this.selectedTourIds,
    required this.onToggleSelect,
  });

  String _formatCurrency(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (tours.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tour_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                "Tour du lịch đi kèm",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Chọn tour bạn muốn tham gia (có thể chọn nhiều)",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tours.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tour = tours[index];
              final isSelected = selectedTourIds.contains(tour.id);
              return _buildTourCard(context, tour, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(BuildContext context, TourBrief tour, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => onToggleSelect(tour, value ?? false),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${tour.durationDays} ngày ${tour.durationNights} đêm",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "${_formatCurrency(tour.pricePerPerson)} đ/người",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tour-detail', arguments: tour.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text("Chi tiết"),
            ),
          ],
        ),
      ),
    );
  }
}