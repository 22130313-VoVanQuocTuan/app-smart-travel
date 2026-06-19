import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/domain/entities/homestay.dart';
import 'package:smart_travel/presentation/theme/app_colors.dart';
import 'package:smart_travel/router/route_names.dart';

class TopHomestayCard extends StatelessWidget {
  final Homestay homestay;
  final int rank; // 0-indexed: 0 = #1, 1 = #2, ...

  const TopHomestayCard({
    Key? key,
    required this.homestay,
    required this.rank,
  }) : super(key: key);



  Color _getRankColor() {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  List<Color> _getCardGradient() {
    switch (rank) {
      case 0:
        return [
          const Color(0xFFFFD700).withOpacity(0.15),
          const Color(0xFFFFF8E1).withOpacity(0.05),
        ];
      case 1:
        return [
          const Color(0xFFC0C0C0).withOpacity(0.12),
          const Color(0xFFF5F5F5).withOpacity(0.05),
        ];
      case 2:
        return [
          const Color(0xFFCD7F32).withOpacity(0.12),
          const Color(0xFFFFF3E0).withOpacity(0.05),
        ];
      default:
        return [
          Colors.white,
          Colors.white,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = homestay.pricePerNight != null && homestay.pricePerNight! > 0;
    final priceString = hasPrice
        ? "${NumberFormat('#,###').format(homestay.pricePerNight)}đ"
        : "Liên hệ";

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.hotelDetail, arguments: homestay.id);
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getCardGradient(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: rank < 3
              ? Border.all(
                  color: _getRankColor().withOpacity(0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: rank < 3
                  ? _getRankColor().withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: rank < 3 ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + Rank Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    homestay.thumbnail ?? "",
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 130,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.green.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.cottage_outlined, size: 40, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                ),

                // Rank Badge (top-left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rank < 3
                          ? _getRankColor().withOpacity(0.9)
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rank < 3) ...[
                          const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          rank < 3 ? 'Top ${rank + 1}' : '#${rank + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // "HOT" badge (top-right) - chỉ cho top 3
                if (rank < 3)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3D00).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_outlined, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      homestay.name ?? "Homestay",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating + Reviews
                    Row(
                      children: [
                        const Icon(Icons.star_border_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          homestay.rating != null && homestay.rating! > 0
                              ? homestay.rating!.toStringAsFixed(1)
                              : 'Mới',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: homestay.rating != null && homestay.rating! > 0
                                ? const Color(0xFF1F2937)
                                : AppColors.primary,
                          ),
                        ),
                        if (homestay.numOfReviews != null && homestay.numOfReviews! > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${homestay.numOfReviews})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            homestay.destinationName ?? homestay.address ?? "",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceString,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '/ đêm',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
