import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/injection_container.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_bloc.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_event.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_state.dart';

class StatisticsDetailScreen extends StatefulWidget {
  const StatisticsDetailScreen({super.key});

  @override
  State<StatisticsDetailScreen> createState() => _StatisticsDetailScreenState();
}

class _StatisticsDetailScreenState extends State<StatisticsDetailScreen> {
  late final StatisticsBloc _dashboardBloc;
  late final StatisticsBloc _revenueBloc;

  int _selectedRevenueTab = 1; // 0=Ngày, 1=Tháng, 2=Năm
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _dashboardBloc = StatisticsBloc(repository: sl());
    _revenueBloc = StatisticsBloc(repository: sl());
    _dashboardBloc.add(const LoadDashboardStats());
    _loadRevenue();
  }

  void _loadRevenue() {
    final types = ['DAY', 'MONTH', 'YEAR'];
    _revenueBloc.add(LoadSystemRevenue(
      type: types[_selectedRevenueTab],
      year: _selectedYear,
      month: _selectedMonth,
    ));
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    _revenueBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Thống Kê Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _dashboardBloc.add(const LoadDashboardStats());
          _loadRevenue();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== DASHBOARD OVERVIEW =====
              BlocBuilder<StatisticsBloc, StatisticsState>(
                bloc: _dashboardBloc,
                builder: (context, state) {
                  if (state is StatisticsLoading) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  if (state is StatisticsError) {
                    return _buildErrorCard(state.message);
                  }
                  if (state is StatisticsLoaded) {
                    return _buildDashboardOverview(state.stats);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              // ===== REVENUE CHART =====
              _buildRevenueSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue highlight cards
        Row(
          children: [
            Expanded(child: _buildHighlightCard(
              'Doanh Thu Hôm Nay',
              _currencyFormat.format(stats.todayRevenue),
              Icons.trending_up_rounded,
              const [Color(0xFF00BCD4), Color(0xFF0097A7)],
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildHighlightCard(
              'Tổng Doanh Thu',
              _currencyFormat.format(stats.totalRevenue),
              Icons.account_balance_wallet_rounded,
              const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildHighlightCard(
              'Hóa Đơn Hôm Nay',
              '${stats.todayInvoices}',
              Icons.receipt_long_rounded,
              const [Color(0xFFFF6D00), Color(0xFFFF9100)],
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildHighlightCard(
              'Tổng Người Dùng',
              '${stats.totalUsers}',
              Icons.people_rounded,
              const [Color(0xFF1A73E8), Color(0xFF42A5F5)],
            )),
          ],
        ),
        const SizedBox(height: 20),

        // Stats grid
        const Text('Tổng Quan Hệ Thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _buildStatCard('Tỉnh Thành', '${stats.totalProvinces}', Icons.location_city_rounded, const Color(0xFF1A73E8)),
            _buildStatCard('Địa Điểm', '${stats.totalDestinations}', Icons.place_rounded, const Color(0xFF00BCD4)),
            _buildStatCard('Homestay', '${stats.totalHotels}', Icons.hotel_rounded, const Color(0xFF7C4DFF)),
            _buildStatCard('Tour', '${stats.totalTours}', Icons.tour_rounded, const Color(0xFFFF6D00)),
            _buildStatCard('Voucher', '${stats.totalVouchers}', Icons.card_giftcard_rounded, const Color(0xFF00C853)),
            _buildStatCard('Hóa Đơn', '${stats.todayInvoices}', Icons.receipt_rounded, const Color(0xFFE91E63)),
          ],
        ),
        const SizedBox(height: 20),

        // User role breakdown
        _buildUserRoleBreakdown(stats),
        const SizedBox(height: 20),

        // Top destinations
        _buildTopDestinations(stats.topDestinations),
        const SizedBox(height: 20),

        // Top homestays by revenue
        _buildTopHomestays(stats.topHomestays),
        const SizedBox(height: 20),

        // Top hosts by revenue
        _buildTopHosts(stats.topHosts),
      ],
    );
  }

  Widget _buildHighlightCard(String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF757575)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUserRoleBreakdown(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline_rounded, color: Color(0xFF1A73E8), size: 20),
              SizedBox(width: 8),
              Text('Phân Loại Người Dùng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 16),
          _buildRoleRow('USER', stats.totalUsersByRoleUSER, stats.totalUsers, const Color(0xFF1A73E8)),
          const SizedBox(height: 8),
          _buildRoleRow('HOST', stats.totalUsersByRoleHOST, stats.totalUsers, const Color(0xFF00BCD4)),
          const SizedBox(height: 8),
          _buildRoleRow('ADMIN', stats.totalUsersByRoleADMIN, stats.totalUsers, const Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  Widget _buildRoleRow(String role, int count, int total, Color color) {
    double ratio = total > 0 ? count / total : 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(role, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            Text('$count (${(ratio * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: Color(0xFF757575))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, backgroundColor: color.withValues(alpha: 0.1), color: color, minHeight: 6),
        ),
      ],
    );
  }

  Widget _buildTopDestinations(List<TopDestination> destinations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFF6D00), size: 20),
              SizedBox(width: 8),
              Text('Top Địa Điểm Nổi Bật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 12),
          ...destinations.asMap().entries.map((entry) {
            final idx = entry.key;
            final dest = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: idx < 3 ? const Color(0xFFFF6D00) : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dest.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(dest.provinceName, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text('${dest.viewCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopHomestays(List<TopHomestay> homestays) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home_work_rounded, color: Color(0xFF7C4DFF), size: 20),
              SizedBox(width: 8),
              Text('Top Doanh Thu Homestay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 12),
          if (homestays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có dữ liệu thống kê', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            )
          else
            ...homestays.asMap().entries.map((entry) {
              final idx = entry.key;
              final homestay = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: idx < 3 ? const Color(0xFF7C4DFF) : const Color(0xFFBDBDBD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(homestay.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Chủ nhà: ${homestay.hostName}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money_rounded, size: 14, color: Color(0xFF3F51B5)),
                          const SizedBox(width: 4),
                          Text(_currencyFormat.format(homestay.totalRevenue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3F51B5))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopHosts(List<TopHost> hosts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_rounded, color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text('Top Doanh Thu Chủ Homestay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 12),
          if (hosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có dữ liệu thống kê', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            )
          else
            ...hosts.asMap().entries.map((entry) {
              final idx = entry.key;
              final host = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: idx < 3 ? const Color(0xFF00BCD4) : const Color(0xFFBDBDBD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(host.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money_rounded, size: 14, color: Color(0xFF00838F)),
                          const SizedBox(width: 4),
                          Text(_currencyFormat.format(host.totalRevenue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00838F))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===== REVENUE SECTION =====
  Widget _buildRevenueSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF1A73E8), size: 22),
              SizedBox(width: 8),
              Text('Biểu Đồ Doanh Thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 16),

          // Tab selector
          Row(
            children: [
              _buildTabButton('Ngày', 0),
              const SizedBox(width: 8),
              _buildTabButton('Tháng', 1),
              const SizedBox(width: 8),
              _buildTabButton('Năm', 2),
              const Spacer(),
              // Year/Month selector
              if (_selectedRevenueTab != 2) ...[
                _buildDropdown(),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          BlocBuilder<StatisticsBloc, StatisticsState>(
            bloc: _revenueBloc,
            builder: (context, state) {
              if (state is RevenueLoading) {
                return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
              }
              if (state is RevenueError) {
                return SizedBox(height: 250, child: Center(child: Text('Lỗi: ${state.message}')));
              }
              if (state is RevenueLoaded) {
                return _buildBarChart(state.revenueData);
              }
              return const SizedBox(height: 250);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedRevenueTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRevenueTab = index);
        _loadRevenue();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF757575),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildDropdown() {
    if (_selectedRevenueTab == 0) {
      // Month + Year picker for DAY view
      return Row(
        children: [
          DropdownButton<int>(
            value: _selectedMonth,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('T${i + 1}'))),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedMonth = v);
                _loadRevenue();
              }
            },
          ),
          const SizedBox(width: 4),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
            items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedYear = v);
                _loadRevenue();
              }
            },
          ),
        ],
      );
    } else {
      // Year picker for MONTH view
      return DropdownButton<int>(
        value: _selectedYear,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
        items: List.generate(5, (i) => DateTime.now().year - 2 + i)
            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedYear = v);
            _loadRevenue();
          }
        },
      );
    }
  }

  Widget _buildBarChart(RevenueData data) {
    if (data.dataPoints.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('Chưa có dữ liệu doanh thu', style: TextStyle(color: Color(0xFF9E9E9E)))),
      );
    }

    final maxY = data.dataPoints.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final interval = _calculateInterval(maxY);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = data.dataPoints[group.x.toInt()];
                    return BarTooltipItem(
                      '${point.label}\n${_currencyFormat.format(point.revenue)}\n${point.invoiceCount} đơn',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < data.dataPoints.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data.dataPoints[idx].label,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF757575)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      return Text(_formatShortCurrency(value), style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E)));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE0E0E0), strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.dataPoints.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.revenue,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF42A5F5)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: data.dataPoints.length > 15 ? 8 : 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded, color: Color(0xFF1A73E8), size: 18),
              const SizedBox(width: 8),
              Text('Tổng: ${_currencyFormat.format(data.totalRevenue)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _dashboardBloc.add(const LoadDashboardStats()),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 0) return 1;
    final magnitude = (maxValue / 5).ceil();
    if (magnitude <= 1000) return 1000;
    if (magnitude <= 10000) return 10000;
    if (magnitude <= 100000) return 100000;
    if (magnitude <= 1000000) return 1000000;
    return (magnitude / 1000000).ceil() * 1000000;
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}tỷ';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}
