
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/finance/finance_host_settlement_model.dart';
import '../../../data/models/finance/finance_monthly_model.dart';
import '../../../data/models/finance/finance_summary_model.dart';

class FinanceOverviewWidget extends StatelessWidget {
  final FinanceSummaryModel data;
  final List<FinanceMonthlyModel> monthlyData;
  final List<FinanceHostSettlementModel> hostSettlements;
  final int selectedYear;
  final int selectedMonth;

  const FinanceOverviewWidget({
    super.key,
    required this.data,
    this.monthlyData = const [],
    this.hostSettlements = const [],
    required this.selectedYear,
    required this.selectedMonth,
  });

  String formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(value);
  }

  String get periodLabel => 'Tháng $selectedMonth/$selectedYear';

  Widget buildCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
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

  Widget buildOverallOverview() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        buildCard(
          'Tổng doanh thu',
          formatMoney(data.totalRevenue),
          Icons.attach_money,
          Colors.green,
        ),
        buildCard(
          'Tổng hoa hồng',
          formatMoney(data.totalCommission),
          Icons.account_balance,
          Colors.blue,
        ),
        buildCard(
          'Tổng chi host',
          formatMoney(data.totalHomestayRevenue),
          Icons.home_work_outlined,
          Colors.orange,
        ),
        buildCard(
          'Tổng booking',
          data.totalBookings.toString(),
          Icons.receipt_long,
          Colors.purple,
        ),
      ],
    );
  }

  Widget buildPeriodOverview() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đối Soát $periodLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildCashFlowRow(
              'Booking hoàn thành trong kỳ',
              formatMoney(data.monthlyCompletedRevenue),
              valueColor: Colors.black87,
            ),
            buildCashFlowRow(
              'Hệ thống đã thu online',
              formatMoney(data.monthlyOnlineRevenue),
              valueColor: Colors.green,
            ),
            buildCashFlowRow(
              'Host đã thu tiền mặt',
              formatMoney(data.monthlyCashRevenue),
              valueColor: Colors.orange,
            ),
            const Divider(height: 28),
            buildCashFlowRow(
              'Cần trả host',
              formatMoney(data.monthlyHostPayoutAmount),
              valueColor: Colors.red,
            ),
            buildCashFlowRow(
              'Host cần chuyển lại hệ thống',
              formatMoney(data.monthlyCashCommissionReceivable),
              valueColor: Colors.blue,
            ),
            const Divider(height: 28),
            buildCashFlowRow(
              'Đối soát ròng kỳ này',
              formatMoney(
                data.monthlyCashCommissionReceivable -
                    data.monthlyHostPayoutAmount,
              ),
              valueColor: data.monthlyCashCommissionReceivable -
                          data.monthlyHostPayoutAmount >=
                      0
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSystemCashFlowStatement() {
    final totalCashIn = data.totalRevenue;
    final totalCashOut = data.totalHomestayRevenue;
    final systemRetention = data.totalCommission;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng Quan Thu Chi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildCashFlowRow(
              'Tổng tiền vào hệ thống',
              formatMoney(totalCashIn),
              valueColor: Colors.green,
            ),
            buildCashFlowRow(
              'Tổng tiền đã/ghi nhận trả host',
              formatMoney(totalCashOut),
              valueColor: Colors.red,
            ),
            const Divider(height: 28),
            buildCashFlowRow(
              'Phần hệ thống giữ lại',
              formatMoney(systemRetention),
              valueColor: Colors.blue,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có dữ liệu biểu đồ cho năm hiện tại.'),
        ),
      );
    }

    final maxRevenue = monthlyData.fold<double>(
      0,
      (prev, element) =>
          element.totalRevenue > prev ? element.totalRevenue : prev,
    );
    final chartMaxY = maxRevenue > 0 ? maxRevenue * 1.2 : 1.0;
    final interval = maxRevenue > 0 ? maxRevenue / 4.0 : 1.0;

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
            Text(
              'Biểu Đồ Doanh Thu Năm $selectedYear',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: chartMaxY,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: interval,
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
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHostSettlementSection() {
    if (hostSettlements.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Không có dữ liệu đối soát host cho $periodLabel.'),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Báo Cáo Theo Từng Host - $periodLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...hostSettlements.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.hostName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${item.homestayCount} homestay',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildCashFlowRow(
                      'Tổng booking hoàn thành',
                      item.totalCompletedBookings.toString(),
                    ),
                    buildCashFlowRow(
                      'Booking online / cash',
                      '${item.onlineCompletedBookings} / ${item.cashCompletedBookings}',
                    ),
                    buildCashFlowRow(
                      'Doanh thu hoàn thành',
                      formatMoney(item.totalCompletedRevenue),
                    ),
                    buildCashFlowRow(
                      'Hệ thống thu online',
                      formatMoney(item.onlineCompletedRevenue),
                      valueColor: Colors.green,
                    ),
                    buildCashFlowRow(
                      'Host thu tiền mặt',
                      formatMoney(item.cashCompletedRevenue),
                      valueColor: Colors.orange,
                    ),
                    const Divider(height: 22),
                    buildCashFlowRow(
                      'Cần trả host',
                      formatMoney(item.amountPayableToHost),
                      valueColor: Colors.red,
                    ),
                    buildCashFlowRow(
                      'Host cần chuyển lại hệ thống',
                      formatMoney(item.amountHostMustTransfer),
                      valueColor: Colors.blue,
                    ),
                    buildCashFlowRow(
                      'Tổng hoa hồng',
                      formatMoney(item.totalCommission),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildOverallOverview(),
        const SizedBox(height: 16),
        buildPeriodOverview(),
        const SizedBox(height: 16),
        buildSystemCashFlowStatement(),
        const SizedBox(height: 16),
        buildHostSettlementSection(),
        const SizedBox(height: 16),
        buildMonthlyChart(),
      ],
    );
  }
}
