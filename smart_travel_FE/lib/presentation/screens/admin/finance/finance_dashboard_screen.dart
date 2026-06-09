import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/pdf_downloader.dart';
import '../../../blocs/finance/finance_bloc.dart';
import '../../../blocs/finance/finance_event.dart';
import '../../../blocs/finance/finance_state.dart';
import '../../../widgets/finance/finance_overview_widget.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  static const String _groupDateRange = 'range';
  static const String _groupMonth = 'month';
  static const String _groupQuarter = 'quarter';
  static const String _groupYear = 'year';

  String _selectedGroup = _groupMonth;
  int _selectedYear = DateTime.now().year;
  int _selectedQuarter = 1;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _fromDate = selected;
        if (_fromDate.isAfter(_toDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = selected;
        if (_toDate.isBefore(_fromDate)) {
          _fromDate = _toDate;
        }
      }
    });
  }

  void _applyFilter() {
    if (_selectedGroup == _groupDateRange && _fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc')), 
      );
      return;
    }

    final startDate = _selectedGroup == _groupDateRange
        ? _fromDate.toIso8601String().split('T').first
        : null;
    final endDate = _selectedGroup == _groupDateRange
        ? _toDate.toIso8601String().split('T').first
        : null;
    final groupBy = _selectedGroup == _groupMonth
        ? 'month'
        : _selectedGroup == _groupQuarter
            ? 'quarter'
            : _selectedGroup == _groupYear
                ? 'year'
                : null;

    context.read<FinanceBloc>().add(
          GetFinanceSummaryEvent(
            startDate: startDate,
            endDate: endDate,
            groupBy: groupBy,
            year: _selectedGroup != _groupDateRange ? _selectedYear : null,
            quarter: _selectedGroup == _groupQuarter ? _selectedQuarter : null,
          ),
        );
  }

  void _clearFilter() {
    setState(() {
      _selectedGroup = _groupMonth;
      _selectedYear = DateTime.now().year;
      _selectedQuarter = 1;
      _fromDate = DateTime.now().subtract(const Duration(days: 30));
      _toDate = DateTime.now();
    });
    context.read<FinanceBloc>().add(const GetFinanceSummaryEvent());
  }

  Future<void> _exportPdf() async {
    final startDate = _selectedGroup == _groupDateRange
        ? _fromDate.toIso8601String().split('T').first
        : null;
    final endDate = _selectedGroup == _groupDateRange
        ? _toDate.toIso8601String().split('T').first
        : null;
    final groupBy = _selectedGroup == _groupMonth
        ? 'month'
        : _selectedGroup == _groupQuarter
            ? 'quarter'
            : _selectedGroup == _groupYear
                ? 'year'
                : null;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Đang tạo file PDF...'),
      ),
    );

    try {
      final bytes = await context
          .read<FinanceBloc>()
          .financeDataSource
          .exportPdf(
            startDate: startDate,
            endDate: endDate,
            groupBy: groupBy,
            year: _selectedGroup != _groupDateRange ? _selectedYear : null,
            quarter: _selectedGroup == _groupQuarter ? _selectedQuarter : null,
          );

      final path = await PdfDownloader.savePdf(bytes);
      final opened = await PdfDownloader.openPdf(path);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(opened
              ? 'Đã xuất và mở PDF thành công: $path'
              : 'Đã lưu PDF: $path. Mở file bằng ứng dụng quản lý tệp nếu cần.'),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
        ),
      );
    }
  }

  Widget _buildFilterCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lọc thống kê',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Thống kê theo:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroup,
                    items: const [
                      DropdownMenuItem(value: _groupMonth, child: Text('Theo tháng')),
                      DropdownMenuItem(value: _groupQuarter, child: Text('Theo quý')),
                      DropdownMenuItem(value: _groupYear, child: Text('Theo năm')),
                      DropdownMenuItem(value: _groupDateRange, child: Text('Từ ngày đến ngày')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedGroup = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedGroup == _groupDateRange) ...[
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text('Từ: ${_formatDate(_fromDate)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text('Đến: ${_formatDate(_toDate)}'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  if (_selectedGroup != _groupYear) ...[
                    const Text('Năm:'),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedYear,
                      items: List.generate(6, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(value: year, child: Text(year.toString()));
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedGroup == _groupQuarter) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quý:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedQuarter,
                        items: List.generate(4, (index) {
                          final quarter = index + 1;
                          return DropdownMenuItem(value: quarter, child: Text('Q$quarter'));
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedQuarter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text('Áp dụng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilter,
                    child: const Text('Xóa bộ lọc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài chính'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is FinanceLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterCard(context),
                  const SizedBox(height: 16),
                  FinanceOverviewWidget(
                    data: state.summary,
                    monthlyData: state.monthlyData,
                  ),
                ],
              ),
            );
          }

          if (state is FinanceError) {
            return Center(
              child: Text(state.message),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}