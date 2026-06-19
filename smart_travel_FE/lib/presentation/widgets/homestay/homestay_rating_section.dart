// lib/presentation/widgets/homestay/homestay_rating_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class HomestayRatingSection extends StatelessWidget {
  final double averageRating;
  final int reviewCount;
  final VoidCallback? onViewAllReviews;

  const HomestayRatingSection({
    Key? key,
    required this.averageRating,
    required this.reviewCount,
    this.onViewAllReviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Rating Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá homestay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Rating Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '/5',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stars
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingBar.builder(
                            initialRating: averageRating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 20,
                            itemPadding: EdgeInsets.zero,
                            ignoreGestures: true,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (_) {},
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dựa trên $reviewCount đánh giá',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating Distribution
          _buildRatingDistribution(),
          const SizedBox(height: 16),

          // View All Reviews Button
          if (reviewCount > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewAllReviews,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text('Xem tất cả $reviewCount đánh giá'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    // Simplified distribution (we'll enhance with real data if needed)
    final ratings = [
      {'stars': 5, 'label': 'Tuyệt vời', 'percent': 0.6},
      {'stars': 4, 'label': 'Tốt', 'percent': 0.25},
      {'stars': 3, 'label': 'Bình thường', 'percent': 0.1},
      {'stars': 2, 'label': 'Tạm được', 'percent': 0.03},
      {'stars': 1, 'label': 'Tệ', 'percent': 0.02},
    ];

    return Column(
      children: List.generate(
        ratings.length,
        (index) {
          final rating = ratings[index];
          final percent = (rating['percent'] as double?) ?? 0.0;
          final count = (reviewCount * percent).round();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    '${rating['stars']}⭐',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        _getColorForRating(rating['stars'] as int),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 35,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorForRating(int stars) {
    switch (stars) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

