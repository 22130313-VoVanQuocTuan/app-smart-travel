import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/data_sources/remote/finance_data_source.dart';
import '../../../data/models/finance/finance_host_settlement_model.dart';
import '../../../data/models/finance/finance_monthly_model.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {

  final FinanceDataSource financeDataSource;

  FinanceBloc({
    required this.financeDataSource,
  }) : super(FinanceInitial()) {

    on<GetFinanceSummaryEvent>(_onGetSummary);
  }

  Future<void> _onGetSummary(
      GetFinanceSummaryEvent event,
      Emitter<FinanceState> emit,
      ) async {

    try {

      emit(FinanceLoading());

      final now = DateTime.now();
      final selectedYear = event.year ?? now.year;
      final selectedMonth = event.month ?? now.month;

      final summary = await financeDataSource.getSummary(
        year: selectedYear,
        month: selectedMonth,
      );
      List<FinanceMonthlyModel> monthlyData = [];
      List<FinanceHostSettlementModel> hostSettlements = [];

      try {
        monthlyData = await financeDataSource.getMonthlyData(selectedYear);
      } catch (_) {
        monthlyData = [];
      }

      try {
        hostSettlements = await financeDataSource.getHostSettlements(
          year: selectedYear,
          month: selectedMonth,
        );
      } catch (_) {
        hostSettlements = [];
      }

      emit(FinanceLoaded(
        summary: summary,
        monthlyData: monthlyData,
        hostSettlements: hostSettlements,
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
      ));

    } catch (e) {

      emit(FinanceError(e.toString()));
    }
  }
}
