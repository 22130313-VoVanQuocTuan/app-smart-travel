import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/pdf_downloader.dart';
import '../../../blocs/finance/finance_bloc.dart';
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
                    .exportPdf();

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
              child: FinanceOverviewWidget(
                data: state.summary,
                monthlyData: state.monthlyData,
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