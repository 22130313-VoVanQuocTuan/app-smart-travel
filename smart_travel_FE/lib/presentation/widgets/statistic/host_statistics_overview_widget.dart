import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/presentation/screens/host/host_statistics_screen.dart';

class HostStatisticsOverviewWidget extends StatelessWidget {
  final DashboardStats stats;
  final int hostId;

  const HostStatisticsOverviewWidget({Key? key, required this.stats, required this.hostId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HostStatisticsScreen(hostId: hostId)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.7), const Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
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
                Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tổng Quan Doanh Thu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Revenue highlight row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Doanh Thu Hôm Nay',
                    currencyFormat.format(stats.todayRevenue),
                    Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    'Tổng Doanh Thu',
                    currencyFormat.format(stats.totalRevenue),
                    Icons.account_balance_wallet_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Hóa Đơn Hôm Nay',
                    stats.todayInvoices.toString(),
                    Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    'Homestay',
                    stats.totalHotels.toString(),
                    Icons.hotel_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhấn để xem biểu đồ chi tiết →',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
