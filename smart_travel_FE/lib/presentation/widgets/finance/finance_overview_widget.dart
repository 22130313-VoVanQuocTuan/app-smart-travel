import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/finance/finance_monthly_model.dart';
import '../../../data/models/finance/finance_summary_model.dart';

class FinanceOverviewWidget extends StatelessWidget {
  final FinanceSummaryModel data;
  final List<FinanceMonthlyModel> monthlyData;

  const FinanceOverviewWidget({
    super.key,
    required this.data,
    this.monthlyData = const [],
  });

  String formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(value);
  }

  Widget buildCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCashFlowRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCashFlowStatement() {
    final totalCashIn = data.totalRevenue;
    final totalCashOut = data.totalCommission + data.totalHomestayRevenue;
    final netCash = totalCashIn - totalCashOut;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Báo cáo dòng tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildCashFlowRow('Tổng tiền vào', formatMoney(totalCashIn), valueColor: Colors.green),
            buildCashFlowRow('Tổng tiền ra', formatMoney(totalCashOut), valueColor: Colors.red),
            const Divider(height: 28),
            buildCashFlowRow('Dòng tiền thuần', formatMoney(netCash), valueColor: netCash >= 0 ? Colors.green : Colors.red),
            const SizedBox(height: 12),
            buildCashFlowRow('Tổng hóa đơn', data.totalInvoices.toString()),
            buildCashFlowRow('Tổng booking', data.totalBookings.toString()),
          ],
        ),
      ),
    );
  }

  Widget buildMonthlyChart() {
    if (monthlyData.isEmpty) {
      return const Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có dữ liệu biểu đồ cho năm hiện tại.'),
        ),
      );
    }

    final maxRevenue = monthlyData.fold<double>(0, (prev, element) => element.totalRevenue > prev ? element.totalRevenue : prev);
    final items = monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.totalRevenue,
            color: Colors.lightBlue,
            width: 18,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ doanh thu theo tháng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxRevenue * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: maxRevenue > 0 ? maxRevenue / 4 : 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact(locale: 'vi_VN').format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[index].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: items,
                  gridData: FlGridData(show: true, horizontalInterval: maxRevenue / 4),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            buildCard(
              'Doanh thu',
              formatMoney(data.totalRevenue),
              Icons.attach_money,
              Colors.green,
            ),
            buildCard(
              'Hoa hồng',
              formatMoney(data.totalCommission),
              Icons.account_balance,
              Colors.blue,
            ),
            buildCard(
              'Trả homestay',
              formatMoney(data.totalHomestayRevenue),
              Icons.home,
              Colors.orange,
            ),
            buildCard(
              'Booking',
              data.totalBookings.toString(),
              Icons.receipt,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildCashFlowStatement(),
        const SizedBox(height: 16),
        buildMonthlyChart(),
      ],
    );
  }
}
