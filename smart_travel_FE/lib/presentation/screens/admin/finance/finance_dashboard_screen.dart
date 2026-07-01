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
  State<FinanceDashboardScreen> createState()
  => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends State<FinanceDashboardScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _reloadFinanceReport() {
    context.read<FinanceBloc>().add(
      GetFinanceSummaryEvent(
        year: _selectedYear,
        month: _selectedMonth,
      ),
    );
  }

  Widget _buildFilterBar() {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(6, (index) => currentYear - index);
    final months = List<int>.generate(12, (index) => index + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Tháng',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: months
                  .map(
                    (month) => DropdownMenuItem<int>(
                      value: month,
                      child: Text('Tháng $month'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedMonth = value;
                });
                _reloadFinanceReport();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Năm',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedYear = value;
                });
                _reloadFinanceReport();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý tài chính"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
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
                      year: _selectedYear,
                      month: _selectedMonth,
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
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, state) {
                if (state is FinanceLoaded) {
                  _selectedYear = state.selectedYear;
                  _selectedMonth = state.selectedMonth;
                }

                if (state is FinanceLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is FinanceLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: FinanceOverviewWidget(
                      data: state.summary,
                      monthlyData: state.monthlyData,
                      hostSettlements: state.hostSettlements,
                      selectedYear: state.selectedYear,
                      selectedMonth: state.selectedMonth,
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
          ),
        ],
      ),
    );
  }
}
