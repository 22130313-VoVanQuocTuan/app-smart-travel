import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/data/models/statistics/category_revenue_data.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/injection_container.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_bloc.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_event.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_state.dart';

class HostStatisticsScreen extends StatefulWidget {
  final int hostId;
  const HostStatisticsScreen({super.key, required this.hostId});

  @override
  State<HostStatisticsScreen> createState() => _HostStatisticsScreenState();
}

class _HostStatisticsScreenState extends State<HostStatisticsScreen> {
  late final StatisticsBloc _revenueBloc;
  late final StatisticsBloc _categoryBloc;
  late final StatisticsBloc _rangeBloc;

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Doanh thu của chủ homestay
  int _selectedTab = 1; // 0=Ngày, 1=Tháng, 2=Năm
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Doanh thu của chủ homestay theo khoảng thời gian
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

  // Doanh thu của chủ homestay theo danh mục
  int _pieYear = DateTime.now().year;
  int _pieMonth = DateTime.now().month;

  int _pieTouchedIndex = -1;

  // Doanh thu của chủ homestay theo danh mục
  static const List<Color> _pieColors = [
    Color(0xFF1A73E8),
    Color(0xFF00BCD4),
    Color(0xFF7C4DFF),
    Color(0xFFFF6D00),
    Color(0xFF00C853),
    Color(0xFFE91E63),
    Color(0xFFFF9100),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF5252),
  ];

  @override
  void initState() {
    super.initState();
    _revenueBloc = StatisticsBloc(repository: sl());
    _categoryBloc = StatisticsBloc(repository: sl());
    _rangeBloc = StatisticsBloc(repository: sl());
    _loadRevenue();
    _loadCategoryRevenue();
    _loadRangeRevenue();
  }

  void _loadRevenue() {
    final types = ['DAY', 'MONTH', 'YEAR'];
    _revenueBloc.add(
      LoadHostRevenue(
        hostId: widget.hostId,
        type: types[_selectedTab],
        year: _selectedYear,
        month: _selectedMonth,
      ),
    );
  }

  void _loadCategoryRevenue() {
    _categoryBloc.add(
      LoadHostRevenueByCategory(
        hostId: widget.hostId,
        year: _pieYear,
        month: _pieMonth,
      ),
    );
  }

  void _loadRangeRevenue() {
    final fmt = DateTimeFormatter();
    _rangeBloc.add(
      LoadHostRevenueByRange(
        hostId: widget.hostId,
        startDate: fmt.format(_rangeStart),
        endDate: fmt.format(_rangeEnd),
      ),
    );
  }

  @override
  void dispose() {
    _revenueBloc.close();
    _categoryBloc.close();
    _rangeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Thống Kê Doanh Thu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF00BCD4)],
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
          _loadRevenue();
          _loadCategoryRevenue();
          _loadRangeRevenue();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== SECTION 1: Doanh thu của chủ homestay theo ngày/tháng/năm =====
              _buildRevenueByPeriodSection(),
              const SizedBox(height: 20),

              // ===== SECTION 2: Doanh thu của chủ homestay theo khoảng thời gian =====
              _buildRevenueByRangeSection(),
              const SizedBox(height: 20),

              // ===== SECTION 3: Doanh thu của chủ homestay theo danh mục =====
              _buildPieChartSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SECTION 1: Doanh thu của chủ homestay theo ngày/tháng/năm =====
  Widget _buildRevenueByPeriodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF7C4DFF), size: 22),
              SizedBox(width: 8),
              Text(
                'Doanh Thu Theo Thời Gian',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          Row(
            children: [
              _buildTab('Ngày', 0),
              const SizedBox(width: 8),
              _buildTab('Tháng', 1),
              const SizedBox(width: 8),
              _buildTab('Năm', 2),
              const Spacer(),
              if (_selectedTab != 2) _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<StatisticsBloc, StatisticsState>(
            bloc: _revenueBloc,
            builder: (context, state) {
              if (state is RevenueLoading)
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              if (state is RevenueError)
                return SizedBox(
                  height: 220,
                  child: Center(child: Text('Lỗi: ${state.message}')),
                );
              if (state is RevenueLoaded)
                return _buildBarChart(state.revenueData, const [
                  Color(0xFF7C4DFF),
                  Color(0xFFB388FF),
                ]);
              return const SizedBox(height: 220);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadRevenue();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF) : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF757575),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    if (_selectedTab == 0) {
      return Row(
        children: [
          DropdownButton<int>(
            value: _selectedMonth,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w600,
            ),
            items: List.generate(
              12,
              (i) => DropdownMenuItem(value: i + 1, child: Text('T${i + 1}')),
            ),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedMonth = v);
                _loadRevenue();
              }
            },
          ),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w600,
            ),
            items:
                List.generate(5, (i) => DateTime.now().year - 2 + i)
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
      return DropdownButton<int>(
        value: _selectedYear,
        underline: const SizedBox(),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1A237E),
          fontWeight: FontWeight.w600,
        ),
        items:
            List.generate(5, (i) => DateTime.now().year - 2 + i)
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

  // ===== SECTION 2: Revenue by Date Range =====
  Widget _buildRevenueByRangeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                color: Color(0xFF00BCD4),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Doanh Thu Tuỳ Chọn Thời Gian',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date range pickers
          Row(
            children: [
              Expanded(
                child: _buildDatePickerButton('Từ', _rangeStart, (d) {
                  setState(() => _rangeStart = d);
                  _loadRangeRevenue();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerButton('Đến', _rangeEnd, (d) {
                  setState(() => _rangeEnd = d);
                  _loadRangeRevenue();
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<StatisticsBloc, StatisticsState>(
            bloc: _rangeBloc,
            builder: (context, state) {
              if (state is RevenueLoading)
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              if (state is RevenueError)
                return SizedBox(
                  height: 220,
                  child: Center(child: Text('Lỗi: ${state.message}')),
                );
              if (state is RevenueLoaded)
                return _buildBarChart(state.revenueData, const [
                  Color(0xFF00BCD4),
                  Color(0xFF80DEEA),
                ]);
              return const SizedBox(height: 220);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(
    String label,
    DateTime date,
    Function(DateTime) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('vi', 'VN'),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== SECTION 3: Pie Chart =====
  Widget _buildPieChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: Color(0xFFFF6D00), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Doanh Thu Theo Homestay',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month/Year picker
          Row(
            children: [
              const Text('Tháng: ', style: TextStyle(color: Color(0xFF757575))),
              DropdownButton<int>(
                value: _pieMonth,
                underline: const SizedBox(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w600,
                ),
                items: List.generate(
                  12,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('T${i + 1}')),
                ),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _pieMonth = v);
                    _loadCategoryRevenue();
                  }
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pieYear,
                underline: const SizedBox(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w600,
                ),
                items:
                    List.generate(5, (i) => DateTime.now().year - 2 + i)
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _pieYear = v);
                    _loadCategoryRevenue();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<StatisticsBloc, StatisticsState>(
            bloc: _categoryBloc,
            builder: (context, state) {
              if (state is CategoryRevenueLoading)
                return const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                );
              if (state is CategoryRevenueError)
                return SizedBox(
                  height: 280,
                  child: Center(child: Text('Lỗi: ${state.message}')),
                );
              if (state is CategoryRevenueLoaded)
                return _buildPieChart(state.categoryData);
              return const SizedBox(height: 280);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(CategoryRevenueData data) {
    if (data.categories.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: Color(0xFFBDBDBD),
              ),
              SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu chỉ có 1 homestay, biểu đồ tròn không có ý nghĩa (luôn 100%)
    if (data.categories.length == 1) {
      final item = data.categories.first;
      return Container(
        margin: const EdgeInsets.only(top: 20, bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.home_work_rounded,
              size: 48,
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tất cả doanh thu đều thuộc về:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.homestayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFF6D00),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng tháng: ${_currencyFormat.format(data.totalRevenue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _pieTouchedIndex = -1;
                      return;
                    }
                    _pieTouchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections:
                  data.categories.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isTouched = idx == _pieTouchedIndex;
                    final color = _pieColors[idx % _pieColors.length];

                    return PieChartSectionData(
                      color: color,
                      value: item.revenue,
                      title: '${item.percentage.toStringAsFixed(1)}%',
                      radius: isTouched ? 70 : 55,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                      badgeWidget: isTouched ? _buildBadge(item, color) : null,
                      badgePositionPercentageOffset: 1.3,
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        ...data.categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final color = _pieColors[idx % _pieColors.length];
          final isTouched = idx == _pieTouchedIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isTouched ? color.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  isTouched ? Border.all(color: color.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.homestayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currencyFormat.format(item.revenue),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          );
        }),
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
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFF6D00),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng tháng: ${_currencyFormat.format(data.totalRevenue)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(CategoryRevenueItem item, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
      ),
      child: Text(
        item.homestayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ===== Shared Bar Chart Builder =====
  Widget _buildBarChart(RevenueData data, List<Color> colors) {
    if (data.dataPoints.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Chưa có dữ liệu doanh thu',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
      );
    }

    final maxY = data.dataPoints
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);
    final interval = _calculateInterval(maxY);

    return Column(
      children: [
        SizedBox(
          height: 220,
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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < data.dataPoints.length) {
                        // Show every label or skip if too many
                        final skip = data.dataPoints.length > 15 ? 3 : 1;
                        if (idx % skip != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data.dataPoints[idx].label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF757575),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: interval,
                    getTitlesWidget:
                        (value, meta) => Text(
                          _formatShortCurrency(value),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: const Color(0xFFE0E0E0),
                      strokeWidth: 0.5,
                    ),
              ),
              borderData: FlBorderData(show: false),
              barGroups:
                  data.dataPoints.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.revenue,
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: data.dataPoints.length > 15 ? 6 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
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
              Icon(Icons.monetization_on_rounded, color: colors[0], size: 18),
              const SizedBox(width: 8),
              Text(
                'Tổng: ${_currencyFormat.format(data.totalRevenue)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ],
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
    if (value >= 1000000000)
      return '${(value / 1000000000).toStringAsFixed(1)}tỷ';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class DateTimeFormatter {
  String format(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
